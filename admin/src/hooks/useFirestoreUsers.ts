import { useEffect, useState } from 'react';
import {
  fetchUsersTotal,
  subscribeUsers,
  type AdminUser,
} from '../lib/firestoreUsers';

/**
 * Firestore `users` 실시간 구독 훅 (Flutter StreamBuilder 대응).
 * UI 레이아웃은 건드리지 않고, 데이터만 공급합니다.
 */
export function useFirestoreUsers() {
  const [users, setUsers] = useState<AdminUser[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [total, setTotal] = useState<number | null>(null);

  useEffect(() => {
    let alive = true;
    fetchUsersTotal()
      .then((count) => alive && setTotal(count))
      .catch(() => alive && setTotal(null));
    return () => {
      alive = false;
    };
  }, []);

  useEffect(() => {
    setLoading(true);
    const unsub = subscribeUsers({
      onData: (next) => {
        setUsers(next);
        setError(null);
        setLoading(false);
      },
      onError: (err) => {
        console.error('[useFirestoreUsers]', err);
        setError(err.message);
        setUsers([]);
        setLoading(false);
      },
    });
    return () => unsub();
  }, []);

  /** 낙관적 UI 갱신 (쓰기 직후 로컬 반영). 다음 onSnapshot이 덮어씁니다. */
  const setUsersLocal = (
    updater: AdminUser[] | ((prev: AdminUser[]) => AdminUser[])
  ) => {
    setUsers(updater);
  };

  /** 전체 가입자 수가 불러온 수보다 많으면 목록·합계는 일부 기준이다. */
  const truncated = total !== null && total > users.length;

  return { users, loading, error, setUsersLocal, total, truncated };
}

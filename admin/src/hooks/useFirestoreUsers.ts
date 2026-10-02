import { useEffect, useState } from 'react';
import {
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

  return { users, loading, error, setUsersLocal };
}

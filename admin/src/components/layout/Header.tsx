import { useState, useEffect } from 'react';
import { collection, getDocs, limit, query } from 'firebase/firestore';
import { ensureAdminAuth, signOutAdmin } from '../../lib/adminAuth';
import { getDb, USERS_COLLECTION } from '../../lib/firebase';
import { fetchWhoAmI } from '../../lib/jenaApi';

export default function Header() {
  // GCP(Firestore) 연결 상태를 추적하는 상태 변수 ('checking', 'online', 'offline')
  const [serverStatus, setServerStatus] = useState<'checking' | 'online' | 'offline'>('checking');
  const [jenaLabel, setJenaLabel] = useState('Jena: 확인 중...');

  useEffect(() => {
    const checkServerHealth = async () => {
      try {
        await ensureAdminAuth();
        await getDocs(query(collection(getDb(), USERS_COLLECTION), limit(1)));
        setServerStatus('online');
      } catch {
        setServerStatus('offline');
      }
    };

    checkServerHealth();
  }, []);

  useEffect(() => {
    const loadWhoami = async () => {
      try {
        const user = await ensureAdminAuth();
        if (!user) {
          setJenaLabel('Jena: 로그인 필요');
          return;
        }
        const me = await fetchWhoAmI(await user.getIdToken());
        setJenaLabel(`Jena: ${me.email || me.uid}`);
      } catch (err) {
        setJenaLabel(
          err instanceof Error && err.message === 'forbidden'
            ? 'Jena: 권한 없음'
            : 'Jena: 연결 실패'
        );
      }
    };
    void loadWhoami();
  }, []);

  return (
    <header className="bg-gray-800 border-b border-gray-700 text-white p-4 flex justify-between items-center">
      <div className="font-bold text-lg">SRC Admin</div>
      <div className="flex gap-4 text-sm items-center">
        
        {/* 서버 상태에 따라 뱃지 색상과 글자가 자동으로 바뀝니다 */}
        {serverStatus === 'checking' && (
          <span className="px-2 py-1 bg-gray-700 text-gray-300 rounded animate-pulse">
            GCP: 연결 확인중...
          </span>
        )}
        {serverStatus === 'online' && (
          <span className="px-2 py-1 bg-green-900 text-green-400 rounded">
            GCP: 정상
          </span>
        )}
        {serverStatus === 'offline' && (
          <span className="px-2 py-1 bg-red-900 text-red-400 rounded">
            GCP: 연결 끊김
          </span>
        )}

        <span className="px-2 py-1 bg-gray-700 text-gray-200 rounded">{jenaLabel}</span>
        <span>Profile</span>
        <button
          type="button"
          onClick={() => void signOutAdmin()}
          className="px-2 py-1 bg-gray-700 hover:bg-gray-600 rounded"
        >
          로그아웃
        </button>
      </div>
    </header>
  );
}

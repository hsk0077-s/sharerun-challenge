import { useState, useEffect } from 'react';
import { useFirestoreUsers } from '../../hooks/useFirestoreUsers';
import {
  subscribeTournaments,
  type AdminTournament,
} from '../../lib/firestoreOps';

function tierLabel(tier: number): string {
  if (tier <= 1) return '초급';
  if (tier === 2) return '중급';
  return '상급';
}

function sumWallet(
  users: { share_balance?: number; diamond_balance?: number; value_balance: number }[],
  field: 'share_balance' | 'diamond_balance' | 'value_balance'
): number {
  return users.reduce((acc, user) => acc + (user[field] || 0), 0);
}

export default function Overview() {
  const { users, loading, error } = useFirestoreUsers();
  const [statsReady, setStatsReady] = useState(false);
  const [tournaments, setTournaments] = useState<AdminTournament[]>([]);

  const totalUsers = users.length;
  const totalShare = sumWallet(users, 'share_balance');
  const totalDiamond = sumWallet(users, 'diamond_balance');
  const totalValue = sumWallet(users, 'value_balance');
  const gcpOnline = !error && !loading;

  useEffect(() => {
    if (!loading) setStatsReady(true);
  }, [loading]);

  useEffect(() => {
    return subscribeTournaments({
      onData: setTournaments,
      onError: (err) => console.error('[Overview tournaments]', err),
    });
  }, []);

  const roomMonitor = tournaments.slice(0, 4).map((t) => {
    const bepPct =
      t.minParticipantsBep > 0
        ? Math.min(100, Math.round((t.participantCount / t.minParticipantsBep) * 100))
        : 0;
    return {
      name: `${tierLabel(t.requiredTier)} ${t.targetDistanceKm}km · ${t.title}`,
      current: t.participantCount,
      max: t.maxParticipants,
      bep: bepPct,
      status: t.status,
    };
  });

  return (
    <div className="p-6 text-white h-full overflow-y-auto space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
        <h2 className="text-2xl font-bold tracking-tight">
          System Overview (시스템 관제탑)
        </h2>
        <div className="flex items-center gap-3">
          <span
            className={`inline-flex items-center gap-2 px-3 py-1.5 rounded-full text-xs font-semibold border ${
              !statsReady
                ? 'bg-gray-800 border-gray-600 text-gray-400'
                : gcpOnline
                  ? 'bg-emerald-950/70 border-emerald-800 text-emerald-400'
                  : 'bg-amber-950/70 border-amber-800 text-amber-400'
            }`}
          >
            <span
              className={`w-1.5 h-1.5 rounded-full ${
                !statsReady ? 'bg-gray-500' : gcpOnline ? 'bg-emerald-400 animate-pulse' : 'bg-amber-400'
              }`}
            />
            {!statsReady
              ? 'Firestore: Connecting...'
              : gcpOnline
                ? 'Firestore: Live'
                : 'Firestore: Permission / Offline'}
          </span>
          <span className="text-xs text-gray-500 hidden md:inline">
            {loading
              ? '데이터 준비 중'
              : `등록 ${totalUsers.toLocaleString()}명 · SHARE ${totalShare.toLocaleString()} · 다이아 ${totalDiamond.toLocaleString()} · VALUE ${totalValue.toLocaleString()}`}
            {error ? ` · ${error}` : ''}
          </span>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="bg-gray-800 p-6 rounded-xl border border-gray-700">
          <h3 className="text-gray-300 text-sm font-semibold mb-4">A. 트랙 관리</h3>
          <p className="text-sm text-gray-500 py-8 text-center">데이터 준비 중</p>
        </div>

        <div className="bg-gray-800 p-6 rounded-xl border border-gray-700">
          <h3 className="text-gray-300 text-sm font-semibold mb-4">B. 3-jewel 토큰 체계</h3>
          {loading ? (
            <p className="text-sm text-gray-500 py-8 text-center">데이터 준비 중</p>
          ) : (
            <div className="grid grid-cols-3 gap-3 text-center py-4">
              <div>
                <p className="text-2xl font-bold text-emerald-400">{totalShare.toLocaleString()}</p>
                <span className="text-[11px] font-semibold text-gray-400 mt-1 block">SHARE</span>
              </div>
              <div>
                <p className="text-2xl font-bold text-sky-300">{totalDiamond.toLocaleString()}</p>
                <span className="text-[11px] font-semibold text-gray-400 mt-1 block">다이아</span>
              </div>
              <div>
                <p className="text-2xl font-bold text-lime-400">{totalValue.toLocaleString()}</p>
                <span className="text-[11px] font-semibold text-gray-400 mt-1 block">VALUE</span>
              </div>
            </div>
          )}
        </div>

        <div className="bg-gray-800 p-6 rounded-xl border border-gray-700">
          <h3 className="text-gray-300 text-sm font-semibold mb-4">C. 대회 방 모집 모니터링</h3>
          <div className="space-y-2">
            {roomMonitor.length === 0 ? (
              <p className="text-sm text-gray-500 py-4 text-center">모집 중인 대회가 없습니다.</p>
            ) : (
              roomMonitor.map((room, idx) => (
                <div
                  key={`${room.name}-${idx}`}
                  className="flex items-center justify-between gap-3 px-3 py-2.5 rounded-lg bg-gray-900/50 border border-gray-700/80"
                >
                  <p className="text-sm text-gray-200 truncate">
                    {room.name} - 모집 인원 {room.current}/{room.max}명 (BEP {room.bep}%)
                  </p>
                  <span className="shrink-0 text-[11px] font-semibold text-emerald-400 whitespace-nowrap">
                    {room.status === 'recruiting' ? '모집 중' : room.status}
                  </span>
                </div>
              ))
            )}
          </div>
        </div>

        <div className="bg-gray-800 p-6 rounded-xl border border-gray-700">
          <h3 className="text-gray-300 text-sm font-semibold mb-4">D. Jena AI 실시간 성황</h3>
          <p className="text-sm text-gray-500 py-8 text-center">데이터 준비 중</p>
        </div>
      </div>
    </div>
  );
}

import { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { useFirestoreUsers } from '../../hooks/useFirestoreUsers';
import { isActiveAccount } from '../../lib/firestoreUsers';
import { ensureAdminAuth } from '../../lib/adminAuth';
import { fetchReports } from '../../lib/jenaApi';
import {
  currentKstMonth,
  subscribeActivities,
  subscribeAppeals,
  subscribeDonationMonth,
  subscribeTournaments,
  type AdminActivity,
  type AdminAppeal,
  type AdminTournament,
  type DonationMonth,
} from '../../lib/firestoreOps';

/** 서버 기본값(donation_cap.py DEFAULT_MONTHLY_CAP_WON)과 같은 월 상한. */
const MONTHLY_DONATION_CAP_WON = 1_000_000;
const FINISHED_TOURNAMENT = new Set([
  'completed',
  'settled',
  'finished',
  'closed',
  'cancelled',
  'canceled',
]);

function tierLabel(tier: number): string {
  if (tier <= 1) return '초급';
  if (tier === 2) return '중급';
  return '상급';
}

function statusLabel(status: string): string {
  if (status === 'recruiting') return '모집 중';
  if (status === 'in_progress' || status === 'ongoing' || status === 'active') return '진행 중';
  return status;
}

function sumWallet(
  users: { share_balance?: number; diamond_balance?: number; value_balance: number }[],
  field: 'share_balance' | 'diamond_balance' | 'value_balance'
): number {
  return users.reduce((acc, user) => acc + (user[field] || 0), 0);
}

function QueueLink({
  to,
  label,
  value,
  alert,
}: {
  to: string;
  label: string;
  value: string;
  alert: boolean;
}) {
  return (
    <Link
      to={to}
      className="flex items-center justify-between gap-3 px-3 py-2.5 rounded-lg bg-gray-900/50 border border-gray-700/80 hover:border-emerald-700 transition-colors"
    >
      <span className="text-sm text-gray-200">{label}</span>
      <span className={`text-lg font-bold ${alert ? 'text-amber-400' : 'text-emerald-400'}`}>
        {value}
      </span>
    </Link>
  );
}

export default function Overview() {
  const { users, loading, error } = useFirestoreUsers();
  const [statsReady, setStatsReady] = useState(false);
  const [tournaments, setTournaments] = useState<AdminTournament[]>([]);
  const [donation, setDonation] = useState<DonationMonth | null>(null);
  const [appeals, setAppeals] = useState<AdminAppeal[] | null>(null);
  const [activities, setActivities] = useState<AdminActivity[] | null>(null);
  const [openReports, setOpenReports] = useState<number | null>(null);

  const month = currentKstMonth();
  const activeUsers = users.filter(isActiveAccount);
  const totalShare = sumWallet(activeUsers, 'share_balance');
  const totalDiamond = sumWallet(activeUsers, 'diamond_balance');
  const totalValue = sumWallet(activeUsers, 'value_balance');
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

  useEffect(() => {
    return subscribeDonationMonth(month, setDonation, (err) =>
      console.error('[Overview donation]', err)
    );
  }, [month]);

  useEffect(() => {
    return subscribeAppeals({
      onData: setAppeals,
      onError: (err) => console.error('[Overview appeals]', err),
    });
  }, []);

  useEffect(() => {
    return subscribeActivities(
      {
        onData: setActivities,
        onError: (err) => console.error('[Overview activities]', err),
      },
      { limitCount: 40 }
    );
  }, []);

  useEffect(() => {
    let cancelled = false;
    void (async () => {
      try {
        const admin = await ensureAdminAuth();
        if (!admin) return;
        const rows = await fetchReports(await admin.getIdToken(), 'open');
        if (!cancelled) setOpenReports(rows.length);
      } catch (err) {
        console.error('[Overview reports]', err);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, []);

  const donated = donation?.totalWon ?? 0;
  const donationPct = Math.min(100, Math.round((donated / MONTHLY_DONATION_CAP_WON) * 100));
  const waitingAppeals = appeals
    ? appeals.filter((a) => a.status === 'under_review' || a.status === 'pending').length
    : null;
  const verifiedRuns = activities ? activities.filter((a) => a.jenaVerified).length : null;

  const roomMonitor = tournaments
    .slice()
    .sort(
      (a, b) =>
        Number(FINISHED_TOURNAMENT.has(a.status)) - Number(FINISHED_TOURNAMENT.has(b.status))
    )
    .slice(0, 4)
    .map((t) => {
      const bepPct =
        t.minParticipantsBep > 0
          ? Math.min(100, Math.round((t.participantCount / t.minParticipantsBep) * 100))
          : 0;
      return {
        id: t.id,
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
              : `전체 ${users.length.toLocaleString()}명 · 활성 ${activeUsers.length.toLocaleString()}명`}
            {error ? ` · ${error}` : ''}
          </span>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="bg-gray-800 p-6 rounded-xl border border-gray-700">
          <h3 className="text-gray-300 text-sm font-semibold mb-4">
            A. 이번 달 회사 기부 예산 현황 ({month})
          </h3>
          {donation === null ? (
            <p className="text-sm text-gray-500 py-8 text-center">데이터 준비 중</p>
          ) : (
            <div className="space-y-3 py-2">
              <p className="text-2xl font-bold text-emerald-400">
                {donated.toLocaleString()}원
                <span className="text-sm font-normal text-gray-400">
                  {' '}
                  / {MONTHLY_DONATION_CAP_WON.toLocaleString()}원
                </span>
              </p>
              <div className="h-3 rounded-full bg-gray-900 overflow-hidden">
                <div
                  className={`h-full ${donationPct >= 100 ? 'bg-amber-400' : 'bg-emerald-500'}`}
                  style={{ width: `${donationPct}%` }}
                />
              </div>
              <p className="text-xs text-gray-400">
                소진율 {donationPct}%
                {donationPct >= 100 ? ' · 상한 도달, 이후 기부는 기록되지 않습니다.' : ''}
              </p>
            </div>
          )}
        </div>

        <div className="bg-gray-800 p-6 rounded-xl border border-gray-700">
          <h3 className="text-gray-300 text-sm font-semibold mb-4">
            B. 재화 보유 현황 (활성 계정 {activeUsers.length.toLocaleString()}명)
          </h3>
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
              <p className="text-sm text-gray-500 py-4 text-center">표시할 대회가 없습니다.</p>
            ) : (
              roomMonitor.map((room) => (
                <div
                  key={room.id}
                  className="flex items-center justify-between gap-3 px-3 py-2.5 rounded-lg bg-gray-900/50 border border-gray-700/80"
                >
                  <p className="text-sm text-gray-200 truncate">
                    {room.name} - 모집 인원 {room.current}/{room.max}명 (BEP {room.bep}%)
                  </p>
                  <span className="shrink-0 text-[11px] font-semibold text-emerald-400 whitespace-nowrap">
                    {statusLabel(room.status)}
                  </span>
                </div>
              ))
            )}
          </div>
        </div>

        <div className="bg-gray-800 p-6 rounded-xl border border-gray-700">
          <h3 className="text-gray-300 text-sm font-semibold mb-4">D. 실시간 운영 대기열</h3>
          <div className="space-y-2">
            <QueueLink
              to="/abuse"
              label="심사 대기 소명"
              value={waitingAppeals == null ? '…' : `${waitingAppeals}건`}
              alert={(waitingAppeals ?? 0) > 0}
            />
            <QueueLink
              to="/reports"
              label="미처리 신고"
              value={openReports == null ? '…' : `${openReports}건`}
              alert={(openReports ?? 0) > 0}
            />
            <QueueLink
              to="/runs"
              label="최근 검증된 달리기 (최근 40건 중)"
              value={verifiedRuns == null ? '…' : `${verifiedRuns}건`}
              alert={false}
            />
          </div>
        </div>
      </div>
    </div>
  );
}

import { useEffect, useState } from 'react';
import { Users } from 'lucide-react';
import { ensureAdminAuth } from '../../lib/adminAuth';
import {
  fetchReferrals,
  type ReferralList,
  type ReferralPayoutMarker,
} from '../../lib/jenaApi';

function payoutText(marker: ReferralPayoutMarker | null): string {
  if (!marker) return '-';
  const when = marker.createdAt || '-';
  return `${marker.amount.toLocaleString()} SHARE · ${when}`;
}

export default function Referrals() {
  const [cursor, setCursor] = useState<string | null>(null);
  const [page, setPage] = useState<ReferralList | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;
    setLoading(true);
    setError(null);
    void (async () => {
      try {
        const user = await ensureAdminAuth();
        if (!user) {
          if (!cancelled) setError('로그인 필요');
          return;
        }
        const next = await fetchReferrals(await user.getIdToken(), cursor);
        if (!cancelled) setPage(next);
      } catch (err) {
        if (cancelled) return;
        setPage(null);
        setError(
          err instanceof Error && err.message === 'forbidden'
            ? '권한 없음'
            : 'Jena에 연결하지 못했습니다. 재배포 전에는 이 주소가 없습니다.'
        );
      } finally {
        if (!cancelled) setLoading(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [cursor]);

  return (
    <div className="p-6 text-white h-full overflow-y-auto space-y-4">
      <div>
        <h2 className="text-2xl font-bold tracking-tight flex items-center gap-2">
          <Users size={22} className="text-emerald-400" />
          추천인
        </h2>
        <p className="text-sm text-gray-400 mt-1">
          추천 코드와 지급 마커를 조회합니다. 이 화면에서는 바꾸지 않습니다.
        </p>
        {error && <p className="text-xs text-amber-400 mt-1">{error}</p>}
      </div>

      <div className="bg-gray-800 rounded-xl border border-gray-700 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm text-gray-300">
            <thead className="text-xs uppercase bg-gray-900/60 text-gray-400 border-b border-gray-700">
              <tr>
                <th className="py-3 px-3">유저</th>
                <th className="py-3 px-3">코드</th>
                <th className="py-3 px-3">referredBy</th>
                <th className="py-3 px-3">referredByUid</th>
                <th className="py-3 px-3">체험</th>
                <th className="py-3 px-3">지급 횟수</th>
                <th className="py-3 px-3">redeem 10000</th>
                <th className="py-3 px-3">trial_referee 10,000 + 40,000</th>
                <th className="py-3 px-3">trial_referrer 30,000</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-700/50">
              {loading ? (
                <tr>
                  <td colSpan={9} className="py-8 text-center text-gray-400">
                    불러오는 중...
                  </td>
                </tr>
              ) : !page || page.users.length === 0 ? (
                <tr>
                  <td colSpan={9} className="py-8 text-center text-gray-400">
                    추천 기록이 없습니다.
                  </td>
                </tr>
              ) : (
                page.users.map((row) => (
                  <tr key={row.uid} className="align-top">
                    <td className="py-3 px-3 text-white">{row.uid}</td>
                    <td className="py-3 px-3">{row.referralCode || '-'}</td>
                    <td className="py-3 px-3">{row.referredBy || '-'}</td>
                    <td className="py-3 px-3">{row.referredByUid || '-'}</td>
                    <td className="py-3 px-3">
                      {row.trialRunCount}/{row.trialRunsRequired}
                    </td>
                    <td className="py-3 px-3">
                      {row.referralPayoutCount}/{row.referralPayoutMax}
                    </td>
                    <td className="py-3 px-3">{payoutText(row.payouts.redeem)}</td>
                    <td className="py-3 px-3">{payoutText(row.payouts.trial_referee)}</td>
                    <td className="py-3 px-3">{payoutText(row.payouts.trial_referrer)}</td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      <div className="flex gap-2">
        <button
          type="button"
          disabled={!cursor || loading}
          onClick={() => setCursor(null)}
          className="px-3 py-2 rounded-lg bg-gray-800 border border-gray-700 text-sm disabled:text-gray-600"
        >
          처음
        </button>
        <button
          type="button"
          disabled={!page?.nextCursor || loading}
          onClick={() => page?.nextCursor && setCursor(page.nextCursor)}
          className="px-3 py-2 rounded-lg bg-gray-800 border border-gray-700 text-sm disabled:text-gray-600"
        >
          다음
        </button>
      </div>
    </div>
  );
}

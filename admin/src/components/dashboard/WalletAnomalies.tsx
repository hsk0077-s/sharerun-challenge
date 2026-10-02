import { useEffect, useState, type FormEvent } from 'react';
import { AlertTriangle } from 'lucide-react';
import { ensureAdminAuth } from '../../lib/adminAuth';
import { fetchWalletAnomalies, type WalletAnomalyList } from '../../lib/jenaApi';

const REASON_LABEL: Record<string, string> = {
  debug_test_grant_1m: '디버그 100만 지급',
  unmatched_receipt: '영수증 금액 불일치',
  payment_amount_mismatch: '결제 금액 불일치',
  negative_balance: '음수 잔액',
  receipt_uid_mismatch: '영수증 uid 불일치',
};

function balanceText(row: WalletAnomalyList['rows'][number]): string {
  if (
    row.shareBalance == null &&
    row.diamondBalance == null &&
    row.valueTokenBalance == null
  ) {
    return '-';
  }
  return `S ${row.shareBalance ?? '-'} · D ${row.diamondBalance ?? '-'} · V ${row.valueTokenBalance ?? '-'}`;
}

export default function WalletAnomalies() {
  const [draftUid, setDraftUid] = useState('');
  const [uid, setUid] = useState('');
  const [cursor, setCursor] = useState<string | null>(null);
  const [page, setPage] = useState<WalletAnomalyList | null>(null);
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
        const next = await fetchWalletAnomalies(await user.getIdToken(), { uid, cursor });
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
  }, [uid, cursor]);

  const onSearch = (event: FormEvent) => {
    event.preventDefault();
    setCursor(null);
    setUid(draftUid.trim());
  };

  return (
    <div className="p-6 text-white h-full overflow-y-auto space-y-4">
      <div>
        <h2 className="text-2xl font-bold tracking-tight flex items-center gap-2">
          <AlertTriangle size={22} className="text-amber-400" />
          지갑 이상
        </h2>
        <p className="text-sm text-gray-400 mt-1">
          이상 후보를 조회합니다. 차감하거나 숫자를 바꾸지 않습니다.
        </p>
        {error && <p className="text-xs text-amber-400 mt-1">{error}</p>}
        {page?.truncated && (
          <p className="text-xs text-amber-400 mt-1">
            영수증·원장 일부만 확인했습니다. uid로 범위를 좁혀 주세요.
          </p>
        )}
      </div>

      <form onSubmit={onSearch} className="flex flex-wrap items-end gap-3">
        <label className="text-xs text-gray-400">
          uid
          <input
            value={draftUid}
            onChange={(event) => setDraftUid(event.target.value)}
            className="mt-1 block bg-gray-900 border border-gray-700 rounded-lg px-3 py-2 text-sm text-white"
            placeholder="비우면 사용자 순서로 조회"
          />
        </label>
        <button
          type="submit"
          className="px-3 py-2 rounded-lg bg-gray-800 border border-gray-700 text-sm"
        >
          조회
        </button>
      </form>

      <div className="bg-gray-800 rounded-xl border border-gray-700 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm text-gray-300">
            <thead className="text-xs uppercase bg-gray-900/60 text-gray-400 border-b border-gray-700">
              <tr>
                <th className="py-3 px-3">유저</th>
                <th className="py-3 px-3">이유</th>
                <th className="py-3 px-3">설명</th>
                <th className="py-3 px-3">잔액</th>
                <th className="py-3 px-3">문서</th>
                <th className="py-3 px-3">금액</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-700/50">
              {loading ? (
                <tr>
                  <td colSpan={6} className="py-8 text-center text-gray-400">
                    불러오는 중...
                  </td>
                </tr>
              ) : !page || page.rows.length === 0 ? (
                <tr>
                  <td colSpan={6} className="py-8 text-center text-gray-400">
                    이 구간에 이상이 없습니다.
                  </td>
                </tr>
              ) : (
                page.rows.map((row) => (
                  <tr key={`${row.uid}-${row.reason}-${row.receiptId ?? ''}`} className="align-top">
                    <td className="py-3 px-3 text-white">{row.uid}</td>
                    <td className="py-3 px-3 text-amber-200">
                      {REASON_LABEL[row.reason] || row.reason}
                    </td>
                    <td className="py-3 px-3">{row.detail}</td>
                    <td className="py-3 px-3">{balanceText(row)}</td>
                    <td className="py-3 px-3">{row.receiptId || '-'}</td>
                    <td className="py-3 px-3">
                      {row.amount == null
                        ? '-'
                        : `${row.amount.toLocaleString()}${row.assetType ? ` ${row.assetType}` : ''}`}
                    </td>
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

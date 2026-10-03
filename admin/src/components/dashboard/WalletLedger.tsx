import { useEffect, useMemo, useState, type FormEvent } from 'react';
import { Wallet } from 'lucide-react';
import { ensureAdminAuth } from '../../lib/adminAuth';
import { fetchWalletLedger, type WalletLedger as Ledger } from '../../lib/jenaApi';
import { subscribeUsers, type AdminUser } from '../../lib/firestoreUsers';

function matches(user: AdminUser, query: string): boolean {
  const needle = query.trim().toLowerCase();
  if (!needle) return false;
  return [user.nickname, user.user_id, user.id, user.email].some((value) =>
    value.toLowerCase().includes(needle)
  );
}

function signed(amount: number): string {
  const text = amount.toLocaleString();
  return amount > 0 ? `+${text}` : text;
}

export default function WalletLedger() {
  const [users, setUsers] = useState<AdminUser[] | null>(null);
  const [draft, setDraft] = useState('');
  const [query, setQuery] = useState('');
  const [ledger, setLedger] = useState<Ledger | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    return subscribeUsers({
      onData: setUsers,
      onError: () => setUsers([]),
    });
  }, []);

  const hits = useMemo(
    () => (query.trim() ? (users ?? []).filter((user) => matches(user, query)) : []),
    [users, query]
  );

  const load = async (uid: string) => {
    setLoading(true);
    setError(null);
    try {
      const admin = await ensureAdminAuth();
      if (!admin) {
        setError('로그인 필요');
        setLedger(null);
        return;
      }
      setLedger(await fetchWalletLedger(await admin.getIdToken(), uid));
    } catch (err) {
      setLedger(null);
      const message = err instanceof Error ? err.message : '';
      setError(
        message === 'forbidden'
          ? '권한 없음'
          : message === 'missing'
            ? '사용자를 찾지 못했습니다.'
            : 'Jena에 연결하지 못했습니다. 재배포 전에는 이 주소가 없습니다.'
      );
    } finally {
      setLoading(false);
    }
  };

  const onSearch = (event: FormEvent) => {
    event.preventDefault();
    const next = draft.trim();
    setQuery(next);
    if (!next) return;
    const found = (users ?? []).filter((user) => matches(user, next));
    if (found.length === 1) {
      void load(found[0].id);
      return;
    }
    if (found.length === 0) void load(next);
  };

  return (
    <div className="p-6 text-white h-full overflow-y-auto space-y-4">
      <div>
        <h2 className="text-2xl font-bold tracking-tight flex items-center gap-2">
          <Wallet size={22} className="text-emerald-400" />
          지갑 원장
        </h2>
        <p className="text-sm text-gray-400 mt-1">
          계좌의 잔액과 원장을 조회합니다. 숫자는 바꾸지 않습니다.
        </p>
        <p className="text-xs text-gray-500 mt-1">
          테스트 계정에 넣은 1,000,000은 원장 행이 없습니다. 그 차이도 숨기지 않고 표시합니다.
        </p>
        {error && <p className="text-xs text-amber-400 mt-1">{error}</p>}
      </div>

      <form onSubmit={onSearch} className="flex flex-wrap items-end gap-3">
        <label className="text-xs text-gray-400">
          uid / 이메일 / 닉네임
          <input
            value={draft}
            onChange={(event) => setDraft(event.target.value)}
            className="mt-1 block bg-gray-900 border border-gray-700 rounded-lg px-3 py-2 text-sm text-white w-72"
            placeholder="정확히 한 명이면 원장을 엽니다"
          />
        </label>
        <button
          type="submit"
          className="px-3 py-2 rounded-lg bg-gray-800 border border-gray-700 text-sm"
        >
          조회
        </button>
      </form>

      {query && hits.length > 1 && (
        <div className="flex flex-wrap gap-2">
          {hits.map((user) => (
            <button
              key={user.id}
              type="button"
              onClick={() => void load(user.id)}
              className="px-3 py-2 rounded-lg bg-gray-800 border border-gray-700 text-sm text-left"
            >
              <span className="text-white">{user.nickname}</span>
              <span className="block text-xs text-gray-400">{user.email || user.id}</span>
            </button>
          ))}
        </div>
      )}

      {loading && <p className="text-sm text-gray-400">불러오는 중...</p>}

      {ledger && (
        <div className="space-y-4">
          <p className="text-sm text-gray-300">
            {ledger.nickname || '-'} · {ledger.email || '-'} · {ledger.uid}
          </p>
          {ledger.truncated && (
            <p className="text-xs text-amber-400">
              원장 2000건까지만 읽었습니다. 합계가 전체와 다를 수 있습니다.
            </p>
          )}
          <div className="bg-gray-800 rounded-xl border border-gray-700 overflow-hidden">
            <table className="w-full text-left text-sm text-gray-300">
              <thead className="text-xs uppercase bg-gray-900/60 text-gray-400 border-b border-gray-700">
                <tr>
                  <th className="py-3 px-3">통화</th>
                  <th className="py-3 px-3">잔액</th>
                  <th className="py-3 px-3">원장 합계</th>
                  <th className="py-3 px-3">차이</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-700/50">
                {ledger.currencies.map((row) => (
                  <tr key={row.currency}>
                    <td className="py-3 px-3 text-white">{row.currency}</td>
                    <td className="py-3 px-3">{row.balance.toLocaleString()}</td>
                    <td className="py-3 px-3">{row.ledgerSum.toLocaleString()}</td>
                    <td className={`py-3 px-3 ${row.mismatch ? 'text-amber-300' : ''}`}>
                      {row.mismatch
                        ? `불일치 ${(row.balance - row.ledgerSum).toLocaleString()}`
                        : '일치'}
                      {row.seedGap
                        ? ' · 시드 1,000,000은 원장 행이 없습니다. 예상된 불일치입니다.'
                        : ''}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          <div className="bg-gray-800 rounded-xl border border-gray-700 overflow-hidden">
            <div className="overflow-x-auto">
              <table className="w-full text-left text-sm text-gray-300">
                <thead className="text-xs uppercase bg-gray-900/60 text-gray-400 border-b border-gray-700">
                  <tr>
                    <th className="py-3 px-3">시간 (KST)</th>
                    <th className="py-3 px-3">type</th>
                    <th className="py-3 px-3">통화</th>
                    <th className="py-3 px-3">금액</th>
                    <th className="py-3 px-3">관련 id</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-700/50">
                  {ledger.entries.length === 0 ? (
                    <tr>
                      <td colSpan={5} className="py-8 text-center text-gray-400">
                        원장 행이 없습니다.
                      </td>
                    </tr>
                  ) : (
                    ledger.entries.map((row) => (
                      <tr key={`${row.id}-${row.currency}`}>
                        <td className="py-3 px-3">{row.timeKst || '-'}</td>
                        <td className="py-3 px-3">{row.type}</td>
                        <td className="py-3 px-3">{row.currency}</td>
                        <td className="py-3 px-3">{signed(row.amount)}</td>
                        <td className="py-3 px-3 break-all">{row.relatedId || '-'}</td>
                      </tr>
                    ))
                  )}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

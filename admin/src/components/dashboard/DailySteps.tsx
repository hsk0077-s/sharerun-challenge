import { useEffect, useState, type FormEvent } from 'react';
import { Activity } from 'lucide-react';
import { ensureAdminAuth } from '../../lib/adminAuth';
import { fetchDailySteps, type DailyStepsPage } from '../../lib/jenaApi';

type Filter = { uid: string; from: string; to: string };

export default function DailySteps() {
  const [draft, setDraft] = useState<Filter>({ uid: '', from: '', to: '' });
  const [filter, setFilter] = useState<Filter>({ uid: '', from: '', to: '' });
  const [page, setPage] = useState<DailyStepsPage | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [anomaliesOnly, setAnomaliesOnly] = useState(false);

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
        const next = await fetchDailySteps(await user.getIdToken(), filter);
        if (cancelled) return;
        setPage(next);
        setDraft((current) => ({
          uid: current.uid,
          from: current.from || next.start,
          to: current.to || next.end,
        }));
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
  }, [filter]);

  const onSearch = (event: FormEvent) => {
    event.preventDefault();
    setFilter({
      uid: draft.uid.trim(),
      from: draft.from,
      to: draft.to,
    });
  };

  const rows = (page?.rows ?? []).filter((row) => !anomaliesOnly || row.anomaly);

  return (
    <div className="p-6 text-white h-full overflow-y-auto space-y-4">
      <div>
        <h2 className="text-2xl font-bold tracking-tight flex items-center gap-2">
          <Activity size={22} className="text-emerald-400" />
          일별 걸음
        </h2>
        <p className="text-sm text-gray-400 mt-1">
          걸음 수를 조회합니다. 숫자는 바꾸지 않습니다.
        </p>
        {error && <p className="text-xs text-amber-400 mt-1">{error}</p>}
        {page?.truncated && (
          <p className="text-xs text-amber-400 mt-1">
            일부만 불러왔습니다. uid로 범위를 좁혀 주세요.
          </p>
        )}
      </div>

      <form onSubmit={onSearch} className="flex flex-wrap items-end gap-3">
        <label className="text-xs text-gray-400">
          uid
          <input
            value={draft.uid}
            onChange={(event) => setDraft({ ...draft, uid: event.target.value })}
            className="mt-1 block bg-gray-900 border border-gray-700 rounded-lg px-3 py-2 text-sm text-white"
            placeholder="비우면 전체"
          />
        </label>
        <label className="text-xs text-gray-400">
          부터
          <input
            type="date"
            value={draft.from}
            onChange={(event) => setDraft({ ...draft, from: event.target.value })}
            className="mt-1 block bg-gray-900 border border-gray-700 rounded-lg px-3 py-2 text-sm text-white"
          />
        </label>
        <label className="text-xs text-gray-400">
          까지
          <input
            type="date"
            value={draft.to}
            onChange={(event) => setDraft({ ...draft, to: event.target.value })}
            className="mt-1 block bg-gray-900 border border-gray-700 rounded-lg px-3 py-2 text-sm text-white"
          />
        </label>
        <button
          type="submit"
          className="px-3 py-2 rounded-lg bg-gray-800 border border-gray-700 text-sm"
        >
          조회
        </button>
        <label className="flex items-center gap-2 text-sm text-gray-300 pb-2">
          <input
            type="checkbox"
            checked={anomaliesOnly}
            onChange={(event) => setAnomaliesOnly(event.target.checked)}
          />
          이상만 보기
        </label>
      </form>

      <div className="bg-gray-800 rounded-xl border border-gray-700 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm text-gray-300">
            <thead className="text-xs uppercase bg-gray-900/60 text-gray-400 border-b border-gray-700">
              <tr>
                <th className="py-3 px-3">유저</th>
                <th className="py-3 px-3">날짜</th>
                <th className="py-3 px-3">걸음</th>
                <th className="py-3 px-3">source</th>
                <th className="py-3 px-3">lastHealth</th>
                <th className="py-3 px-3">updatedAt</th>
                <th className="py-3 px-3">이상</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-700/50">
              {loading ? (
                <tr>
                  <td colSpan={7} className="py-8 text-center text-gray-400">
                    불러오는 중...
                  </td>
                </tr>
              ) : rows.length === 0 ? (
                <tr>
                  <td colSpan={7} className="py-8 text-center text-gray-400">
                    {anomaliesOnly ? '이상 기록이 없습니다.' : '걸음 기록이 없습니다.'}
                  </td>
                </tr>
              ) : (
                rows.map((row) => (
                  <tr key={`${row.uid}-${row.day}`}>
                    <td className="py-3 px-3 text-white">{row.uid}</td>
                    <td className="py-3 px-3">{row.day}</td>
                    <td className="py-3 px-3">{row.steps.toLocaleString()}</td>
                    <td className="py-3 px-3">{row.source || '-'}</td>
                    <td className="py-3 px-3">
                      {row.lastHealth == null ? '-' : row.lastHealth.toLocaleString()}
                    </td>
                    <td className="py-3 px-3">{row.updatedAt || '-'}</td>
                    <td className={`py-3 px-3 ${row.anomaly ? 'text-amber-300' : ''}`}>
                      {row.anomaly ? '이상' : '-'}
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}

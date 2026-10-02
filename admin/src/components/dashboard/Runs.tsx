import { useEffect, useMemo, useState } from 'react';
import { Flag } from 'lucide-react';
import {
  fetchTrialRunCounts,
  subscribeRecentRuns,
  type AdminRun,
} from '../../lib/firestoreOps';

const TRIAL_RUNS_REQUIRED = 5;

function isWatchLinkDoc(id: string): boolean {
  return id.startsWith('watch-link-');
}

function formatDuration(seconds: number | null): string {
  if (seconds == null) return '-';
  const whole = Math.max(0, Math.trunc(seconds));
  const mm = Math.floor(whole / 60);
  const ss = whole % 60;
  return `${mm}:${ss.toString().padStart(2, '0')}`;
}

function formatDistance(km: number | null): string {
  if (km == null) return '-';
  return `${km.toLocaleString()} km`;
}

function trialText(count: number | null | undefined, known: boolean): string {
  if (!known) return '…';
  if (count == null) return `-/${TRIAL_RUNS_REQUIRED}`;
  return `${count}/${TRIAL_RUNS_REQUIRED}`;
}

export default function Runs() {
  const [runs, setRuns] = useState<AdminRun[] | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [trials, setTrials] = useState<Record<string, number | null>>({});
  const [trialsReady, setTrialsReady] = useState(false);

  useEffect(() => {
    return subscribeRecentRuns({
      onData: (rows) => {
        setRuns(rows);
        setError(null);
      },
      onError: () => setError('activities를 읽지 못했습니다.'),
    });
  }, []);

  const visible = useMemo(
    () => (runs ?? []).filter((run) => !isWatchLinkDoc(run.id)),
    [runs]
  );

  const uids = useMemo(
    () => [...new Set(visible.map((run) => run.userId).filter(Boolean))],
    [visible]
  );

  useEffect(() => {
    let cancelled = false;
    setTrialsReady(false);
    void fetchTrialRunCounts(uids)
      .then((next) => {
        if (!cancelled) setTrials(next);
      })
      .catch(() => {
        if (!cancelled) setTrials({});
      })
      .finally(() => {
        if (!cancelled) setTrialsReady(true);
      });
    return () => {
      cancelled = true;
    };
  }, [uids]);

  return (
    <div className="p-6 text-white h-full overflow-y-auto space-y-4">
      <div>
        <h2 className="text-2xl font-bold tracking-tight flex items-center gap-2">
          <Flag size={22} className="text-emerald-400" />
          런 검증
        </h2>
        <p className="text-sm text-gray-400 mt-1">
          최근 활동을 조회합니다. 판정과 체험 횟수는 바꾸지 않습니다. watch-link 문서는 제외합니다.
        </p>
        {error && <p className="text-xs text-amber-400 mt-1">{error}</p>}
      </div>

      <div className="bg-gray-800 rounded-xl border border-gray-700 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm text-gray-300">
            <thead className="text-xs uppercase bg-gray-900/60 text-gray-400 border-b border-gray-700">
              <tr>
                <th className="py-3 px-3">활동</th>
                <th className="py-3 px-3">uid</th>
                <th className="py-3 px-3">jenaDecision</th>
                <th className="py-3 px-3">사유</th>
                <th className="py-3 px-3">validationFinalized</th>
                <th className="py-3 px-3">거리</th>
                <th className="py-3 px-3">시간</th>
                <th className="py-3 px-3">체험</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-700/50">
              {runs === null ? (
                <tr>
                  <td colSpan={8} className="py-8 text-center text-gray-400">
                    불러오는 중...
                  </td>
                </tr>
              ) : visible.length === 0 ? (
                <tr>
                  <td colSpan={8} className="py-8 text-center text-gray-400">
                    최근 활동이 없습니다.
                  </td>
                </tr>
              ) : (
                visible.map((run) => (
                  <tr key={run.id} className="align-top">
                    <td className="py-3 px-3 text-white break-all">{run.id}</td>
                    <td className="py-3 px-3 break-all">{run.userId || '-'}</td>
                    <td className="py-3 px-3">{run.jenaDecision || '-'}</td>
                    <td className="py-3 px-3">{run.jenaReason || '-'}</td>
                    <td className="py-3 px-3">{run.validationFinalized ? 'true' : 'false'}</td>
                    <td className="py-3 px-3">{formatDistance(run.distanceKm)}</td>
                    <td className="py-3 px-3">{formatDuration(run.durationSeconds)}</td>
                    <td className="py-3 px-3">
                      {run.userId
                        ? trialText(trials[run.userId], trialsReady || run.userId in trials)
                        : '-'}
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

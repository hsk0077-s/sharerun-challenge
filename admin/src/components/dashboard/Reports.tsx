import { useCallback, useEffect, useState } from 'react';
import { Flag } from 'lucide-react';
import { ensureAdminAuth } from '../../lib/adminAuth';
import {
  fetchReports,
  updateReportStatus,
  type AdminReport,
  type ReportStatus,
} from '../../lib/jenaApi';

const TABS: { status: ReportStatus; label: string }[] = [
  { status: 'open', label: '대기' },
  { status: 'reviewed', label: '검토됨' },
  { status: 'resolved', label: '조치 완료' },
  { status: 'dismissed', label: '기각' },
];

const ACTIONS: { status: Exclude<ReportStatus, 'open'>; label: string; style: string }[] = [
  { status: 'reviewed', label: '검토됨', style: 'bg-sky-900/60 border-sky-700 text-sky-200' },
  { status: 'resolved', label: '조치 완료', style: 'bg-emerald-900/60 border-emerald-700 text-emerald-200' },
  { status: 'dismissed', label: '기각', style: 'bg-gray-800 border-gray-600 text-gray-300' },
];

function formatWhen(iso: string | null): string {
  if (!iso) return '-';
  const date = new Date(iso);
  return Number.isNaN(date.getTime()) ? '-' : date.toLocaleString('ko-KR');
}

function errorText(err: unknown): string {
  return err instanceof Error && err.message === 'forbidden'
    ? '권한 없음'
    : 'Jena에 연결하지 못했습니다.';
}

export default function Reports() {
  const [tab, setTab] = useState<ReportStatus>('open');
  const [rows, setRows] = useState<AdminReport[] | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [notes, setNotes] = useState<Record<string, string>>({});
  const [busyId, setBusyId] = useState<string | null>(null);

  const load = useCallback(async (status: ReportStatus) => {
    setRows(null);
    setError(null);
    try {
      const user = await ensureAdminAuth();
      if (!user) {
        setError('로그인 필요');
        setRows([]);
        return;
      }
      setRows(await fetchReports(await user.getIdToken(), status));
    } catch (err) {
      setError(errorText(err));
      setRows([]);
    }
  }, []);

  useEffect(() => {
    void load(tab);
  }, [tab, load]);

  const change = async (report: AdminReport, status: Exclude<ReportStatus, 'open'>) => {
    if (busyId) return;
    setBusyId(report.id);
    setError(null);
    try {
      const user = await ensureAdminAuth();
      if (!user) throw new Error('forbidden');
      await updateReportStatus(
        await user.getIdToken(),
        report.id,
        status,
        (notes[report.id] ?? '').trim()
      );
      await load(tab);
    } catch (err) {
      setError(errorText(err));
    } finally {
      setBusyId(null);
    }
  };

  return (
    <div className="p-6 text-white h-full overflow-y-auto space-y-4">
      <div>
        <h2 className="text-2xl font-bold tracking-tight flex items-center gap-2">
          <Flag size={22} className="text-emerald-400" />
          신고 관리
        </h2>
        <p className="text-sm text-gray-400 mt-1">
          이름 신고를 접수 순서대로 처리합니다. 상태 변경은 감사 로그에 남습니다.
        </p>
        {error && <p className="text-xs text-amber-400 mt-1">{error}</p>}
      </div>

      <div className="flex gap-2">
        {TABS.map((item) => (
          <button
            key={item.status}
            type="button"
            onClick={() => setTab(item.status)}
            className={`px-3 py-1.5 rounded-lg border text-sm ${
              tab === item.status
                ? 'bg-gray-900 border-emerald-600 text-emerald-400 font-bold'
                : 'bg-gray-800 border-gray-700 text-gray-400'
            }`}
          >
            {item.label}
          </button>
        ))}
      </div>

      <div className="space-y-3">
        {rows === null ? (
          <p className="text-center text-gray-500 text-sm py-8">불러오는 중...</p>
        ) : rows.length === 0 ? (
          <p className="text-center text-gray-500 text-sm py-8">신고가 없습니다.</p>
        ) : (
          rows.map((report) => (
            <div
              key={report.id}
              className="rounded-xl p-4 bg-gray-800 border border-gray-700 space-y-2"
            >
              <div className="flex flex-wrap items-baseline justify-between gap-2">
                <p className="font-semibold text-white">
                  {report.targetName || report.targetId || '-'}
                  <span className="ml-2 text-xs font-normal text-gray-400">
                    {report.targetType || '-'}
                  </span>
                </p>
                <span className="text-xs text-gray-500">{formatWhen(report.createdAt)}</span>
              </div>
              <p className="text-sm text-gray-200">사유: {report.reason || '-'}</p>
              {report.detail ? (
                <p className="text-sm text-gray-400 whitespace-pre-wrap">{report.detail}</p>
              ) : null}
              <p className="text-xs text-gray-500 truncate">신고자 {report.reporterUid || '-'}</p>
              <div className="flex flex-wrap items-center gap-2 pt-1">
                <input
                  value={notes[report.id] ?? ''}
                  onChange={(event) =>
                    setNotes((current) => ({ ...current, [report.id]: event.target.value }))
                  }
                  maxLength={300}
                  placeholder="처리 메모 (선택)"
                  className="flex-1 min-w-48 bg-gray-900 border border-gray-700 rounded-lg px-3 py-1.5 text-sm text-white"
                />
                {ACTIONS.filter((action) => action.status !== tab).map((action) => (
                  <button
                    key={action.status}
                    type="button"
                    disabled={busyId !== null}
                    onClick={() => void change(report, action.status)}
                    className={`px-3 py-1.5 rounded-lg border text-sm disabled:opacity-50 ${action.style}`}
                  >
                    {action.label}
                  </button>
                ))}
              </div>
            </div>
          ))
        )}
      </div>
    </div>
  );
}

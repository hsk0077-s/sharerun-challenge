import { useEffect, useMemo, useState } from 'react';
import { AlertTriangle, CheckCircle, ShieldAlert, XCircle } from 'lucide-react';
import {
  subscribeActivities,
  subscribeAppeals,
  updateAppealStatus,
  type AdminActivity,
  type AdminAppeal,
} from '../../lib/firestoreOps';

const SERVER_DECISIONS = new Set([
  'verified',
  'rejected_kickboard',
  'rejected_bike',
  'rejected_unknown',
]);

function isWatchLinkDoc(id: string): boolean {
  return id.startsWith('watch-link-');
}

function isWaitingAppeal(status: string): boolean {
  return status === 'under_review' || status === 'pending';
}

function appealStatusLabel(status: string): string {
  if (status === 'under_review') return '심사 중';
  if (status === 'pending') return '대기';
  if (status === 'approved') return '승인';
  if (status === 'rejected') return '기각';
  if (!status) return '-';
  return status;
}

function formatWhen(iso: string): string {
  if (!iso) return '-';
  const date = new Date(iso);
  if (Number.isNaN(date.getTime())) return '-';
  return date.toLocaleString('ko-KR');
}

function isServerDecided(activity: AdminActivity): boolean {
  if (isWatchLinkDoc(activity.id)) return false;
  if (activity.validationFinalized) return true;
  return activity.jenaDecision != null && SERVER_DECISIONS.has(activity.jenaDecision);
}

function ProofBlock({ uri }: { uri: string }) {
  const [broken, setBroken] = useState(false);
  const http = uri.startsWith('https://') || uri.startsWith('http://');
  if (!uri) return <p className="text-sm text-gray-500">증빙 주소 없음</p>;
  return (
    <div className="space-y-2">
      {http && !broken ? (
        <img
          src={uri}
          alt="소명 증빙"
          className="max-h-64 rounded-lg border border-gray-700"
          onError={() => setBroken(true)}
        />
      ) : null}
      <p className="text-xs text-gray-400 break-all">{uri}</p>
    </div>
  );
}

export default function AbuseAudit() {
  const [appeals, setAppeals] = useState<AdminAppeal[] | null>(null);
  const [activities, setActivities] = useState<AdminActivity[] | null>(null);
  const [appealError, setAppealError] = useState<string | null>(null);
  const [activityError, setActivityError] = useState<string | null>(null);
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);
  const [actionError, setActionError] = useState<string | null>(null);

  useEffect(() => {
    return subscribeAppeals(
      {
        onData: (rows) => {
          setAppeals(rows);
          setAppealError(null);
        },
        onError: (err) => {
          console.error('[AbuseAudit appeals]', err);
          setAppealError(err.message);
          setAppeals([]);
        },
      },
      { limitCount: 80 }
    );
  }, []);

  useEffect(() => {
    return subscribeActivities(
      {
        onData: (rows) => {
          setActivities(rows);
          setActivityError(null);
        },
        onError: (err) => {
          console.error('[AbuseAudit activities]', err);
          setActivityError(err.message);
          setActivities([]);
        },
      },
      { limitCount: 60 }
    );
  }, []);

  const queue = useMemo(() => {
    const rows = (appeals ?? []).filter((appeal) => isWaitingAppeal(appeal.status));
    return rows.slice().sort((a, b) => (b.createdAt || '').localeCompare(a.createdAt || ''));
  }, [appeals]);

  const decided = useMemo(
    () => (activities ?? []).filter(isServerDecided),
    [activities]
  );

  useEffect(() => {
    if (queue.length === 0) {
      setSelectedId(null);
      return;
    }
    if (!selectedId || !queue.some((appeal) => appeal.id === selectedId)) {
      setSelectedId(queue[0]!.id);
    }
  }, [queue, selectedId]);

  const selected = queue.find((appeal) => appeal.id === selectedId) ?? null;
  const linked = selected
    ? decided.find((activity) => activity.id === selected.activityId) ?? null
    : null;

  const setStatus = async (status: 'approved' | 'rejected') => {
    if (!selected || busy) return;
    setBusy(true);
    setActionError(null);
    try {
      await updateAppealStatus(selected.id, status);
    } catch (err) {
      setActionError(err instanceof Error ? err.message : '소명 상태를 바꾸지 못했습니다.');
    } finally {
      setBusy(false);
    }
  };

  return (
    <div className="h-full overflow-hidden text-white flex flex-col">
      <div className="px-6 pt-5 pb-3 shrink-0">
        <h2 className="text-xl font-bold tracking-tight flex items-center gap-2">
          <ShieldAlert size={22} className="text-orange-400" />
          Jena 어뷰징 심사 · 소명 심사
        </h2>
        <p className="text-sm text-gray-400 mt-1">
          소명 문서와 서버 활동 판정을 조회합니다. 승인·기각은 소명 status만 바꿉니다.
        </p>
        {appealError && (
          <p className="text-xs text-amber-400 mt-1">appeals: {appealError}</p>
        )}
        {activityError && (
          <p className="text-xs text-amber-400 mt-1">activities: {activityError}</p>
        )}
      </div>

      <div className="flex-1 min-h-0 grid grid-cols-1 lg:grid-cols-[340px_1fr] gap-4 px-6 pb-6">
        <section className="bg-gray-800/80 border border-gray-700 rounded-xl flex flex-col min-h-0 overflow-hidden">
          <div className="px-4 py-3 border-b border-gray-700 shrink-0">
            <h3 className="font-bold text-white">소명 대기 리스트</h3>
            <p className="text-xs text-gray-400 mt-0.5">심사 대기 목록 ({queue.length}건)</p>
          </div>
          <div className="flex-1 overflow-y-auto p-3 space-y-2">
            {appeals === null ? (
              <p className="text-center text-gray-500 text-sm py-8">불러오는 중...</p>
            ) : queue.length === 0 ? (
              <div className="flex flex-col items-center justify-center text-gray-500 gap-2 py-12">
                <CheckCircle size={28} className="text-emerald-500/50" />
                <p className="text-sm">심사 대기 안건이 없습니다.</p>
              </div>
            ) : (
              queue.map((item) => {
                const active = item.id === selectedId;
                const name = item.userNickname || item.userId || item.id;
                return (
                  <button
                    key={item.id}
                    type="button"
                    onClick={() => setSelectedId(item.id)}
                    className={`w-full text-left rounded-xl px-3 py-3 transition-colors border ${
                      active
                        ? 'bg-orange-950/40 border-orange-500 shadow-[0_0_0_1px_rgba(249,115,22,0.35)]'
                        : 'bg-gray-900/50 border-gray-700 hover:border-gray-500'
                    }`}
                  >
                    <div className="flex items-start gap-2">
                      <AlertTriangle
                        size={16}
                        className={`mt-0.5 shrink-0 ${active ? 'text-orange-400' : 'text-amber-500'}`}
                      />
                      <div className="min-w-0">
                        <p className="text-sm font-semibold text-white truncate">
                          {name}{' '}
                          <span className="text-gray-400 font-normal">
                            · {appealStatusLabel(item.status)}
                          </span>
                        </p>
                        <p className="text-xs text-gray-400 mt-1 truncate">
                          {item.reasonDetail || '-'}
                        </p>
                      </div>
                    </div>
                  </button>
                );
              })
            )}
          </div>
        </section>

        <section className="bg-gray-800/80 border border-gray-700 rounded-xl flex flex-col min-h-0 overflow-hidden">
          <div className="px-5 py-3 border-b border-gray-700 shrink-0">
            <h3 className="font-bold text-white">상세 심사 및 판결 화면</h3>
          </div>
          <div className="flex-1 overflow-y-auto p-5 space-y-4">
            {!selected ? (
              <p className="text-sm text-gray-500">좌측에서 소명 건을 선택하세요.</p>
            ) : (
              <>
                <div className="flex flex-wrap items-baseline justify-between gap-2">
                  <div>
                    <p className="text-lg font-bold text-white">
                      {selected.userNickname || selected.userId || selected.id}
                    </p>
                    <p className="text-xs text-gray-400 mt-0.5">
                      {selected.id} · uid {selected.userId || '-'} · activity {selected.activityId || '-'}
                    </p>
                  </div>
                  <p className="text-xs text-gray-500">
                    {appealStatusLabel(selected.status)} · {formatWhen(selected.createdAt)}
                  </p>
                </div>

                <div className="bg-gray-900/70 border border-gray-700 rounded-xl p-4">
                  <p className="text-xs text-gray-500 mb-2 font-medium">소명 상세 (reasonDetail)</p>
                  <p className="text-sm text-gray-200 leading-relaxed whitespace-pre-wrap">
                    {selected.reasonDetail || '-'}
                  </p>
                </div>

                <div className="bg-gray-900/70 border border-gray-700 rounded-xl p-4">
                  <p className="text-xs text-gray-500 mb-2 font-medium">증빙 (proofImageUri)</p>
                  <ProofBlock uri={selected.proofImageUri} />
                </div>

                <div className="bg-gray-900/70 border border-gray-700 rounded-xl p-4 text-sm text-gray-300 space-y-1">
                  <p className="text-xs text-gray-500 font-medium mb-2">연결 활동 판정</p>
                  {isWatchLinkDoc(selected.activityId) ? (
                    <p>watch-link 문서는 판정 목록에서 제외합니다.</p>
                  ) : linked ? (
                    <>
                      <p>jenaDecision: {linked.jenaDecision || '-'}</p>
                      <p>validationFinalized: {linked.validationFinalized ? 'true' : 'false'}</p>
                      <p>verified: {linked.jenaVerified ? 'true' : 'false'}</p>
                      {linked.jenaReason ? <p>jenaReason: {linked.jenaReason}</p> : null}
                      <p>거리 {linked.distanceKm.toLocaleString()} km</p>
                    </>
                  ) : (
                    <p>최근 활동 목록에서 이 activityId를 찾지 못했습니다.</p>
                  )}
                </div>

                <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                  <button
                    type="button"
                    disabled={busy}
                    onClick={() => void setStatus('approved')}
                    className="flex items-center justify-center gap-2 rounded-xl px-4 py-3.5 bg-emerald-700 hover:bg-emerald-600 disabled:bg-gray-700 disabled:text-gray-500 text-white font-bold text-sm transition-colors"
                  >
                    <CheckCircle size={18} />
                    소명 승인
                  </button>
                  <button
                    type="button"
                    disabled={busy}
                    onClick={() => void setStatus('rejected')}
                    className="flex items-center justify-center gap-2 rounded-xl px-4 py-3.5 bg-red-900/90 hover:bg-red-800 disabled:bg-gray-700 disabled:text-gray-500 text-white font-bold text-sm transition-colors border border-red-800"
                  >
                    <XCircle size={18} />
                    소명 기각
                  </button>
                </div>
                {actionError && (
                  <p className="text-xs text-amber-400">{actionError}</p>
                )}
              </>
            )}

            <div className="border-t border-gray-700 pt-4">
              <h4 className="text-sm font-semibold text-gray-300 mb-3">활동 판정</h4>
              {activities === null ? (
                <p className="text-sm text-gray-500">불러오는 중...</p>
              ) : decided.length === 0 ? (
                <p className="text-sm text-gray-500">판정된 활동이 없습니다.</p>
              ) : (
                <div className="space-y-2">
                  {decided.map((activity) => (
                    <div
                      key={activity.id}
                      className={`rounded-lg border px-3 py-2 text-xs text-gray-300 ${
                        selected?.activityId === activity.id
                          ? 'border-orange-500 bg-orange-950/30'
                          : 'border-gray-700 bg-gray-900/40'
                      }`}
                    >
                      <p className="text-sm text-white truncate">{activity.id}</p>
                      <p className="mt-1">uid {activity.userId || '-'}</p>
                      <p>
                        jenaDecision {activity.jenaDecision || '-'} · validationFinalized{' '}
                        {activity.validationFinalized ? 'true' : 'false'} · verified{' '}
                        {activity.jenaVerified ? 'true' : 'false'}
                      </p>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>
        </section>
      </div>
    </div>
  );
}

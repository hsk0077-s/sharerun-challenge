import { useEffect, useState } from 'react';
import { ShieldAlert } from 'lucide-react';
import { ensureAdminAuth } from '../../lib/adminAuth';
import {
  decideReferralReview,
  fetchReferralReviews,
  type ReferralReview,
  type ReferralReviewDecision,
  type ReferralReviewStatus,
} from '../../lib/jenaApi';

const TABS: { status: ReferralReviewStatus; label: string }[] = [
  { status: 'pending', label: '보류 중' },
  { status: 'rejected', label: '지급 안 함' },
  { status: 'released', label: '지급 완료' },
];

const DETAIL_LABELS: Record<string, string> = {
  straight_slide: '직선 경로를 옆으로 민 복사',
  late_signature_change: '늦게 서명을 바꾼 같은 폰',
  copy_review: '복사 의심',
};

const PAYOUT_LABELS: Record<string, string> = {
  trial_referee: '초대받은 사람 보상',
  trial_referrer: '초대한 사람 보상',
  redeem: '코드 입력 보상',
};

function formatWhen(iso: string | null): string {
  if (!iso) return '-';
  const date = new Date(iso);
  return Number.isNaN(date.getTime()) ? '-' : date.toLocaleString('ko-KR');
}

function errorText(err: unknown): string {
  if (err instanceof Error && err.message === 'forbidden') return '권한 없음';
  if (err instanceof Error && err.message === 'conflict') {
    return '이미 처리된 건입니다. 목록을 새로 불러왔습니다.';
  }
  return 'Jena에 연결하지 못했습니다.';
}

const ACTIONS: Record<
  ReferralReviewStatus,
  { decision: ReferralReviewDecision; label: string; style: string; confirm?: string }[]
> = {
  pending: [
    {
      decision: 'reject',
      label: '지급 안 함',
      style: 'bg-gray-800 border-gray-600 text-gray-300',
      confirm: '이 보상을 지급하지 않습니다. 계속할까요?',
    },
    {
      decision: 'release',
      label: '지금 지급',
      style: 'bg-emerald-900/60 border-emerald-700 text-emerald-200',
      confirm: '지급일 전이어도 지금 SHARE를 지급합니다. 되돌릴 수 없습니다. 계속할까요?',
    },
  ],
  rejected: [
    {
      decision: 'reopen',
      label: '다시 보류로',
      style: 'bg-sky-900/60 border-sky-700 text-sky-200',
    },
  ],
  released: [],
};

type Loaded = { tab: ReferralReviewStatus; rows: ReferralReview[]; error: string | null };

export default function ReferralReviews() {
  const [tab, setTab] = useState<ReferralReviewStatus>('pending');
  const [reloadKey, setReloadKey] = useState(0);
  const [loaded, setLoaded] = useState<Loaded | null>(null);
  const [actionError, setActionError] = useState<string | null>(null);
  const [notes, setNotes] = useState<Record<string, string>>({});
  const [busyId, setBusyId] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;
    void (async () => {
      let rows: ReferralReview[] = [];
      let error: string | null = null;
      try {
        const user = await ensureAdminAuth();
        if (!user) error = '로그인 필요';
        else rows = await fetchReferralReviews(await user.getIdToken(), tab);
      } catch (err) {
        error = errorText(err);
      }
      if (!cancelled) setLoaded({ tab, rows, error });
    })();
    return () => {
      cancelled = true;
    };
  }, [tab, reloadKey]);

  // 탭을 바꾼 직후에는 이전 탭의 목록을 보여 주지 않는다.
  const rows = loaded && loaded.tab === tab ? loaded.rows : null;
  const error = actionError ?? (loaded && loaded.tab === tab ? loaded.error : null);

  const decide = async (
    review: ReferralReview,
    decision: ReferralReviewDecision,
    confirmText?: string
  ) => {
    if (busyId) return;
    if (confirmText && !window.confirm(confirmText)) return;
    setBusyId(review.id);
    setActionError(null);
    try {
      const user = await ensureAdminAuth();
      if (!user) throw new Error('forbidden');
      await decideReferralReview(
        await user.getIdToken(),
        review.id,
        decision,
        (notes[review.id] ?? '').trim()
      );
    } catch (err) {
      setActionError(errorText(err));
    } finally {
      setBusyId(null);
      setReloadKey((key) => key + 1);
    }
  };

  return (
    <div className="p-6 text-white h-full overflow-y-auto space-y-4">
      <div>
        <h2 className="text-2xl font-bold tracking-tight flex items-center gap-2">
          <ShieldAlert size={22} className="text-emerald-400" />
          추천 보류
        </h2>
        <p className="text-sm text-gray-400 mt-1">
          복사가 의심되어 7일 동안 보류한 추천 SHARE입니다. 아무것도 하지 않으면 지급일에 자동으로
          지급됩니다. 지급하지 않으려면 "지급 안 함"을 누르세요. 모든 처리는 감사 로그에 남습니다.
        </p>
        {error && <p className="text-xs text-amber-400 mt-1">{error}</p>}
      </div>

      <div className="flex gap-2">
        {TABS.map((item) => (
          <button
            key={item.status}
            type="button"
            onClick={() => {
              setActionError(null);
              setTab(item.status);
            }}
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
          <p className="text-center text-gray-500 text-sm py-8">해당하는 건이 없습니다.</p>
        ) : (
          rows.map((review) => (
            <div
              key={review.id}
              className="rounded-xl p-4 bg-gray-800 border border-gray-700 space-y-2"
            >
              <div className="flex flex-wrap items-baseline justify-between gap-2">
                <p className="font-semibold text-white">
                  {review.amount.toLocaleString()} SHARE
                  <span className="ml-2 text-xs font-normal text-gray-400">
                    {PAYOUT_LABELS[review.payoutType ?? ''] ?? review.payoutType ?? '-'}
                  </span>
                </p>
                <span className="text-xs text-gray-500">
                  지급일 {formatWhen(review.releaseAt)}
                </span>
              </div>
              <p className="text-sm text-gray-200">
                사유: {DETAIL_LABELS[review.detail ?? ''] ?? review.detail ?? DETAIL_LABELS[review.reason ?? ''] ?? '-'}
              </p>
              <p className="text-xs text-gray-500 break-all">
                받는 사람 {review.payeeUid ?? '-'} · 상대 {review.refereeUid ?? '-'} · 접수{' '}
                {formatWhen(review.createdAt)}
              </p>
              {review.reviewNote ? (
                <p className="text-xs text-gray-400">
                  메모: {review.reviewNote} ({review.reviewedBy ?? '-'})
                </p>
              ) : null}
              {ACTIONS[tab].length > 0 && (
                <div className="flex flex-wrap items-center gap-2 pt-1">
                  <input
                    value={notes[review.id] ?? ''}
                    onChange={(event) =>
                      setNotes((current) => ({ ...current, [review.id]: event.target.value }))
                    }
                    maxLength={300}
                    placeholder="처리 메모 (선택)"
                    className="flex-1 min-w-48 bg-gray-900 border border-gray-700 rounded-lg px-3 py-1.5 text-sm text-white"
                  />
                  {ACTIONS[tab].map((action) => (
                    <button
                      key={action.decision}
                      type="button"
                      disabled={busyId !== null}
                      onClick={() => void decide(review, action.decision, action.confirm)}
                      className={`px-3 py-1.5 rounded-lg border text-sm disabled:opacity-50 ${action.style}`}
                    >
                      {action.label}
                    </button>
                  ))}
                </div>
              )}
            </div>
          ))
        )}
      </div>
    </div>
  );
}

import {
  collection,
  doc,
  getDoc,
  limit,
  onSnapshot,
  orderBy,
  query,
  where,
  type Unsubscribe,
} from 'firebase/firestore';
import { ensureAdminAuth } from './adminAuth';
import { getDb } from './firebase';

function toIso(value: unknown): string {
  if (value == null) return '';
  if (typeof value === 'string') return value;
  if (typeof value === 'object' && value !== null && 'toDate' in value) {
    try {
      return (value as { toDate: () => Date }).toDate().toISOString();
    } catch {
      return '';
    }
  }
  return '';
}

function num(v: unknown, fallback = 0): number {
  if (typeof v === 'number' && Number.isFinite(v)) return v;
  if (typeof v === 'string') {
    const n = Number(v);
    if (Number.isFinite(n)) return n;
  }
  return fallback;
}

export type AdminTournament = {
  id: string;
  title: string;
  targetDistanceKm: number;
  participantCount: number;
  maxParticipants: number;
  minParticipantsBep: number;
  status: string;
  sponsorName: string;
  sponsorPrizeSupportShare: number;
  sponsorDonationSupportShare: number;
  requiredTier: number;
  entryFeeShare: number;
  winnerRewardValue: number;
  sponsorBillboardMessages: string[];
};

export type AdminActivity = {
  id: string;
  userId: string;
  distanceKm: number;
  durationSeconds: number | null;
  averagePaceSecondsPerKm: number | null;
  jenaVerified: boolean;
  jenaDecision: string | null;
  jenaReason: string | null;
  validationFinalized: boolean;
  updatedAt: string;
  completedAt: string;
};

export type AdminAppeal = {
  id: string;
  userId: string;
  userNickname: string;
  activityId: string;
  reasonDetail: string;
  status: string;
  createdAt: string;
};

export type AdminPaymentIntent = {
  id: string;
  uid: string;
  type: string;
  status: string;
  amountKrw: number;
  amountShare: number;
  sponsorId: string | null;
  tournamentId: string | null;
  option: string | null;
  createdAt: string;
};

export type AdminWalletTx = {
  id: string;
  uid: string;
  type: string;
  shareAmount: number;
  valueAmount: number;
  diamondAmount: number;
  tournamentId: string | null;
  createdAt: string;
};

type Handlers<T> = {
  onData: (rows: T[]) => void;
  onError?: (error: Error) => void;
};

function subscribeCollection<T>(
  buildQuery: () => ReturnType<typeof query>,
  mapDoc: (id: string, data: Record<string, unknown>) => T,
  handlers: Handlers<T>
): Unsubscribe {
  let inner: Unsubscribe | null = null;
  let cancelled = false;

  void (async () => {
    await ensureAdminAuth();
    if (cancelled) return;
    inner = onSnapshot(
      buildQuery(),
      (snap) => {
        handlers.onData(
          snap.docs.map((d) => mapDoc(d.id, d.data() as Record<string, unknown>))
        );
      },
      (err) => handlers.onError?.(err)
    );
  })();

  return () => {
    cancelled = true;
    inner?.();
  };
}

export function subscribeTournaments(
  handlers: Handlers<AdminTournament>
): Unsubscribe {
  return subscribeCollection(
    () => query(collection(getDb(), 'tournaments'), limit(40)),
    (id, data) => ({
      id,
      title: (data.title as string) || 'SRC Tournament',
      targetDistanceKm: num(data.targetDistanceKm, 3),
      participantCount: Math.trunc(num(data.participantCount)),
      maxParticipants: Math.trunc(num(data.maxParticipants)),
      minParticipantsBep: Math.trunc(num(data.minParticipantsBep)),
      status: (data.status as string) || 'recruiting',
      sponsorName: typeof data.sponsorName === 'string' ? data.sponsorName.trim() : '',
      sponsorPrizeSupportShare: Math.trunc(num(data.sponsorPrizeSupportShare)),
      sponsorDonationSupportShare: Math.trunc(num(data.sponsorDonationSupportShare)),
      requiredTier: Math.trunc(num(data.requiredTier, 1)),
      entryFeeShare: Math.trunc(num(data.entryFeeShare)),
      winnerRewardValue: Math.trunc(num(data.winnerRewardValue)),
      sponsorBillboardMessages: Array.isArray(data.sponsorBillboardMessages)
        ? data.sponsorBillboardMessages.map(String)
        : [],
    }),
    handlers
  );
}

export function subscribeActivities(
  handlers: Handlers<AdminActivity>,
  opts?: { userId?: string; limitCount?: number }
): Unsubscribe {
  const lim = opts?.limitCount ?? 40;
  return subscribeCollection(
    () => {
      const col = collection(getDb(), 'activities');
      if (opts?.userId) {
        return query(
          col,
          where('userId', '==', opts.userId),
          orderBy('updatedAt', 'desc'),
          limit(lim)
        );
      }
      return query(col, orderBy('updatedAt', 'desc'), limit(lim));
    },
    (id, data) => ({
      id,
      userId: (data.userId as string) || '',
      distanceKm: num(data.distanceKm),
      durationSeconds:
        data.durationSeconds == null ? null : Math.trunc(num(data.durationSeconds)),
      averagePaceSecondsPerKm:
        data.averagePaceSecondsPerKm == null
          ? null
          : num(data.averagePaceSecondsPerKm),
      jenaVerified: Boolean(data.jenaVerified ?? data.Jena_Verified),
      jenaDecision: typeof data.jenaDecision === 'string' && data.jenaDecision.trim()
        ? data.jenaDecision.trim()
        : null,
      jenaReason: typeof data.jenaReason === 'string' && data.jenaReason.trim()
        ? data.jenaReason.trim()
        : null,
      validationFinalized: data.validationFinalized === true,
      updatedAt: toIso(data.updatedAt),
      completedAt: toIso(data.completedAt),
    }),
    handlers
  );
}

export function subscribePaymentIntents(
  handlers: Handlers<AdminPaymentIntent>
): Unsubscribe {
  return subscribeCollection(
    () =>
      query(
        collection(getDb(), 'paymentIntents'),
        orderBy('createdAt', 'desc'),
        limit(40)
      ),
    (id, data) => ({
      id,
      uid: (data.uid as string) || '',
      type: (data.type as string) || 'unknown',
      status: (data.status as string) || 'created',
      amountKrw: Math.trunc(num(data.amountKrw)),
      amountShare: Math.trunc(num(data.amountShare)),
      sponsorId: (data.sponsorId as string) || null,
      tournamentId: (data.tournamentId as string) || null,
      option: (data.option as string) || null,
      createdAt: toIso(data.createdAt),
    }),
    handlers
  );
}

export function subscribeWalletTransactions(
  handlers: Handlers<AdminWalletTx>
): Unsubscribe {
  return subscribeCollection(
    () =>
      query(
        collection(getDb(), 'walletTransactions'),
        orderBy('createdAt', 'desc'),
        limit(40)
      ),
    (id, data) => ({
      id,
      uid: (data.uid as string) || (data.userId as string) || '',
      type: (data.type as string) || 'unknown',
      shareAmount: Math.trunc(num(data.shareAmount)),
      valueAmount: Math.trunc(num(data.valueAmount)),
      diamondAmount: Math.trunc(num(data.diamondAmount)),
      tournamentId: (data.tournamentId as string) || null,
      createdAt: toIso(data.createdAt),
    }),
    handlers
  );
}

function readText(value: unknown): string {
  return typeof value === 'string' ? value.trim() : '';
}

const PENDING_APPEAL_STATUSES = ['under_review', 'pending'];

function mapAppeal(id: string, data: Record<string, unknown>): AdminAppeal {
  return {
    id,
    userId: readText(data.userId),
    userNickname: readText(data.userNickname),
    activityId: readText(data.activityId),
    reasonDetail: readText(data.reasonDetail),
    status: readText(data.status),
    createdAt: toIso(data.createdAt),
  };
}

/**
 * 대기 중인 소명(under_review, pending)은 항상 따로 구독하고, 최근 기록 80건과 합친다.
 * 완료된 과거 소명이 limit을 채워도 대기 건이 밀려나지 않는다.
 */
export function subscribeAppeals(
  handlers: Handlers<AdminAppeal>,
  opts?: { limitCount?: number }
): Unsubscribe {
  const lim = opts?.limitCount ?? 80;
  let pending: AdminAppeal[] = [];
  let recent: AdminAppeal[] = [];
  const emit = () => {
    const byId = new Map<string, AdminAppeal>();
    for (const row of [...recent, ...pending]) byId.set(row.id, row);
    handlers.onData([...byId.values()]);
  };
  const unsubPending = subscribeCollection(
    () =>
      query(collection(getDb(), 'appeals'), where('status', 'in', PENDING_APPEAL_STATUSES), limit(200)),
    mapAppeal,
    {
      onData: (rows) => {
        pending = rows;
        emit();
      },
      onError: handlers.onError,
    }
  );
  const unsubRecent = subscribeCollection(
    () => query(collection(getDb(), 'appeals'), limit(lim)),
    mapAppeal,
    {
      onData: (rows) => {
        recent = rows;
        emit();
      },
      onError: handlers.onError,
    }
  );
  return () => {
    unsubPending();
    unsubRecent();
  };
}

export type AdminPlayPurchase = {
  id: string;
  uid: string;
  productId: string;
  priceKrw: number;
  diamondAmount: number;
  orderId: string | null;
  refundStatus: string | null;
  createdAt: string;
};

/** Google Play 인앱 결제 영수증(`playPurchases`). 서버가 지급을 확정한 뒤에만 생긴다. */
export function subscribePlayPurchases(
  handlers: Handlers<AdminPlayPurchase>
): Unsubscribe {
  return subscribeCollection(
    () =>
      query(collection(getDb(), 'playPurchases'), orderBy('createdAt', 'desc'), limit(40)),
    (id, data) => ({
      id,
      uid: readText(data.uid),
      productId: readText(data.productId),
      priceKrw: Math.trunc(num(data.priceKrw)),
      diamondAmount: Math.trunc(num(data.diamondAmount)),
      orderId: readText(data.orderId) || null,
      refundStatus: readText(data.refundStatus) || null,
      createdAt: toIso(data.createdAt),
    }),
    handlers
  );
}

export type AdminAuditLog = {
  id: string;
  uid: string;
  email: string;
  action: string;
  targetUid: string;
  reason: string;
  createdAt: string;
};

export function subscribeAuditLogs(handlers: Handlers<AdminAuditLog>): Unsubscribe {
  return subscribeCollection(
    () =>
      query(collection(getDb(), 'adminAuditLogs'), orderBy('createdAt', 'desc'), limit(100)),
    (id, data) => ({
      id,
      uid: readText(data.uid),
      email: readText(data.email),
      action: readText(data.action),
      targetUid: readText(data.targetUid),
      reason: readText(data.reason),
      createdAt: toIso(data.createdAt),
    }),
    handlers
  );
}

/** 현재 KST 연-월 (`YYYY-MM`). `donationMonthTotals`의 문서 ID. */
export function currentKstMonth(now: Date = new Date()): string {
  return new Date(now.getTime() + 9 * 60 * 60 * 1000).toISOString().slice(0, 7);
}

export type DonationMonth = { month: string; totalWon: number };

export function subscribeDonationMonth(
  month: string,
  onData: (value: DonationMonth) => void,
  onError?: (error: Error) => void
): Unsubscribe {
  let inner: Unsubscribe | null = null;
  let cancelled = false;
  void (async () => {
    await ensureAdminAuth();
    if (cancelled) return;
    inner = onSnapshot(
      doc(getDb(), 'donationMonthTotals', month),
      (snap) => {
        const data = snap.exists() ? (snap.data() as Record<string, unknown>) : {};
        onData({ month, totalWon: Math.max(0, Math.trunc(num(data.totalWon))) });
      },
      (err) => onError?.(err)
    );
  })();
  return () => {
    cancelled = true;
    inner?.();
  };
}

export type AdminRun = {
  id: string;
  userId: string;
  distanceKm: number | null;
  durationSeconds: number | null;
  jenaDecision: string | null;
  jenaReason: string | null;
  validationFinalized: boolean;
  updatedAt: string;
};

function optionalNumber(value: unknown): number | null {
  if (value == null || value === '') return null;
  const n = num(value, Number.NaN);
  return Number.isFinite(n) ? n : null;
}

/** Recent activities. Admin rules already allow this read. Does not write. */
export function subscribeRecentRuns(
  handlers: Handlers<AdminRun>,
  opts?: { limitCount?: number }
): Unsubscribe {
  const lim = opts?.limitCount ?? 40;
  return subscribeCollection(
    () =>
      query(collection(getDb(), 'activities'), orderBy('updatedAt', 'desc'), limit(lim)),
    (id, data) => ({
      id,
      userId: readText(data.userId),
      distanceKm: optionalNumber(data.distanceKm),
      durationSeconds:
        data.durationSeconds == null ? null : Math.trunc(num(data.durationSeconds)),
      jenaDecision: readText(data.jenaDecision) || null,
      jenaReason: readText(data.jenaReason) || null,
      validationFinalized: data.validationFinalized === true,
      updatedAt: toIso(data.updatedAt),
    }),
    handlers
  );
}

/** `users/{uid}.economy.trialRunCount`. Missing user → null. Missing field → 0. */
export async function fetchTrialRunCounts(
  uids: string[]
): Promise<Record<string, number | null>> {
  await ensureAdminAuth();
  const unique = [...new Set(uids.map((uid) => uid.trim()).filter(Boolean))];
  const entries = await Promise.all(
    unique.map(async (uid) => {
      const snap = await getDoc(doc(getDb(), 'users', uid));
      if (!snap.exists()) return [uid, null] as const;
      const economy = snap.data().economy;
      const raw =
        economy && typeof economy === 'object'
          ? (economy as Record<string, unknown>).trialRunCount
          : undefined;
      const count = optionalNumber(raw);
      return [uid, count == null ? 0 : Math.trunc(count)] as const;
    })
  );
  return Object.fromEntries(entries);
}

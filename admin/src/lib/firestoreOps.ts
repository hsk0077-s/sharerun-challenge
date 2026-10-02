import {
  collection,
  doc,
  getDoc,
  limit,
  onSnapshot,
  orderBy,
  query,
  updateDoc,
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
  proofImageUri: string;
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

export function subscribeAppeals(
  handlers: Handlers<AdminAppeal>,
  opts?: { limitCount?: number }
): Unsubscribe {
  const lim = opts?.limitCount ?? 80;
  return subscribeCollection(
    () => query(collection(getDb(), 'appeals'), limit(lim)),
    (id, data) => ({
      id,
      userId: readText(data.userId),
      userNickname: readText(data.userNickname),
      activityId: readText(data.activityId),
      reasonDetail: readText(data.reasonDetail),
      proofImageUri: readText(data.proofImageUri),
      status: readText(data.status),
      createdAt: toIso(data.createdAt),
    }),
    handlers
  );
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

/** Appeals rules allow `isAdmin()` to update. Status only — not wallet or users. */
export async function updateAppealStatus(
  appealId: string,
  status: 'approved' | 'rejected'
): Promise<void> {
  await ensureAdminAuth();
  await updateDoc(doc(getDb(), 'appeals', appealId), { status });
}

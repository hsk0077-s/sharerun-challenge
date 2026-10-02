import {
  collection,
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
  updatedAt: string;
  completedAt: string;
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
      sponsorName: (data.sponsorName as string) || 'SRC Sponsor',
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
      jenaDecision: (data.jenaDecision as string) || null,
      jenaReason: (data.jenaReason as string) || null,
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

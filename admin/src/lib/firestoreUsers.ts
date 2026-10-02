import {
  collection,
  doc,
  onSnapshot,
  updateDoc,
  type Unsubscribe,
} from 'firebase/firestore';
import { getDb, USERS_COLLECTION } from './firebase';
import { ensureAdminAuth } from './adminAuth';
/**
 * 어드민 UI가 이미 기대하는 필드 형태 (기존 axios 응답 호환).
 * Firestore SRC UserModel → 이 형태로 매핑합니다.
 */
export type AdminUser = {
  id: string;
  user_id: string;
  nickname: string;
  value_balance: number;
  status: 'ACTIVE' | 'UNDER_REVIEW' | 'SUSPENDED' | string;
  created_at: string;
  share_balance?: number;
  diamond_balance?: number;
};

function readWalletInt(
  wallet: Record<string, unknown> | undefined,
  keys: string[]
): number {
  if (!wallet) return 0;
  for (const key of keys) {
    const v = wallet[key];
    if (typeof v === 'number' && Number.isFinite(v)) return Math.trunc(v);
    if (typeof v === 'string') {
      const n = Number(v);
      if (Number.isFinite(n)) return Math.trunc(n);
    }
  }
  return 0;
}

function toIso(value: unknown): string {
  if (value == null) return new Date().toISOString();
  if (typeof value === 'string') return value;
  if (typeof value === 'object' && value !== null && 'toDate' in value) {
    try {
      return (value as { toDate: () => Date }).toDate().toISOString();
    } catch {
      /* fall through */
    }
  }
  return new Date().toISOString();
}

/** Firestore `users/{uid}` 문서 → 어드민 테이블 행 */
export function mapFirestoreUser(
  docId: string,
  data: Record<string, unknown>
): AdminUser {
  const walletRaw = data.wallet;
  const wallet =
    walletRaw && typeof walletRaw === 'object'
      ? (walletRaw as Record<string, unknown>)
      : undefined;

  const nickname =
    (typeof data.nickname === 'string' && data.nickname.trim()) ||
    (typeof data.displayName === 'string' && data.displayName.trim()) ||
    'Unknown';

  const statusRaw =
    (typeof data.status === 'string' && data.status) ||
    (typeof data.adminStatus === 'string' && data.adminStatus) ||
    'ACTIVE';

  const status = statusRaw.toUpperCase().replace(/-/g, '_');

  return {
    id: docId,
    user_id: (typeof data.uid === 'string' && data.uid) || docId,
    nickname,
    value_balance: readWalletInt(wallet, [
      'valueTokenBalance',
      'valueToken',
      'value',
      'VALUE',
    ]),
    share_balance: readWalletInt(wallet, ['shareBalance', 'share', 'SHARE']),
    diamond_balance: readWalletInt(wallet, [
      'diamondBalance',
      'diamond',
      'dia',
      'DIA',
    ]),
    status,
    created_at: toIso(data.createdAt ?? data.created_at ?? data.termsAcceptedAt),
  };
}

export type UsersListenerHandlers = {
  onData: (users: AdminUser[]) => void;
  onError?: (error: Error) => void;
};

/**
 * React 쪽 StreamBuilder 대체: `users` 컬렉션 실시간 구독.
 * 구독 전 Admin Auth를 맞춘 뒤 onSnapshot 합니다.
 */
export function subscribeUsers(handlers: UsersListenerHandlers): Unsubscribe {
  let innerUnsub: Unsubscribe | null = null;
  let cancelled = false;

  void (async () => {
    await ensureAdminAuth();
    if (cancelled) return;

    const col = collection(getDb(), USERS_COLLECTION);
    innerUnsub = onSnapshot(
      col,
      (snap) => {
        const users = snap.docs.map((d) =>
          mapFirestoreUser(d.id, d.data() as Record<string, unknown>)
        );
        handlers.onData(users);
      },
      (err) => {
        handlers.onError?.(err);
      }
    );
  })();

  return () => {
    cancelled = true;
    innerUnsub?.();
  };
}

export async function updateUserStatus(
  uid: string,
  status: string
): Promise<void> {
  await ensureAdminAuth();
  await updateDoc(doc(getDb(), USERS_COLLECTION, uid), {
    status,
    adminStatus: status,
    updatedAt: new Date().toISOString(),
  });
}

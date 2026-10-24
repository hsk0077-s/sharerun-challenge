import {
  collection,
  onSnapshot,
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
  /** Firestore `users/{uid}.email`. Empty when the field is absent. */
  email: string;
  value_balance: number;
  status: 'ACTIVE' | 'UNDER_REVIEW' | 'SUSPENDED' | string;
  created_at: string;
  /** `createdAt` only. Null when the field is missing — never "today". */
  joined_at: string | null;
  /** `accountStatus` only. Null when the field is missing. */
  account_status: string | null;
  share_balance?: number;
  diamond_balance?: number;
  /** KR / US / JP / IN / OTHER, or UNKNOWN when no country, countryCode or locale is stored. */
  country: UserCountry;
};

export type UserCountry = 'KR' | 'US' | 'JP' | 'IN' | 'OTHER' | 'UNKNOWN';

const LANGUAGE_REGION: Record<string, string> = { ko: 'KR', ja: 'JP', hi: 'IN' };

/** `countryCode` -> `country` -> `locale` (`ko_KR`, `en-US`, `ja`). */
export function normalizeCountry(data: Record<string, unknown>): UserCountry {
  for (const key of ['countryCode', 'country', 'locale']) {
    const raw = data[key];
    if (typeof raw !== 'string' || !raw.trim()) continue;
    const parts = raw.trim().split(/[-_]/);
    const region =
      parts.length > 1 ? parts[parts.length - 1]!.toUpperCase() : key === 'locale'
        ? (LANGUAGE_REGION[parts[0]!.toLowerCase()] ?? '')
        : parts[0]!.toUpperCase();
    if (!region) continue;
    return region === 'KR' || region === 'US' || region === 'JP' || region === 'IN'
      ? region
      : 'OTHER';
  }
  return 'UNKNOWN';
}

/** 탈퇴(deleted)·정리(purged) 계정은 활성 계정에서 뺀다. */
export function isActiveAccount(user: AdminUser): boolean {
  const state = (user.account_status ?? '').toLowerCase();
  return state !== 'deleted' && state !== 'purged';
}

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

/** `createdAt` for the user table. Missing or unreadable → null, not today. */
function readJoinedAt(value: unknown): string | null {
  if (typeof value === 'string') {
    const trimmed = value.trim();
    return trimmed || null;
  }
  if (value && typeof value === 'object' && 'toDate' in value) {
    try {
      const date = (value as { toDate: () => Date }).toDate();
      if (date instanceof Date && !Number.isNaN(date.getTime())) {
        return date.toISOString();
      }
    } catch {
      return null;
    }
  }
  return null;
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

  const email = typeof data.email === 'string' ? data.email.trim() : '';
  const accountStatusRaw = data.accountStatus;
  const account_status =
    typeof accountStatusRaw === 'string' && accountStatusRaw.trim()
      ? accountStatusRaw.trim()
      : null;

  const statusRaw =
    (typeof data.status === 'string' && data.status) ||
    (typeof data.adminStatus === 'string' && data.adminStatus) ||
    'ACTIVE';

  const status = statusRaw.toUpperCase().replace(/-/g, '_');

  return {
    id: docId,
    user_id: (typeof data.uid === 'string' && data.uid) || docId,
    nickname,
    email,
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
    joined_at: readJoinedAt(data.createdAt),
    account_status,
    country: normalizeCountry(data),
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

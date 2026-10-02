const DEFAULT_JENA_BASE_URL =
  'https://src-jena-ai-1089697395275.asia-northeast3.run.app';

export type JenaWhoAmI = {
  uid: string;
  email: string | null;
  admin: boolean;
};

export function jenaBaseUrl(): string {
  const fromEnv = import.meta.env.VITE_JENA_BASE_URL as string | undefined;
  const base = fromEnv?.trim() || DEFAULT_JENA_BASE_URL;
  return base.replace(/\/$/, '');
}

export type ReferralPayoutMarker = {
  amount: number;
  createdAt: string | null;
  payeeUid: string | null;
};

export type ReferralUserRow = {
  uid: string;
  referralCode: string | null;
  referredBy: string | null;
  referredByUid: string | null;
  trialRunCount: number;
  trialRunsRequired: number;
  referralPayoutCount: number;
  referralPayoutMax: number;
  payouts: {
    redeem: ReferralPayoutMarker | null;
    trial_referee: ReferralPayoutMarker | null;
    trial_referrer: ReferralPayoutMarker | null;
  };
};

export type ReferralList = {
  users: ReferralUserRow[];
  nextCursor: string | null;
  limit: number;
};

async function jenaGet<T>(path: string, idToken: string): Promise<T> {
  const response = await fetch(`${jenaBaseUrl()}${path}`, {
    headers: { Authorization: `Bearer ${idToken}` },
  });
  if (!response.ok) {
    throw new Error(response.status === 401 || response.status === 403 ? 'forbidden' : 'jena');
  }
  return response.json() as Promise<T>;
}

export function fetchWhoAmI(idToken: string): Promise<JenaWhoAmI> {
  return jenaGet<JenaWhoAmI>('/admin/whoami', idToken);
}

export function fetchReferrals(
  idToken: string,
  cursor?: string | null
): Promise<ReferralList> {
  const params = new URLSearchParams();
  if (cursor) params.set('cursor', cursor);
  const query = params.toString();
  return jenaGet<ReferralList>(`/admin/referrals${query ? `?${query}` : ''}`, idToken);
}

export type DailyStepRow = {
  uid: string;
  day: string;
  steps: number;
  source: string | null;
  lastHealth: number | null;
  updatedAt: string | null;
  anomaly: boolean;
};

export type DailyStepsPage = {
  start: string;
  end: string;
  uid: string | null;
  truncated: boolean;
  rows: DailyStepRow[];
};

export function fetchDailySteps(
  idToken: string,
  filter: { uid?: string; from?: string; to?: string }
): Promise<DailyStepsPage> {
  const params = new URLSearchParams();
  if (filter.uid) params.set('uid', filter.uid);
  if (filter.from) params.set('from', filter.from);
  if (filter.to) params.set('to', filter.to);
  const query = params.toString();
  return jenaGet<DailyStepsPage>(
    `/admin/daily-steps${query ? `?${query}` : ''}`,
    idToken
  );
}

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

export async function fetchWhoAmI(idToken: string): Promise<JenaWhoAmI> {
  const response = await fetch(`${jenaBaseUrl()}/admin/whoami`, {
    headers: { Authorization: `Bearer ${idToken}` },
  });
  if (!response.ok) {
    throw new Error(response.status === 401 || response.status === 403 ? 'forbidden' : 'jena');
  }
  return response.json() as Promise<JenaWhoAmI>;
}

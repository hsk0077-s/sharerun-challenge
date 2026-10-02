import {
  getAuth,
  onAuthStateChanged,
  signInWithEmailAndPassword,
  type Auth,
  type User,
} from 'firebase/auth';
import { getFirebaseApp } from './firebase';

let auth: Auth;
let ready: Promise<User | null> | null = null;

function getAdminAuth(): Auth {
  if (!auth) {
    auth = getAuth(getFirebaseApp());
  }
  return auth;
}

/**
 * SRC Admin → Firestore Rules `isAdmin()` 통과용 로그인.
 * VITE_FIREBASE_ADMIN_EMAIL / VITE_FIREBASE_ADMIN_PASSWORD 가 있으면 시 이메일 로그인.
 * Rules 이메일 화이트리스트: admin@share-run-challenge.app, ops@share-run-challenge.app
 * 또는 Custom Claim `admin: true` / `admins/{uid}` 문서.
 */
export function ensureAdminAuth(): Promise<User | null> {
  if (ready) return ready;

  ready = new Promise((resolve) => {
    const a = getAdminAuth();
    const unsub = onAuthStateChanged(a, async (user) => {
      unsub();
      if (user) {
        resolve(user);
        return;
      }

      const email = import.meta.env.VITE_FIREBASE_ADMIN_EMAIL as string | undefined;
      const password = import.meta.env.VITE_FIREBASE_ADMIN_PASSWORD as
        | string
        | undefined;

      if (!email || !password) {
        console.warn(
          '[adminAuth] VITE_FIREBASE_ADMIN_EMAIL/PASSWORD 미설정 — users list는 Rules에서 거부될 수 있습니다.'
        );
        resolve(null);
        return;
      }

      try {
        const cred = await signInWithEmailAndPassword(a, email, password);
        resolve(cred.user);
      } catch (err) {
        console.error('[adminAuth] 로그인 실패:', err);
        resolve(null);
      }
    });
  });

  return ready;
}

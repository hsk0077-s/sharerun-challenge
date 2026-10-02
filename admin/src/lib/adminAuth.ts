import {
  getAuth,
  onAuthStateChanged,
  signInWithEmailAndPassword,
  signOut,
  type Auth,
  type User,
} from 'firebase/auth';
import { getFirebaseApp } from './firebase';

let auth: Auth;

function getAdminAuth(): Auth {
  if (!auth) {
    auth = getAuth(getFirebaseApp());
  }
  return auth;
}

/**
 * 브라우저에 이미 로그인된 세션만 반환합니다.
 * 이메일과 비밀번호는 로그인 화면에서 입력하며, 빌드에 넣지 않습니다.
 */
export function ensureAdminAuth(): Promise<User | null> {
  const a = getAdminAuth();
  if (a.currentUser) return Promise.resolve(a.currentUser);
  return new Promise((resolve) => {
    const unsub = onAuthStateChanged(a, (user) => {
      unsub();
      resolve(user);
    });
  });
}

export function subscribeAuth(onUser: (user: User | null) => void) {
  return onAuthStateChanged(getAdminAuth(), onUser);
}

export function signInAdmin(email: string, secret: string) {
  return signInWithEmailAndPassword(getAdminAuth(), email.trim(), secret);
}

export function signOutAdmin() {
  return signOut(getAdminAuth());
}

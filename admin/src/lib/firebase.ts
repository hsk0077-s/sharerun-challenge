import { initializeApp, getApps, type FirebaseApp } from 'firebase/app';
import { getFirestore, type Firestore } from 'firebase/firestore';

/**
 * SRC 앱(share-run-challenge)과 동일 프로젝트.
 * 클라이언트 API 키는 공개 식별자이며, 접근 통제는 Firestore Rules가 담당합니다.
 * Vite 환경변수가 있으면 우선 사용합니다.
 */
const firebaseConfig = {
  apiKey: import.meta.env.VITE_FIREBASE_API_KEY ?? 'AIzaSyCeK4CUCswGAuy4jclEX8du_RF0CayNmdk',
  authDomain:
    import.meta.env.VITE_FIREBASE_AUTH_DOMAIN ?? 'share-run-challenge.firebaseapp.com',
  projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID ?? 'share-run-challenge',
  storageBucket:
    import.meta.env.VITE_FIREBASE_STORAGE_BUCKET ??
    'share-run-challenge.firebasestorage.app',
  messagingSenderId:
    import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID ?? '1089697395275',
  appId:
    import.meta.env.VITE_FIREBASE_APP_ID ??
    '1:1089697395275:android:07eea1385ca379549b13ce',
};

let app: FirebaseApp;
let db: Firestore;

export function getFirebaseApp(): FirebaseApp {
  if (!app) {
    app = getApps().length > 0 ? getApps()[0]! : initializeApp(firebaseConfig);
  }
  return app;
}

export function getDb(): Firestore {
  if (!db) {
    db = getFirestore(getFirebaseApp());
  }
  return db;
}

/** SRC `FirestorePaths.users` 와 동일 */
export const USERS_COLLECTION = 'users';

import { initializeApp, getApps, type FirebaseApp } from 'firebase/app';
import { getFirestore, type Firestore } from 'firebase/firestore';

/**
 * SRC 앱(share-run-challenge)과 동일 프로젝트.
 * 클라이언트 API 키는 공개 식별자이며, 접근 통제는 Firestore Rules가 담당합니다.
 * Vite 환경변수가 있으면 우선 사용합니다.
 */
// 개발 서버(npm run dev)가 환경변수 없이 실서비스 프로젝트에 붙지 않게 막는다.
// .env.example을 .env로 복사하면 같은 값이 들어가므로, 일부러 붙을 때만 통과한다.
if (import.meta.env.DEV && !import.meta.env.VITE_FIREBASE_PROJECT_ID) {
  throw new Error(
    '개발 모드에서는 admin/.env 가 필요합니다. .env.example 을 .env 로 복사한 뒤 값을 확인하세요. ' +
      '(배포 빌드는 환경변수가 없어도 실서비스 값으로 빌드됩니다.)'
  );
}

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

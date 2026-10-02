import { useEffect, useState, type FormEvent, type ReactNode } from 'react';
import { collection, getDocs, limit, query } from 'firebase/firestore';
import { type User } from 'firebase/auth';
import { signInAdmin, signOutAdmin, subscribeAuth } from '../../lib/adminAuth';
import { getDb, USERS_COLLECTION } from '../../lib/firebase';

type AdminCheck = 'checking' | 'yes' | 'no' | 'error';

function errorCode(err: unknown): string {
  if (err && typeof err === 'object' && 'code' in err) {
    return String((err as { code: unknown }).code);
  }
  return '';
}

function loginMessage(code: string): string {
  if (
    code === 'auth/invalid-credential' ||
    code === 'auth/wrong-password' ||
    code === 'auth/user-not-found' ||
    code === 'auth/invalid-email'
  ) {
    return '이메일 또는 비밀번호가 올바르지 않습니다.';
  }
  return '로그인에 실패했습니다. 잠시 후 다시 시도하세요.';
}

function Frame({ children }: { children: ReactNode }) {
  return (
    <div className="min-h-screen bg-gray-900 text-white flex items-center justify-center p-6">
      <div className="w-full max-w-md bg-gray-800 border border-gray-700 rounded-xl p-6 space-y-4">
        {children}
      </div>
    </div>
  );
}

function LoginScreen() {
  const [email, setEmail] = useState('');
  const [secret, setSecret] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  const onSubmit = async (event: FormEvent) => {
    event.preventDefault();
    setBusy(true);
    setError(null);
    try {
      await signInAdmin(email, secret);
    } catch (err) {
      setError(loginMessage(errorCode(err)));
    } finally {
      setBusy(false);
    }
  };

  return (
    <Frame>
      <div>
        <h1 className="text-xl font-bold">SRC Admin 로그인</h1>
        <p className="text-sm text-gray-400 mt-1">
          Firebase 계정의 이메일과 비밀번호를 입력하세요.
        </p>
      </div>
      <form onSubmit={onSubmit} className="space-y-3">
        <input
          type="email"
          autoComplete="username"
          required
          value={email}
          onChange={(event) => setEmail(event.target.value)}
          placeholder="이메일"
          className="w-full bg-gray-900 border border-gray-700 rounded-lg px-3 py-2 text-sm focus:outline-none focus:border-emerald-500"
        />
        <input
          type="password"
          autoComplete="current-password"
          required
          value={secret}
          onChange={(event) => setSecret(event.target.value)}
          placeholder="비밀번호"
          className="w-full bg-gray-900 border border-gray-700 rounded-lg px-3 py-2 text-sm focus:outline-none focus:border-emerald-500"
        />
        {error && <p className="text-sm text-red-400">{error}</p>}
        <button
          type="submit"
          disabled={busy}
          className="w-full bg-emerald-600 hover:bg-emerald-500 disabled:bg-gray-700 disabled:text-gray-500 rounded-lg py-2 font-semibold"
        >
          {busy ? '확인 중...' : '로그인'}
        </button>
      </form>
    </Frame>
  );
}

function NotAdmin({ email }: { email: string }) {
  return (
    <Frame>
      <h1 className="text-xl font-bold">관리자 계정이 아닙니다</h1>
      <p className="text-sm text-gray-300 leading-relaxed">
        {email} 은 Firestore 규칙 <span className="text-amber-300">isAdmin()</span>에
        해당하지 않습니다. 허용 이메일은 admin@share-run-challenge.app 와
        ops@share-run-challenge.app 입니다. 다른 계정이면 Authentication 커스텀
        클레임 admin=true 또는 admins 문서가 있어야 합니다.
      </p>
      <button
        type="button"
        onClick={() => void signOutAdmin()}
        className="w-full bg-gray-700 hover:bg-gray-600 rounded-lg py-2 font-semibold"
      >
        로그아웃
      </button>
    </Frame>
  );
}

export default function AdminGate({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null | undefined>(undefined);
  const [admin, setAdmin] = useState<AdminCheck>('checking');
  const [attempt, setAttempt] = useState(0);

  useEffect(() => subscribeAuth(setUser), []);

  useEffect(() => {
    if (!user) return;
    let cancelled = false;
    setAdmin('checking');
    void (async () => {
      try {
        await user.getIdToken(true);
        await getDocs(query(collection(getDb(), USERS_COLLECTION), limit(1)));
        if (!cancelled) setAdmin('yes');
      } catch (err) {
        if (cancelled) return;
        setAdmin(errorCode(err) === 'permission-denied' ? 'no' : 'error');
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [user, attempt]);

  if (user === undefined || (user && admin === 'checking')) {
    return (
      <Frame>
        <p className="text-sm text-gray-300">로그인 상태를 확인하는 중...</p>
      </Frame>
    );
  }

  if (!user) return <LoginScreen />;

  if (admin === 'no') return <NotAdmin email={user.email || user.uid} />;

  if (admin !== 'yes') {
    return (
      <Frame>
        <h1 className="text-xl font-bold">권한 확인 실패</h1>
        <p className="text-sm text-gray-300">
          로그인은 됐지만 관리자 권한을 확인하지 못했습니다. 네트워크를 확인한 뒤
          다시 시도하세요.
        </p>
        <button
          type="button"
          onClick={() => setAttempt((n) => n + 1)}
          className="w-full bg-emerald-600 hover:bg-emerald-500 rounded-lg py-2 font-semibold"
        >
          다시 확인
        </button>
        <button
          type="button"
          onClick={() => void signOutAdmin()}
          className="w-full bg-gray-700 hover:bg-gray-600 rounded-lg py-2 font-semibold"
        >
          로그아웃
        </button>
      </Frame>
    );
  }

  return children;
}

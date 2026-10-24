import { useEffect, useMemo, useState } from 'react';
import { Link } from 'react-router-dom';
import { Search, X } from 'lucide-react';
import { useFirestoreUsers } from '../../hooks/useFirestoreUsers';
import type { AdminUser, UserCountry } from '../../lib/firestoreUsers';
import { ensureAdminAuth } from '../../lib/adminAuth';
import { fetchUserDetail, type AdminUserDetail } from '../../lib/jenaApi';

type CountryFilter = 'ALL' | UserCountry;

const COUNTRY_TABS: { value: CountryFilter; label: string }[] = [
  { value: 'ALL', label: '전체' },
  { value: 'KR', label: 'KR' },
  { value: 'US', label: 'US' },
  { value: 'JP', label: 'JP' },
  { value: 'IN', label: 'IN' },
  { value: 'OTHER', label: '기타' },
  { value: 'UNKNOWN', label: '미지정' },
];

const PROVIDER_LABELS: Record<string, string> = {
  google: '구글',
  kakao: '카카오',
  naver: '네이버',
};

function countryLabel(country: UserCountry): string {
  if (country === 'OTHER') return '기타';
  if (country === 'UNKNOWN') return '미지정';
  return country;
}

function accountStateLabel(accountStatus: string | null): string {
  if (!accountStatus) return '-';
  const normalized = accountStatus.toLowerCase();
  if (normalized === 'deleted') return '탈퇴';
  if (normalized === 'purged') return '정리됨';
  return accountStatus;
}

function formatJoinDate(joinedAt: string | null): string {
  if (!joinedAt) return '-';
  const date = new Date(joinedAt);
  if (Number.isNaN(date.getTime())) return '-';
  return date.toLocaleDateString();
}

function matchesUserQuery(user: AdminUser, query: string): boolean {
  const needle = query.trim().toLowerCase();
  if (!needle) return true;
  return [user.nickname, user.user_id, user.id, user.email].some((value) =>
    value.toLowerCase().includes(needle)
  );
}

function UserDetailPanel({ user, onClose }: { user: AdminUser; onClose: () => void }) {
  const [detail, setDetail] = useState<AdminUserDetail | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;
    setDetail(null);
    setError(null);
    void (async () => {
      try {
        const admin = await ensureAdminAuth();
        if (!admin) throw new Error('login');
        const next = await fetchUserDetail(await admin.getIdToken(), user.id);
        if (!cancelled) setDetail(next);
      } catch (err) {
        if (cancelled) return;
        const message = err instanceof Error ? err.message : '';
        setError(
          message === 'forbidden'
            ? '권한 없음'
            : message === 'missing'
              ? '사용자를 찾지 못했습니다.'
              : message === 'login'
                ? '로그인 필요'
                : 'Jena에 연결하지 못했습니다.'
        );
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [user.id]);

  const uid = encodeURIComponent(user.id);

  return (
    <div className="fixed inset-0 z-40 flex justify-end bg-black/50" onClick={onClose}>
      <aside
        className="w-full max-w-md h-full bg-gray-800 border-l border-gray-700 p-6 overflow-y-auto space-y-5"
        onClick={(event) => event.stopPropagation()}
      >
        <div className="flex items-start justify-between gap-3">
          <div className="min-w-0">
            <h3 className="text-lg font-bold text-white truncate">{user.nickname}</h3>
            <p className="text-xs text-gray-400 break-all">{user.id}</p>
            {user.email ? <p className="text-xs text-gray-500 break-all">{user.email}</p> : null}
          </div>
          <button
            type="button"
            onClick={onClose}
            aria-label="닫기"
            className="p-1 rounded-lg text-gray-400 hover:bg-gray-700"
          >
            <X size={18} />
          </button>
        </div>

        {error ? <p className="text-sm text-amber-400">{error}</p> : null}
        {!detail && !error ? <p className="text-sm text-gray-500">불러오는 중...</p> : null}

        {detail ? (
          <dl className="space-y-4 text-sm">
            <div>
              <dt className="text-xs text-gray-400 mb-1">국가</dt>
              <dd className="text-white">{detail.country ?? '미지정'}</dd>
            </div>
            <div>
              <dt className="text-xs text-gray-400 mb-1">연결된 소셜 로그인</dt>
              <dd className="flex flex-wrap gap-2">
                {detail.providers.length === 0 ? (
                  <span className="text-gray-500">없음</span>
                ) : (
                  detail.providers.map((provider) => (
                    <span
                      key={provider}
                      className="px-2 py-0.5 rounded-full bg-gray-900 border border-gray-600 text-gray-200"
                    >
                      {PROVIDER_LABELS[provider] ?? provider}
                    </span>
                  ))
                )}
              </dd>
            </div>
            <div>
              <dt className="text-xs text-gray-400 mb-1">재가입 보상 차단</dt>
              <dd>
                {detail.rewardBlocked ? (
                  <span className="text-amber-400">
                    차단됨{detail.rewardBlockReason ? ` · ${detail.rewardBlockReason}` : ''}
                    {detail.rewardBlockedAt
                      ? ` · ${new Date(detail.rewardBlockedAt).toLocaleDateString()}`
                      : ''}
                  </span>
                ) : (
                  <span className="text-gray-300">차단 없음</span>
                )}
              </dd>
            </div>
            <div>
              <dt className="text-xs text-gray-400 mb-1">소속 크루</dt>
              <dd className="text-white">
                {detail.crew ? `${detail.crew.name ?? '(이름 없음)'} · ${detail.crew.id}` : '없음'}
              </dd>
            </div>
          </dl>
        ) : null}

        <div className="flex flex-wrap gap-2 pt-2">
          <Link
            to={`/wallet-ledger?uid=${uid}`}
            className="px-3 py-2 rounded-lg bg-gray-900 border border-gray-700 text-sm text-emerald-300"
          >
            지갑 원장
          </Link>
          <Link
            to={`/steps?uid=${uid}`}
            className="px-3 py-2 rounded-lg bg-gray-900 border border-gray-700 text-sm text-emerald-300"
          >
            일별 걸음
          </Link>
        </div>
      </aside>
    </div>
  );
}

export default function UserManagement() {
  const { users, loading, error } = useFirestoreUsers();
  const [query, setQuery] = useState('');
  const [country, setCountry] = useState<CountryFilter>('ALL');
  const [selected, setSelected] = useState<AdminUser | null>(null);

  const visibleUsers = useMemo(
    () =>
      users.filter(
        (user) =>
          (country === 'ALL' || user.country === country) && matchesUserQuery(user, query)
      ),
    [users, query, country]
  );

  const countryCounts = useMemo(() => {
    const counts: Record<string, number> = { ALL: users.length };
    for (const user of users) counts[user.country] = (counts[user.country] ?? 0) + 1;
    return counts;
  }, [users]);

  return (
    <div className="p-6 text-white h-full overflow-y-auto space-y-6 pb-32">
      <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
        <div>
          <h2 className="text-2xl font-bold tracking-tight">유저/크루 관리</h2>
          <p className="text-sm text-gray-400 mt-1">
            플랫폼 유저의 지갑 잔액과 계정 상태를 조회합니다. 행을 누르면 CS 상세가 열립니다.
          </p>
          {error && (
            <p className="text-xs text-amber-400 mt-1">Firestore: {error}</p>
          )}
        </div>
      </div>

      <div className="bg-gray-800 p-4 rounded-xl border border-gray-700 space-y-3">
        <div className="relative">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" size={18} />
          <input
            type="text"
            value={query}
            onChange={(event) => setQuery(event.target.value)}
            placeholder="닉네임, UID, 이메일 검색"
            className="w-full bg-gray-900 border border-gray-700 text-white pl-10 pr-4 py-2 rounded-lg focus:outline-none focus:border-emerald-500 transition-colors"
          />
        </div>
        <div className="flex flex-wrap gap-2">
          {COUNTRY_TABS.map((tab) => (
            <button
              key={tab.value}
              type="button"
              onClick={() => setCountry(tab.value)}
              className={`px-3 py-1 rounded-lg border text-xs ${
                country === tab.value
                  ? 'bg-gray-900 border-emerald-600 text-emerald-400 font-bold'
                  : 'bg-gray-800 border-gray-700 text-gray-400'
              }`}
            >
              {tab.label} {(countryCounts[tab.value] ?? 0).toLocaleString()}
            </button>
          ))}
        </div>
      </div>

      <div className="bg-gray-800 rounded-xl border border-gray-700 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm text-gray-300">
            <thead className="text-xs uppercase bg-gray-900/60 text-gray-400 border-b border-gray-700">
              <tr>
                <th className="py-4 px-4">유저 정보</th>
                <th className="py-4 px-4">국가</th>
                <th className="py-4 px-4">SHARE</th>
                <th className="py-4 px-4">다이아</th>
                <th className="py-4 px-4">VALUE</th>
                <th className="py-4 px-4">상태</th>
                <th className="py-4 px-4">가입일</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-700/50">
              {loading ? (
                <tr>
                  <td colSpan={7} className="py-8 text-center text-gray-400">
                    데이터를 불러오는 중...
                  </td>
                </tr>
              ) : users.length === 0 ? (
                <tr>
                  <td colSpan={7} className="py-8 text-center text-gray-400">
                    등록된 유저가 없습니다.
                  </td>
                </tr>
              ) : visibleUsers.length === 0 ? (
                <tr>
                  <td colSpan={7} className="py-8 text-center text-gray-400">
                    검색 결과가 없습니다.
                  </td>
                </tr>
              ) : (
                visibleUsers.map((user) => (
                  <tr
                    key={user.id}
                    onClick={() => setSelected(user)}
                    className="hover:bg-gray-700/30 transition-colors cursor-pointer"
                  >
                    <td className="py-3 px-4">
                      <div className="font-medium text-white">{user.nickname}</div>
                      <div className="text-xs text-gray-400 mt-0.5">{user.user_id}</div>
                      {user.email ? (
                        <div className="text-xs text-gray-500 mt-0.5">{user.email}</div>
                      ) : null}
                    </td>
                    <td className="py-3 px-4">
                      <span className="px-2 py-0.5 rounded-full text-xs bg-gray-900 border border-gray-600 text-gray-200">
                        {countryLabel(user.country)}
                      </span>
                    </td>
                    <td className="py-3 px-4 font-medium text-white">
                      {(user.share_balance ?? 0).toLocaleString()}
                    </td>
                    <td className="py-3 px-4 font-medium text-sky-300">
                      {(user.diamond_balance ?? 0).toLocaleString()}
                    </td>
                    <td className="py-3 px-4">
                      <span className="font-bold text-emerald-400">
                        {(user.value_balance ?? 0).toLocaleString()}
                      </span>
                    </td>
                    <td className="py-3 px-4 text-gray-300">
                      {accountStateLabel(user.account_status)}
                    </td>
                    <td className="py-3 px-4 text-gray-400">
                      {formatJoinDate(user.joined_at)}
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {selected ? <UserDetailPanel user={selected} onClose={() => setSelected(null)} /> : null}
    </div>
  );
}

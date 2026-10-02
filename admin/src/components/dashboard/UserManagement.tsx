import { useMemo, useState } from 'react';
import { Search } from 'lucide-react';
import { useFirestoreUsers } from '../../hooks/useFirestoreUsers';
import type { AdminUser } from '../../lib/firestoreUsers';

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

export default function UserManagement() {
  const { users, loading, error } = useFirestoreUsers();
  const [query, setQuery] = useState('');

  const visibleUsers = useMemo(
    () => users.filter((user) => matchesUserQuery(user, query)),
    [users, query]
  );

  return (
    <div className="p-6 text-white h-full overflow-y-auto space-y-6 pb-32">
      <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
        <div>
          <h2 className="text-2xl font-bold tracking-tight">유저/크루 관리</h2>
          <p className="text-sm text-gray-400 mt-1">
            플랫폼 유저의 지갑 잔액과 계정 상태를 조회합니다.
          </p>
          {error && (
            <p className="text-xs text-amber-400 mt-1">Firestore: {error}</p>
          )}
        </div>
      </div>

      <div className="bg-gray-800 p-4 rounded-xl border border-gray-700">
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
      </div>

      <div className="bg-gray-800 rounded-xl border border-gray-700 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm text-gray-300">
            <thead className="text-xs uppercase bg-gray-900/60 text-gray-400 border-b border-gray-700">
              <tr>
                <th className="py-4 px-4">유저 정보</th>
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
                  <td colSpan={6} className="py-8 text-center text-gray-400">
                    데이터를 불러오는 중...
                  </td>
                </tr>
              ) : users.length === 0 ? (
                <tr>
                  <td colSpan={6} className="py-8 text-center text-gray-400">
                    등록된 유저가 없습니다.
                  </td>
                </tr>
              ) : visibleUsers.length === 0 ? (
                <tr>
                  <td colSpan={6} className="py-8 text-center text-gray-400">
                    검색 결과가 없습니다.
                  </td>
                </tr>
              ) : (
                visibleUsers.map((user) => (
                  <tr key={user.id} className="hover:bg-gray-700/30 transition-colors">
                    <td className="py-3 px-4">
                      <div className="font-medium text-white">{user.nickname}</div>
                      <div className="text-xs text-gray-400 mt-0.5">{user.user_id}</div>
                      {user.email ? (
                        <div className="text-xs text-gray-500 mt-0.5">{user.email}</div>
                      ) : null}
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
    </div>
  );
}

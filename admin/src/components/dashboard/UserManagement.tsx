import { useState } from 'react';
import { Search, Filter, MoreHorizontal, UserPlus, ShieldAlert, Coins, CheckCircle } from 'lucide-react';
import { useFirestoreUsers } from '../../hooks/useFirestoreUsers';
import { updateUserStatus, updateUserValueBalance } from '../../lib/firestoreUsers';

export default function UserManagement() {
  const { users, loading, error, setUsersLocal } = useFirestoreUsers();
  const [activeMenu, setActiveMenu] = useState<string | null>(null);

  // [절대 실패 없는 통제 로직 1] VALUE 100 지급 — Firestore wallet.valueTokenBalance
  const handleAddValue = async (userId: string, currentValue: number) => {
    const safeValue = typeof currentValue === 'number' ? currentValue : Number(currentValue);
    const newValue = safeValue + 100;
    setUsersLocal((prev) =>
      prev.map((user) => (user.id === userId ? { ...user, value_balance: newValue } : user))
    );
    setActiveMenu(null);
    try {
      await updateUserValueBalance(userId, newValue);
    } catch (err) {
      console.error('VALUE 지급 에러:', err);
    }
  };

  // [절대 실패 없는 통제 로직 2] 유저 상태 변경 — Firestore status/adminStatus
  const handleStatusChange = async (userId: string, newStatus: string) => {
    setUsersLocal((prev) =>
      prev.map((user) => (user.id === userId ? { ...user, status: newStatus } : user))
    );
    setActiveMenu(null);
    try {
      await updateUserStatus(userId, newStatus);
    } catch (err) {
      console.error('상태 변경 에러:', err);
    }
  };

  const getStatusLabel = (status: string) => {
    if (status === 'ACTIVE') return '활성';
    if (status === 'UNDER_REVIEW') return '대기';
    if (status === 'SUSPENDED') return '정지';
    return status;
  };

  return (
    <div className="p-6 text-white h-full overflow-y-auto space-y-6 pb-32" onClick={() => setActiveMenu(null)}>
      
      {/* 상단 헤더 및 액션 버튼 */}
      <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
        <div>
          <h2 className="text-2xl font-bold tracking-tight">유저/크루 관리</h2>
          <p className="text-sm text-gray-400 mt-1">플랫폼 내 전체 유저 및 파트너 크루의 상태를 관리합니다.</p>
          {error && (
            <p className="text-xs text-amber-400 mt-1">Firestore: {error}</p>
          )}
        </div>
        <button className="flex items-center gap-2 bg-emerald-600 hover:bg-emerald-500 text-white px-4 py-2 rounded-lg font-medium transition-colors">
          <UserPlus size={18} />
          <span>신규 크루 등록</span>
        </button>
      </div>

      {/* 검색 및 필터 바 */}
      <div className="bg-gray-800 p-4 rounded-xl border border-gray-700 flex flex-col md:flex-row gap-4">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" size={18} />
          <input 
            type="text" 
            placeholder="이름, ID 검색..." 
            className="w-full bg-gray-900 border border-gray-700 text-white pl-10 pr-4 py-2 rounded-lg focus:outline-none focus:border-emerald-500 transition-colors"
          />
        </div>
        <button className="flex items-center justify-center gap-2 bg-gray-900 border border-gray-700 hover:bg-gray-700 text-white px-4 py-2 rounded-lg transition-colors">
          <Filter size={18} />
          <span>상태 필터</span>
        </button>
      </div>

      {/* 데이터 테이블 */}
      <div className="bg-gray-800 rounded-xl border border-gray-700 overflow-visible">
        <div className="overflow-x-visible">
          <table className="w-full text-left text-sm text-gray-300 relative">
            <thead className="text-xs uppercase bg-gray-900/60 text-gray-400 border-b border-gray-700">
              <tr>
                <th className="py-4 px-4 w-12 text-center">
                  <input type="checkbox" className="rounded bg-gray-900 border-gray-600 text-emerald-500 focus:ring-emerald-500/20" />
                </th>
                <th className="py-4 px-4">유저 정보</th>
                <th className="py-4 px-4">보유 VALUE</th>
                <th className="py-4 px-4">상태</th>
                <th className="py-4 px-4">가입일</th>
                <th className="py-4 px-4 text-center">관리</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-700/50">
              {loading ? (
                <tr><td colSpan={6} className="py-8 text-center text-gray-400">데이터를 불러오는 중...</td></tr>
              ) : users.length === 0 ? (
                <tr><td colSpan={6} className="py-8 text-center text-gray-400">등록된 유저가 없습니다.</td></tr>
              ) : (
                users.map((user) => {
                  const statusLabel = getStatusLabel(user.status);
                  return (
                    <tr key={user.id} className="hover:bg-gray-700/30 transition-colors">
                      <td className="py-3 px-4 text-center">
                        <input type="checkbox" className="rounded bg-gray-900 border-gray-600 text-emerald-500 focus:ring-emerald-500/20" />
                      </td>
                      <td className="py-3 px-4">
                        <div className="font-medium text-white">{user.nickname}</div>
                        <div className="text-xs text-gray-400 mt-0.5">{user.user_id}</div>
                      </td>
                      <td className="py-3 px-4">
                        <span className="font-bold text-emerald-400">
                          {user.value_balance.toLocaleString()} VALUE
                        </span>
                      </td>
                      <td className="py-3 px-4">
                        <span className={`px-2 py-1 rounded text-xs border ${
                          statusLabel === '활성' ? 'text-emerald-400 bg-emerald-950/60 border-emerald-900' : 
                          statusLabel === '정지' ? 'text-red-400 bg-red-950/60 border-red-900' : 
                          'text-amber-400 bg-amber-950/60 border-amber-900'
                        }`}>
                          {statusLabel}
                        </span>
                      </td>
                      <td className="py-3 px-4 text-gray-400">
                        {new Date(user.created_at).toLocaleDateString()}
                      </td>
                      
                      <td className="py-3 px-4 text-center relative">
                        <button 
                          onClick={(e) => {
                            e.stopPropagation();
                            setActiveMenu(activeMenu === user.id ? null : user.id);
                          }}
                          className="p-1.5 text-gray-400 hover:text-white hover:bg-gray-700 rounded transition-colors"
                        >
                          <MoreHorizontal size={18} />
                        </button>

                        {activeMenu === user.id && (
                          <div className="absolute right-10 top-10 w-40 bg-gray-800 border border-gray-600 rounded-lg shadow-xl z-50 overflow-hidden text-sm">
                            <button 
                              onClick={(e) => { e.stopPropagation(); handleAddValue(user.id, user.value_balance); }}
                              className="w-full text-left px-4 py-2 hover:bg-gray-700 flex items-center gap-2 text-emerald-400"
                            >
                              <Coins size={14} /> +100 VALUE
                            </button>
                            <button 
                              onClick={(e) => { e.stopPropagation(); handleStatusChange(user.id, 'ACTIVE'); }}
                              className="w-full text-left px-4 py-2 hover:bg-gray-700 flex items-center gap-2 text-white"
                            >
                              <CheckCircle size={14} /> 정상 복구
                            </button>
                            <button 
                              onClick={(e) => { e.stopPropagation(); handleStatusChange(user.id, 'SUSPENDED'); }}
                              className="w-full text-left px-4 py-2 hover:bg-gray-700 flex items-center gap-2 text-red-400 border-t border-gray-700"
                            >
                              <ShieldAlert size={14} /> 계정 정지
                            </button>
                          </div>
                        )}
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
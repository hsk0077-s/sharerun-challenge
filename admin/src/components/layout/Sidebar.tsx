import { NavLink } from 'react-router-dom';

export default function Sidebar() {
  // 활성화된 메뉴와 비활성화된 메뉴의 색상을 자동으로 바꿔주는 규칙
  const navClass = ({ isActive }: { isActive: boolean }) =>
    `block px-4 py-3 mb-2 rounded-lg transition-colors ${
      isActive ? 'bg-gray-900 text-emerald-400 font-bold' : 'text-gray-400 hover:bg-gray-700 hover:text-white'
    }`;

  return (
    <aside className="w-64 bg-gray-800 border-r border-gray-700 h-full flex flex-col">
      <div className="p-6">
        <h1 className="text-xl font-black text-white tracking-wider">SHARE RUN</h1>
      </div>
      <nav className="flex-1 px-4">
        <NavLink to="/" className={navClass}>통합 대시보드</NavLink>
        <NavLink to="/users" className={navClass}>유저/크루 관리</NavLink>
        <NavLink to="/abuse" className={navClass}>Jena 어뷰징 심사</NavLink>
        <NavLink to="/finance" className={navClass}>재무/환불 관리</NavLink>
        <NavLink to="/sponsor" className={navClass}>B2B 스폰서 룸 승인</NavLink>
        <NavLink to="/referrals" className={navClass}>추천인</NavLink>
        <NavLink to="/steps" className={navClass}>일별 걸음</NavLink>
        <NavLink to="/wallet-anomalies" className={navClass}>지갑 이상</NavLink>
      </nav>
    </aside>
  );
}
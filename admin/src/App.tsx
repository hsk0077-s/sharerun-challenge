import { BrowserRouter, Routes, Route } from 'react-router-dom';
import AdminGate from './components/auth/AdminGate';
import Sidebar from './components/layout/Sidebar';
import Header from './components/layout/Header';
import Overview from './components/dashboard/Overview';
import UserManagement from './components/dashboard/UserManagement';
import AbuseAudit from './components/dashboard/AbuseAudit';
import FinanceManagement from './components/dashboard/FinanceManagement';
import SponsorApproval from './components/dashboard/SponsorApproval';
import Referrals from './components/dashboard/Referrals';
import DailySteps from './components/dashboard/DailySteps';
import WalletAnomalies from './components/dashboard/WalletAnomalies';

export default function App() {
  return (
    <BrowserRouter>
      <AdminGate>
      <div className="flex h-screen bg-gray-900 overflow-hidden">
        {/* 좌측 사이드바 고정 */}
        <Sidebar />

        {/* 우측 콘텐츠 영역 */}
        <div className="flex flex-col flex-1 overflow-hidden">
          <Header />
          
          {/* 주소(URL)에 따라 알맞은 화면을 핀셋 출력 */}
          <main className="flex-1 overflow-x-hidden overflow-y-auto bg-gray-900">
            <Routes>
              <Route path="/" element={<Overview />} />
              <Route path="/users" element={<UserManagement />} />
              <Route path="/abuse" element={<AbuseAudit />} />
              <Route path="/finance" element={<FinanceManagement />} />
              <Route path="/sponsor" element={<SponsorApproval />} />
              <Route path="/referrals" element={<Referrals />} />
              <Route path="/steps" element={<DailySteps />} />
              <Route path="/wallet-anomalies" element={<WalletAnomalies />} />
            </Routes>
          </main>
        </div>
      </div>
      </AdminGate>
    </BrowserRouter>
  );
}
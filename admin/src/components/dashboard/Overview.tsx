import { useState, useEffect } from 'react';
import { ResponsiveContainer, LineChart, Line, XAxis, YAxis, Tooltip, PieChart, Pie, Cell } from 'recharts';
import { Users, AlertTriangle, ShieldAlert, Info } from 'lucide-react';
import { useFirestoreUsers } from '../../hooks/useFirestoreUsers';
import {
  subscribeTournaments,
  type AdminTournament,
} from '../../lib/firestoreOps';

// Card A: 실시간 DAU 라인 (시안 그래픽용 — 차트 축 스케일)
const lineData = [
  { name: '09:00', dau: 42 },
  { name: '12:00', dau: 88 },
  { name: '15:00', dau: 65 },
  { name: '18:00', dau: 120 },
  { name: '21:00', dau: 95 },
  { name: '00:00', dau: 55 },
  { name: '03:00', dau: 28 },
  { name: '06:00', dau: 70 },
  { name: '09:00+', dau: 110 },
  { name: '12:00+', dau: 145 },
];

// Card B: 3-jewel 도넛 (시안 그래픽용)
const shareData = [{ name: 'SHARE', value: 70 }, { name: 'Empty', value: 30 }];
const diamondData = [{ name: 'Diamond', value: 45 }, { name: 'Empty', value: 55 }];
const valueData = [{ name: 'VALUE', value: 85 }, { name: 'Empty', value: 15 }];

const SHARE_COLORS = ['#34D399', '#1F2937'];
const DIAMOND_COLORS = ['#60A5FA', '#1F2937'];
const VALUE_COLORS = ['#A3E635', '#1F2937'];

function tierLabel(tier: number): string {
  if (tier <= 1) return '초급';
  if (tier === 2) return '중급';
  return '상급';
}

export default function Overview() {
  const { users, loading, error } = useFirestoreUsers();
  const [statsReady, setStatsReady] = useState(false);
  const [tournaments, setTournaments] = useState<AdminTournament[]>([]);

  const totalUsers = users.length;
  const totalValue = users.reduce((acc, user) => acc + (user.value_balance || 0), 0);
  const underReviewCount = users.filter((user) => user.status === 'UNDER_REVIEW').length;
  const gcpOnline = !error && !loading;

  useEffect(() => {
    if (!loading) setStatsReady(true);
  }, [loading]);

  useEffect(() => {
    return subscribeTournaments({
      onData: setTournaments,
      onError: (err) => console.error('[Overview tournaments]', err),
    });
  }, []);

  const liveRunners = Math.max(0, Math.min(totalUsers, 200));
  const abuseDetected = underReviewCount;
  const falsePositiveHold = 0;

  const roomMonitor = tournaments.slice(0, 4).map((t) => {
    const max = t.maxParticipants > 0 ? t.maxParticipants : Math.max(t.minParticipantsBep, 1);
    const bepPct =
      t.minParticipantsBep > 0
        ? Math.min(100, Math.round((t.participantCount / t.minParticipantsBep) * 100))
        : 0;
    return {
      name: `${tierLabel(t.requiredTier)} ${t.targetDistanceKm}km · ${t.title}`,
      current: t.participantCount,
      max,
      bep: bepPct,
      status: t.status,
    };
  });


  return (
    <div className="p-6 text-white h-full overflow-y-auto space-y-6">
      {/* 헤더: 시안 — 타이틀 + GCP Stable 뱃지 */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
        <h2 className="text-2xl font-bold tracking-tight">
          System Overview (시스템 관제탑)
        </h2>
        <div className="flex items-center gap-3">
          <span
            className={`inline-flex items-center gap-2 px-3 py-1.5 rounded-full text-xs font-semibold border ${
              !statsReady
                ? 'bg-gray-800 border-gray-600 text-gray-400'
                : gcpOnline
                  ? 'bg-emerald-950/70 border-emerald-800 text-emerald-400'
                  : 'bg-amber-950/70 border-amber-800 text-amber-400'
            }`}
          >
            <span
              className={`w-1.5 h-1.5 rounded-full ${
                !statsReady ? 'bg-gray-500' : gcpOnline ? 'bg-emerald-400 animate-pulse' : 'bg-amber-400'
              }`}
            />
            {!statsReady
              ? 'Firestore: Connecting...'
              : gcpOnline
                ? 'Firestore: Live'
                : 'Firestore: Permission / Offline'}
          </span>
          <span className="text-xs text-gray-500 hidden md:inline">
            등록 {totalUsers.toLocaleString()}명 · VALUE {totalValue.toLocaleString()}
            {error ? ` · ${error}` : ''}
          </span>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Card A: 트랙 관리 */}
        <div className="bg-gray-800 p-6 rounded-xl border border-gray-700 flex flex-col">
          <div className="flex justify-between items-start mb-2">
            <div>
              <h3 className="text-gray-300 text-sm font-semibold">A. 트랙 관리</h3>
              <p className="text-xs text-gray-500 mt-1">
                Real-time Active Users (DAU) · Live Runners:{' '}
                <span className="text-emerald-400 font-bold">{liveRunners}</span>
              </p>
            </div>
            <div className="p-2 bg-emerald-950 text-emerald-400 rounded-lg">
              <Users size={18} />
            </div>
          </div>
          <div className="w-full mt-2 flex-1 min-h-[180px]">
            <ResponsiveContainer width="100%" height={180}>
              <LineChart data={lineData}>
                <XAxis dataKey="name" stroke="#6B7280" fontSize={10} tickLine={false} axisLine={false} />
                <YAxis stroke="#6B7280" fontSize={10} tickLine={false} axisLine={false} domain={[0, 200]} width={32} />
                <Tooltip
                  contentStyle={{ backgroundColor: '#1F2937', borderColor: '#374151', borderRadius: 8 }}
                  labelStyle={{ color: '#9CA3AF' }}
                />
                <Line type="monotone" dataKey="dau" name="DAU" stroke="#6EE7B7" strokeWidth={2.5} dot={false} />
              </LineChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Card B: 3-jewel 토큰 체계 */}
        <div className="bg-gray-800 p-6 rounded-xl border border-gray-700 flex flex-col">
          <h3 className="text-gray-300 text-sm font-semibold mb-4">B. 3-jewel 토큰 체계</h3>
          <div className="grid grid-cols-3 gap-2 text-center my-auto">
            <div className="flex flex-col items-center">
              <div className="relative w-full flex justify-center">
                <ResponsiveContainer width="100%" height={100}>
                  <PieChart>
                    <Pie data={shareData} innerRadius={30} outerRadius={40} paddingAngle={0} dataKey="value" startAngle={90} endAngle={-270}>
                      {shareData.map((_, i) => <Cell key={`share-${i}`} fill={SHARE_COLORS[i]} />)}
                    </Pie>
                  </PieChart>
                </ResponsiveContainer>
                <div className="absolute inset-0 flex items-center justify-center text-xs font-bold text-emerald-400">70%</div>
              </div>
              <span className="text-[11px] font-semibold text-gray-400 mt-1 leading-tight">SHARE 발행량</span>
            </div>
            <div className="flex flex-col items-center">
              <div className="relative w-full flex justify-center">
                <ResponsiveContainer width="100%" height={100}>
                  <PieChart>
                    <Pie data={diamondData} innerRadius={30} outerRadius={40} paddingAngle={0} dataKey="value" startAngle={90} endAngle={-270}>
                      {diamondData.map((_, i) => <Cell key={`dia-${i}`} fill={DIAMOND_COLORS[i]} />)}
                    </Pie>
                  </PieChart>
                </ResponsiveContainer>
                <div className="absolute inset-0 flex items-center justify-center text-xs font-bold text-blue-400">45%</div>
              </div>
              <span className="text-[11px] font-semibold text-gray-400 mt-1 leading-tight">다이아몬드 예치 풀</span>
            </div>
            <div className="flex flex-col items-center">
              <div className="relative w-full flex justify-center">
                <ResponsiveContainer width="100%" height={100}>
                  <PieChart>
                    <Pie data={valueData} innerRadius={30} outerRadius={40} paddingAngle={0} dataKey="value" startAngle={90} endAngle={-270}>
                      {valueData.map((_, i) => <Cell key={`val-${i}`} fill={VALUE_COLORS[i]} />)}
                    </Pie>
                  </PieChart>
                </ResponsiveContainer>
                <div className="absolute inset-0 flex items-center justify-center text-xs font-bold text-lime-400">85%</div>
              </div>
              <span className="text-[11px] font-semibold text-gray-400 mt-1 leading-tight">VALUE 토큰 채굴량</span>
            </div>
          </div>
        </div>

        {/* Card C: 대회 방 모집 모니터링 */}
        <div className="bg-gray-800 p-6 rounded-xl border border-gray-700">
          <h3 className="text-gray-300 text-sm font-semibold mb-4">C. 대회 방 모집 모니터링</h3>
          <div className="space-y-2">
            {roomMonitor.length === 0 ? (
              <p className="text-sm text-gray-500 py-4 text-center">모집 중인 대회가 없습니다.</p>
            ) : (
              roomMonitor.map((room, idx) => (
              <div
                key={`${room.name}-${idx}`}
                className="flex items-center justify-between gap-3 px-3 py-2.5 rounded-lg bg-gray-900/50 border border-gray-700/80"
              >
                <p className="text-sm text-gray-200 truncate">
                  {room.name} - 모집 인원 {room.current}/{room.max}명 (BEP {room.bep}%)
                </p>
                <span className="shrink-0 text-[11px] font-semibold text-emerald-400 whitespace-nowrap">
                  {room.status === 'recruiting' ? '모집 중' : room.status}
                </span>
              </div>
              ))
            )}
          </div>
        </div>

        {/* Card D: Jena AI 실시간 성황 */}
        <div className="bg-gray-800 p-6 rounded-xl border border-gray-700 space-y-2.5">
          <h3 className="text-gray-300 text-sm font-semibold mb-2">D. Jena AI 실시간 성황</h3>

          <div className="flex items-center gap-3 p-3 rounded-lg bg-amber-950/40 border border-amber-900/50 text-amber-300 text-sm">
            <AlertTriangle size={16} className="shrink-0" />
            <span>어뷰징 적발 {abuseDetected}건</span>
          </div>

          <div className="flex items-center gap-3 p-3 rounded-lg bg-orange-950/35 border border-orange-900/40 text-orange-300 text-sm">
            <Info size={16} className="shrink-0" />
            <span>&apos;기록 보류(False Positive) 대기 {falsePositiveHold}건&apos;</span>
          </div>

          <div className="flex items-center gap-3 p-3 rounded-lg bg-red-950/40 border border-red-900/50 text-red-300 text-sm">
            <ShieldAlert size={16} className="shrink-0" />
            <span>어뷰징 적발 {abuseDetected}건 — 고위험 구간</span>
          </div>

          <div className="flex items-center gap-3 p-3 rounded-lg bg-amber-950/25 border border-amber-900/30 text-amber-200/90 text-sm">
            <AlertTriangle size={16} className="shrink-0" />
            <span>&apos;기록 보류(False Positive) 대기 {falsePositiveHold}건&apos;</span>
          </div>
        </div>
      </div>
    </div>
  );
}
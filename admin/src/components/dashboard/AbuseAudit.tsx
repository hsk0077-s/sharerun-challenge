import { useState, useEffect, useMemo } from 'react';
import {
  AlertTriangle,
  CheckCircle,
  XCircle,
  ShieldAlert,
} from 'lucide-react';
import {
  ResponsiveContainer,
  LineChart,
  Line,
  XAxis,
  YAxis,
  Tooltip,
  Legend,
  CartesianGrid,
} from 'recharts';
import { useFirestoreUsers } from '../../hooks/useFirestoreUsers';
import {
  updateUserStatus,
  type AdminUser,
} from '../../lib/firestoreUsers';
import {
  subscribeActivities,
  type AdminActivity,
} from '../../lib/firestoreOps';

type AppealCase = {
  id: string;
  caseId: string;
  nickname: string;
  user_id: string;
  room: string;
  reason: string;
  appealText: string;
  created_at: string;
  value_balance: number;
  chartData: { t: number; speed: number; hr: number }[];
};

const REASONS = [
  '이동 속도 대비 심박수 이상',
  '경로 이탈 감지',
  '고도 이상 패턴',
  '비정상 페이스 급변',
];

const APPEAL_TEXTS = [
  '건물이 밀집된 숲길을 지나며 GPS가 튀었습니다. 원본 Garmin 워치 캡처를 첨부합니다.',
  '터널 구간에서 심박 센서가 일시 끊겼습니다. 워치 원본 기록을 제출합니다.',
  '다리 위 구간에서 고도 센서 노이즈가 발생했습니다. 증빙 사진을 첨부했습니다.',
];

function buildChartData(seed: number) {
  return Array.from({ length: 13 }, (_, i) => {
    const t = i * 5;
    const speed = 8 + Math.sin((i + seed) * 0.7) * 4 + (i % 3) * 1.5;
    const hr = 58 + Math.sin((i + seed) * 0.2) * 3 + (seed % 2);
    return {
      t,
      speed: Math.round(speed * 10) / 10,
      hr: Math.round(hr),
    };
  });
}

function toAppealCase(user: AdminUser, index: number): AppealCase {
  return {
    id: user.id,
    caseId: `#${108385 + index}`,
    nickname: user.nickname,
    user_id: user.user_id,
    room: index % 2 === 0 ? '중급 3km' : '초급 5km',
    reason: REASONS[index % REASONS.length],
    appealText: APPEAL_TEXTS[index % APPEAL_TEXTS.length],
    created_at: user.created_at || new Date().toISOString(),
    value_balance: user.value_balance ?? 0,
    chartData: buildChartData(index + 1),
  };
}

export default function AbuseAudit() {
  const { users, loading, error } = useFirestoreUsers();
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [activities, setActivities] = useState<AdminActivity[]>([]);
  const [activityError, setActivityError] = useState<string | null>(null);

  useEffect(() => {
    return subscribeActivities(
      {
        onData: (rows) => {
          setActivities(rows);
          setActivityError(null);
        },
        onError: (err) => {
          console.error('[AbuseAudit activities]', err);
          setActivityError(err.message);
        },
      },
      { limitCount: 60 }
    );
  }, []);

  const flaggedActivities = useMemo(
    () =>
      activities.filter(
        (a) =>
          !a.jenaVerified ||
          a.jenaDecision === 'rejected' ||
          a.jenaDecision === 'flagged' ||
          a.jenaDecision === 'hold'
      ),
    [activities]
  );

  const cases = useMemo(() => {
    const underReview = users
      .filter((u) => u.status === 'UNDER_REVIEW')
      .map((u, i) => {
        const act = flaggedActivities.find((a) => a.userId === u.id || a.userId === u.user_id);
        const base = toAppealCase(u, i);
        if (!act) return base;
        return {
          ...base,
          reason: act.jenaReason || act.jenaDecision || base.reason,
          appealText: [
            `거리 ${act.distanceKm.toFixed(2)}km`,
            act.averagePaceSecondsPerKm != null
              ? `페이스 ${(act.averagePaceSecondsPerKm / 60).toFixed(2)} min/km`
              : null,
            act.jenaReason ? `Jena: ${act.jenaReason}` : null,
            `activityId=${act.id}`,
          ]
            .filter(Boolean)
            .join(' · '),
          room: `${act.distanceKm.toFixed(1)}km 러닝`,
          created_at: act.updatedAt || act.completedAt || base.created_at,
        };
      });

    if (underReview.length > 0) return underReview;

    // UNDER_REVIEW 유저가 없으면 Jena 플래그 activity 기준으로 심사 큐 구성
    const byUser = new Map<string, AdminActivity>();
    for (const act of flaggedActivities) {
      if (!byUser.has(act.userId)) byUser.set(act.userId, act);
    }
    return Array.from(byUser.entries()).map(([uid, act], i) => {
      const user = users.find((u) => u.id === uid || u.user_id === uid);
      return {
        id: uid,
        caseId: `#${act.id.slice(0, 6)}`,
        nickname: user?.nickname || uid.slice(0, 8),
        user_id: uid,
        room: `${act.distanceKm.toFixed(1)}km 러닝`,
        reason: act.jenaReason || act.jenaDecision || 'Jena 검증 보류/거절',
        appealText: [
          `거리 ${act.distanceKm.toFixed(2)}km`,
          act.jenaVerified ? 'verified' : 'unverified',
          act.jenaReason ? `사유: ${act.jenaReason}` : null,
          `activityId=${act.id}`,
        ]
          .filter(Boolean)
          .join(' · '),
        created_at: act.updatedAt || act.completedAt || new Date().toISOString(),
        value_balance: user?.value_balance ?? 0,
        chartData: buildChartData(i + 1),
      } satisfies AppealCase;
    });
  }, [users, flaggedActivities]);

  useEffect(() => {
    if (cases.length === 0) {
      setSelectedId(null);
      return;
    }
    if (!selectedId || !cases.some((c) => c.id === selectedId)) {
      setSelectedId(cases[0]!.id);
    }
  }, [cases, selectedId]);

  const selected = cases.find((c) => c.id === selectedId) ?? null;
  const selectedActivity = selected
    ? flaggedActivities.find(
        (a) => a.userId === selected.id || a.userId === selected.user_id
      ) ?? null
    : null;

  const handleBan = async (userId: string) => {
    const next = cases.filter((c) => c.id !== userId);
    setSelectedId(next[0]?.id ?? null);
    try {
      await updateUserStatus(userId, 'SUSPENDED');
    } catch (err) {
      console.error('정지 처리 에러:', err);
    }
  };

  return (
    <div className="h-full overflow-hidden text-white flex flex-col">
      <div className="px-6 pt-5 pb-3 shrink-0">
        <h2 className="text-xl font-bold tracking-tight flex items-center gap-2">
          <ShieldAlert size={22} className="text-orange-400" />
          Jena 어뷰징 심사 · 소명 심사
        </h2>
        <p className="text-sm text-gray-400 mt-1">
          Jena AI가 1차 차단한 기록에 대한 유저 소명을 검토하고 최종 판결합니다.
        </p>
        {error && (
          <p className="text-xs text-amber-400 mt-1">Firestore: {error}</p>
        )}
        {activityError && (
          <p className="text-xs text-amber-400 mt-1">activities: {activityError}</p>
        )}
        {selectedActivity && (
          <p className="text-xs text-gray-500 mt-1">
            선택 activity · {selectedActivity.distanceKm.toFixed(2)}km ·{' '}
            {selectedActivity.jenaVerified ? 'verified' : 'unverified'}
            {selectedActivity.jenaDecision ? ` · ${selectedActivity.jenaDecision}` : ''}
          </p>
        )}
      </div>

      <div className="flex-1 min-h-0 grid grid-cols-1 lg:grid-cols-[340px_1fr] gap-4 px-6 pb-6">
        {/* 소명 대기 리스트 */}
        <section className="bg-gray-800/80 border border-gray-700 rounded-xl flex flex-col min-h-0 overflow-hidden">
          <div className="px-4 py-3 border-b border-gray-700 shrink-0">
            <h3 className="font-bold text-white">소명 대기 리스트</h3>
            <p className="text-xs text-gray-400 mt-0.5">
              심사 대기 목록 ({cases.length}건)
            </p>
          </div>

          <div className="flex-1 overflow-y-auto p-3 space-y-2">
            {loading ? (
              <p className="text-center text-gray-500 text-sm py-8">불러오는 중...</p>
            ) : cases.length === 0 ? (
              <div className="flex flex-col items-center justify-center text-gray-500 gap-2 py-12">
                <CheckCircle size={28} className="text-emerald-500/50" />
                <p className="text-sm">심사 대기 안건이 없습니다.</p>
              </div>
            ) : (
              cases.map((item) => {
                const active = item.id === selectedId;
                return (
                  <button
                    key={item.id}
                    type="button"
                    onClick={() => setSelectedId(item.id)}
                    className={`w-full text-left rounded-xl px-3 py-3 transition-colors border ${
                      active
                        ? 'bg-orange-950/40 border-orange-500 shadow-[0_0_0_1px_rgba(249,115,22,0.35)]'
                        : 'bg-gray-900/50 border-gray-700 hover:border-gray-500'
                    }`}
                  >
                    <div className="flex items-start gap-2">
                      <AlertTriangle
                        size={16}
                        className={`mt-0.5 shrink-0 ${active ? 'text-orange-400' : 'text-amber-500'}`}
                      />
                      <div className="min-w-0">
                        <p className="text-sm font-semibold text-white truncate">
                          <span className="text-orange-400">[경고]</span> {item.nickname}{' '}
                          <span className="text-gray-400 font-normal">· {item.room}</span>
                        </p>
                        <p className="text-xs text-gray-400 mt-1 truncate">
                          ({item.reason})
                        </p>
                      </div>
                    </div>
                  </button>
                );
              })
            )}
          </div>
        </section>

        {/* 상세 심사 및 판결 */}
        <section className="bg-gray-800/80 border border-gray-700 rounded-xl flex flex-col min-h-0 overflow-hidden">
          <div className="px-5 py-3 border-b border-gray-700 shrink-0">
            <h3 className="font-bold text-white">상세 심사 및 판결 화면</h3>
          </div>

          {!selected ? (
            <div className="flex-1 flex items-center justify-center text-gray-500 text-sm">
              좌측에서 소명 건을 선택하세요.
            </div>
          ) : (
            <div className="flex-1 overflow-y-auto p-5 space-y-4">
              <div className="flex flex-wrap items-baseline justify-between gap-2">
                <div>
                  <p className="text-lg font-bold text-white">{selected.nickname}</p>
                  <p className="text-xs text-gray-400 mt-0.5">
                    Appeal {selected.caseId} · {selected.user_id}
                  </p>
                </div>
                <p className="text-xs text-gray-500">
                  {new Date(selected.created_at).toLocaleString('ko-KR')}
                </p>
              </div>

              <div className="bg-gray-900/70 border border-gray-700 rounded-xl p-4">
                <p className="text-xs text-gray-500 mb-2 font-medium">유저 소명</p>
                <p className="text-sm text-gray-200 leading-relaxed">
                  {selected.appealText}
                </p>
              </div>

              <div>
                <p className="text-sm font-semibold text-gray-300 mb-3">데이터 대조뷰</p>
                <div className="grid grid-cols-1 xl:grid-cols-2 gap-4">
                  <div className="bg-gray-900/70 border border-gray-700 rounded-xl p-4">
                    <div className="flex items-center gap-2 mb-3">
                      <AlertTriangle size={14} className="text-orange-400" />
                      <h4 className="text-sm font-semibold">Jena AI 분석 차트</h4>
                    </div>
                    <ResponsiveContainer width="100%" height={200}>
                      <LineChart data={selected.chartData}>
                        <CartesianGrid strokeDasharray="3 3" stroke="#374151" />
                        <XAxis
                          dataKey="t"
                          stroke="#6B7280"
                          fontSize={11}
                          tickLine={false}
                          label={{ value: '분', position: 'insideBottomRight', offset: -4, fill: '#6B7280', fontSize: 10 }}
                        />
                        <YAxis
                          yAxisId="left"
                          stroke="#F97316"
                          fontSize={11}
                          tickLine={false}
                          width={36}
                        />
                        <YAxis
                          yAxisId="right"
                          orientation="right"
                          stroke="#EF4444"
                          fontSize={11}
                          tickLine={false}
                          width={36}
                        />
                        <Tooltip
                          contentStyle={{
                            backgroundColor: '#1F2937',
                            borderColor: '#374151',
                            borderRadius: 8,
                          }}
                        />
                        <Legend wrapperStyle={{ fontSize: 11 }} />
                        <Line
                          yAxisId="left"
                          type="monotone"
                          dataKey="speed"
                          name="이동 속도"
                          stroke="#F97316"
                          strokeWidth={2}
                          dot={false}
                        />
                        <Line
                          yAxisId="right"
                          type="monotone"
                          dataKey="hr"
                          name="심박수 (bpm)"
                          stroke="#EF4444"
                          strokeWidth={2}
                          dot={false}
                        />
                      </LineChart>
                    </ResponsiveContainer>
                    <p className="text-[11px] text-red-400 mt-1 text-right">flagged: low HR</p>
                  </div>

                  <div className="bg-gray-900/70 border border-gray-700 rounded-xl p-4 flex flex-col">
                    <h4 className="text-sm font-semibold mb-3">유저 제출 증빙</h4>
                    <div className="flex-1 flex items-center justify-center min-h-[200px]">
                      <div className="relative w-[160px] h-[190px] rounded-[36px] bg-gradient-to-b from-slate-700 to-slate-900 border-4 border-slate-600 shadow-2xl flex flex-col items-center pt-5 pb-4 px-3">
                        <div className="w-full flex-1 rounded-2xl bg-black border border-slate-500 overflow-hidden flex flex-col items-center justify-center p-3">
                          <p className="text-[10px] text-slate-400 mb-1">HEART RATE</p>
                          <p className="text-3xl font-black text-red-400 tabular-nums">122</p>
                          <p className="text-[10px] text-slate-500 mb-2">bpm</p>
                          <svg viewBox="0 0 100 28" className="w-full h-7 text-red-500">
                            <polyline
                              fill="none"
                              stroke="currentColor"
                              strokeWidth="2"
                              points="0,20 10,18 18,22 28,8 38,16 48,4 58,14 68,10 78,18 88,12 100,15"
                            />
                          </svg>
                          <p className="text-[9px] text-emerald-400 mt-2">Garmin · Live</p>
                        </div>
                        <div className="w-10 h-1 rounded-full bg-slate-500 mt-3" />
                      </div>
                    </div>
                    <p className="text-xs text-center text-gray-500 mt-2">
                      워치 원본 캡처 (제출 증빙)
                    </p>
                  </div>
                </div>
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 pt-2">
                <div className="flex flex-col gap-1">
                  <button
                    type="button"
                    disabled
                    className="flex items-center justify-center gap-2 rounded-xl px-4 py-3.5 bg-gray-700 text-gray-500 font-bold text-sm cursor-not-allowed"
                  >
                    <CheckCircle size={18} />
                    소명 승인 (기록 인정 및 100 밸류 토큰 강제지급)
                  </button>
                  <p className="text-[11px] text-center text-gray-500">
                    서버 관리자 API 준비 후 활성화
                  </p>
                </div>
                <button
                  type="button"
                  onClick={() => handleBan(selected.id)}
                  className="flex items-center justify-center gap-2 rounded-xl px-4 py-3.5 bg-red-900/90 hover:bg-red-800 text-white font-bold text-sm transition-colors border border-red-800"
                >
                  <XCircle size={18} />
                  기각 및 영구 정지 (패널티 부여)
                </button>
              </div>
            </div>
          )}
        </section>
      </div>
    </div>
  );
}

import { useState, useEffect, useMemo } from 'react';
import {
  Building2,
  CheckCircle,
  Pencil,
  Gift,
  Heart,
  Banknote,
} from 'lucide-react';
import { useFirestoreUsers } from '../../hooks/useFirestoreUsers';
import { updateUserStatus } from '../../lib/firestoreUsers';
import {
  subscribePaymentIntents,
  subscribeTournaments,
  type AdminPaymentIntent,
  type AdminTournament,
} from '../../lib/firestoreOps';

type Campaign = {
  id: string;
  brand: string;
  title: string;
  status: 'PENDING' | 'ACTIVE' | 'REJECTED';
  budgetShare: number;
  participants: number;
  reward: string;
  sponsorship: string;
  bannerText: string;
  bannerColor: string;
  value_balance: number;
};

export default function SponsorApproval() {
  const { users, loading: usersLoading, error: usersError } = useFirestoreUsers();
  const [payments, setPayments] = useState<AdminPaymentIntent[]>([]);
  const [tournaments, setTournaments] = useState<AdminTournament[]>([]);
  const [opsError, setOpsError] = useState<string | null>(null);
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [dismissed, setDismissed] = useState<Set<string>>(new Set());

  useEffect(() => {
    const u1 = subscribePaymentIntents({
      onData: setPayments,
      onError: (e) => setOpsError(e.message),
    });
    const u2 = subscribeTournaments({
      onData: setTournaments,
      onError: (e) => setOpsError(e.message),
    });
    return () => {
      u1();
      u2();
    };
  }, []);

  const campaigns = useMemo(() => {
    const sponsorPays = payments.filter(
      (p) =>
        (p.type === 'sponsor_payment' || p.type === 'sponsorSupport') &&
        !dismissed.has(p.id)
    );

    if (sponsorPays.length > 0) {
      return sponsorPays.map((p): Campaign => {
        const t = tournaments.find((x) => x.id === p.tournamentId);
        const brand =
          users.find((u) => u.id === p.uid)?.nickname ||
          t?.sponsorName ||
          p.uid.slice(0, 8);
        return {
          id: p.id,
          brand,
          title: t?.title || '스폰서 캠페인',
          status:
            p.status === 'paid' || p.status === 'completed'
              ? 'ACTIVE'
              : p.status === 'failed' || p.status === 'cancelled'
                ? 'REJECTED'
                : 'PENDING',
          budgetShare: p.amountShare || p.amountKrw,
          participants: t?.participantCount ?? t?.maxParticipants ?? 0,
          reward: `우승 VALUE ${t?.winnerRewardValue ?? 500}`,
          sponsorship: p.option
            ? `[옵션 ${p.option}] 스폰서 결제 인텐트`
            : '스폰서 결제 인텐트',
          bannerText:
            t?.sponsorBillboardMessages?.[0] ||
            `${brand}가 이번 대회의 러너들을 후원합니다!`,
          bannerColor: '#A3FF62',
          value_balance: p.amountShare || 0,
        };
      });
    }

    // sponsor payment 없으면 tournaments 스폰서 룸을 심사 큐로
    return tournaments
      .filter((t) => !dismissed.has(t.id) && t.sponsorName)
      .slice(0, 20)
      .map(
        (t): Campaign => ({
          id: t.id,
          brand: t.sponsorName,
          title: t.title,
          status:
            t.status === 'active' || t.status === 'completed'
              ? 'ACTIVE'
              : t.status.startsWith('cancelled')
                ? 'REJECTED'
                : 'PENDING',
          budgetShare: Math.max(t.entryFeeShare || 0, 0) * Math.max(t.maxParticipants, 1),
          participants: t.participantCount,
          reward: `우승 VALUE 리워드`,
          sponsorship: `스폰서: ${t.sponsorName}`,
          bannerText: `${t.sponsorName}가 이번 대회의 러너들을 후원합니다!`,
          bannerColor: '#C4F542',
          value_balance: 0,
        })
      );
  }, [payments, tournaments, users, dismissed]);

  const loading = usersLoading && payments.length === 0 && tournaments.length === 0;
  const error = usersError || opsError;

  useEffect(() => {
    if (campaigns.length === 0) {
      setSelectedId(null);
      return;
    }
    if (!selectedId || !campaigns.some((c) => c.id === selectedId)) {
      setSelectedId(campaigns[0]!.id);
    }
  }, [campaigns, selectedId]);

  const pendingCount = campaigns.filter((c) => c.status === 'PENDING').length;
  const selected = campaigns.find((c) => c.id === selectedId) ?? null;

  const handleApprove = async () => {
    if (!selected) return;
    const id = selected.id;
    setDismissed((prev) => new Set(prev).add(id));
    const pay = payments.find((p) => p.id === id);
    if (pay?.uid) {
      try {
        await updateUserStatus(pay.uid, 'ACTIVE');
      } catch (err) {
        console.error('캠페인 승인 에러:', err);
      }
    }
  };

  const handleReject = async () => {
    if (!selected) return;
    const id = selected.id;
    setDismissed((prev) => new Set(prev).add(id));
    const pay = payments.find((p) => p.id === id);
    if (pay?.uid) {
      try {
        await updateUserStatus(pay.uid, 'SUSPENDED');
      } catch (err) {
        console.error('캠페인 반려 에러:', err);
      }
    }
  };

  return (
    <div className="h-full overflow-hidden text-white flex flex-col">
      <div className="px-6 pt-5 pb-3 shrink-0">
        <h2 className="text-xl font-bold tracking-tight flex items-center gap-2">
          <Building2 size={22} className="text-amber-400" />
          B2B 스폰서 룸 승인
        </h2>
        <p className="text-sm text-gray-400 mt-1">
          브랜드 스폰서 룸·광고 롤링 배너를 심사하고 앱 라이브 송출을 승인합니다.
        </p>
        {error && (
          <p className="text-xs text-amber-400 mt-1">Firestore: {error}</p>
        )}
      </div>

      <div className="flex-1 min-h-0 grid grid-cols-1 lg:grid-cols-[340px_1fr] gap-4 px-6 pb-6">
        {/* 캠페인 심사 대기 */}
        <section className="bg-gray-800/80 border border-gray-700 rounded-xl flex flex-col min-h-0 overflow-hidden">
          <div className="px-4 py-3 border-b border-gray-700 shrink-0">
            <h3 className="font-bold text-gray-300">
              B2B 캠페인 심사 대기 ({pendingCount}건)
            </h3>
          </div>

          <div className="flex-1 overflow-y-auto p-3 space-y-2">
            {loading ? (
              <p className="text-center text-gray-500 text-sm py-8">불러오는 중...</p>
            ) : campaigns.length === 0 ? (
              <div className="flex flex-col items-center justify-center text-gray-500 gap-2 py-12">
                <CheckCircle size={28} className="text-lime-400/50" />
                <p className="text-sm">심사 대기 캠페인이 없습니다.</p>
              </div>
            ) : (
              campaigns.map((item) => {
                const active = item.id === selectedId;
                return (
                  <button
                    key={item.id}
                    type="button"
                    onClick={() => setSelectedId(item.id)}
                    className={`w-full text-left rounded-xl px-3 py-3.5 transition-colors border ${
                      active
                        ? 'bg-gray-700/90 border-amber-500/70'
                        : 'bg-gray-900/50 border-gray-700 hover:border-gray-500'
                    }`}
                  >
                    <p className="text-sm font-semibold text-white leading-snug">
                      <span className="text-amber-400">[대기]</span> {item.brand} -{' '}
                      {item.title}
                    </p>
                  </button>
                );
              })
            )}
          </div>
        </section>

        {/* 브랜드 스폰서 룸 심사 */}
        <section className="bg-gray-800/80 border border-gray-700 rounded-xl flex flex-col min-h-0 overflow-hidden">
          <div className="px-5 py-3 border-b border-gray-700 shrink-0">
            <h3 className="font-bold text-white">
              브랜드 스폰서 룸 및 광고 롤링 배너 심사
            </h3>
          </div>

          {!selected ? (
            <div className="flex-1 flex items-center justify-center text-gray-500 text-sm">
              좌측에서 캠페인을 선택하세요.
            </div>
          ) : (
            <div className="flex-1 overflow-y-auto p-5 space-y-5">
              <div>
                <p className="text-xs font-semibold text-gray-400 uppercase tracking-wide mb-3">
                  Budget and Reward Verification
                </p>
                <div className="space-y-3">
                  <div className="flex items-start gap-3 bg-gray-900/60 border border-gray-700 rounded-xl px-4 py-3.5">
                    <div className="p-2 rounded-lg bg-amber-500/10 text-amber-400 shrink-0">
                      <Banknote size={18} />
                    </div>
                    <div>
                      <p className="text-xs text-gray-500 mb-0.5">선수금 예산</p>
                      <p className="text-sm font-semibold text-white">
                        {selected.budgetShare.toLocaleString()} SHARE
                        <span className="text-gray-400 font-normal">
                          {' '}
                          (참가 {selected.participants.toLocaleString()}명 기준)
                        </span>
                      </p>
                    </div>
                  </div>

                  <div className="flex items-start gap-3 bg-gray-900/60 border border-gray-700 rounded-xl px-4 py-3.5">
                    <div className="p-2 rounded-lg bg-lime-500/10 text-lime-400 shrink-0">
                      <Gift size={18} />
                    </div>
                    <div>
                      <p className="text-xs text-gray-500 mb-0.5">우승 리워드</p>
                      <p className="text-sm font-semibold text-white">{selected.reward}</p>
                    </div>
                  </div>

                  <div className="flex items-start gap-3 bg-gray-900/60 border border-gray-700 rounded-xl px-4 py-3.5">
                    <div className="p-2 rounded-lg bg-rose-500/10 text-rose-400 shrink-0">
                      <Heart size={18} />
                    </div>
                    <div>
                      <p className="text-xs text-gray-500 mb-0.5">스폰서십 옵션</p>
                      <p className="text-sm font-semibold text-white">{selected.sponsorship}</p>
                    </div>
                  </div>
                </div>
              </div>

              <div>
                <p className="text-xs font-semibold text-gray-400 uppercase tracking-wide mb-3">
                  Mobile App Banner Preview
                </p>
                <div className="flex justify-center py-2">
                  <div className="relative w-[220px]">
                    {/* Phone frame */}
                    <div className="rounded-[36px] border-[5px] border-gray-600 bg-black shadow-2xl overflow-hidden">
                      <div className="relative h-[8px] bg-black">
                        <div className="absolute left-1/2 -translate-x-1/2 top-0 w-24 h-5 bg-black rounded-b-2xl z-10" />
                      </div>
                      <div
                        className="min-h-[380px] flex items-center justify-center px-6 py-10"
                        style={{ backgroundColor: selected.bannerColor }}
                      >
                        <p className="text-center text-black font-black text-lg leading-snug">
                          {selected.bannerText}
                        </p>
                      </div>
                      <div className="h-5 bg-black flex items-center justify-center">
                        <div className="w-20 h-1 rounded-full bg-gray-700" />
                      </div>
                    </div>
                  </div>
                </div>
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 pt-1">
                <button
                  type="button"
                  onClick={handleApprove}
                  className="flex items-center justify-center gap-2 rounded-xl px-4 py-3.5 bg-lime-400 hover:bg-lime-300 text-black font-bold text-sm transition-colors"
                >
                  <CheckCircle size={18} />
                  캠페인 승인 및 앱 라이브 송출 (Publish)
                </button>
                <button
                  type="button"
                  onClick={handleReject}
                  className="flex items-center justify-center gap-2 rounded-xl px-4 py-3.5 bg-gray-700 hover:bg-gray-600 text-white font-bold text-sm transition-colors border border-gray-600"
                >
                  <Pencil size={16} />
                  조건 수정 요청 (반려)
                </button>
              </div>
            </div>
          )}
        </section>
      </div>
    </div>
  );
}

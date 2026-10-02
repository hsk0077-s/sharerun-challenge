import { useEffect, useState } from 'react';
import { Building2 } from 'lucide-react';
import {
  subscribePaymentIntents,
  subscribeTournaments,
  type AdminPaymentIntent,
  type AdminTournament,
} from '../../lib/firestoreOps';

function formatWhen(iso: string): string {
  if (!iso) return '-';
  const date = new Date(iso);
  if (Number.isNaN(date.getTime())) return '-';
  return date.toLocaleString('ko-KR');
}

function paymentStatusText(status: string): string {
  if (status === 'credited') return 'credited · 완료';
  if (!status) return '-';
  return status;
}

const ACTIVATION_NOTE =
  '대회 활성화는 서버 POST /ops/tournaments/{id}/activate 에서 처리합니다. 관리자 API는 이후 작업입니다.';

function billboardText(messages: string[]): string {
  const lines = messages.map((line) => line.trim()).filter(Boolean);
  return lines.length > 0 ? lines.join(' / ') : '-';
}

export default function SponsorApproval() {
  const [payments, setPayments] = useState<AdminPaymentIntent[] | null>(null);
  const [tournaments, setTournaments] = useState<AdminTournament[] | null>(null);
  const [paymentError, setPaymentError] = useState<string | null>(null);
  const [tournamentError, setTournamentError] = useState<string | null>(null);

  useEffect(() => {
    const unsubPayments = subscribePaymentIntents({
      onData: (rows) => {
        setPayments(rows);
        setPaymentError(null);
      },
      onError: (err) => {
        setPaymentError(err.message);
        setPayments([]);
      },
    });
    const unsubTournaments = subscribeTournaments({
      onData: (rows) => {
        setTournaments(rows);
        setTournamentError(null);
      },
      onError: (err) => {
        setTournamentError(err.message);
        setTournaments([]);
      },
    });
    return () => {
      unsubPayments();
      unsubTournaments();
    };
  }, []);

  const error = paymentError || tournamentError;
  const sponsorPayments = (payments ?? []).filter((intent) => intent.type === 'sponsor_payment');

  return (
    <div className="h-full overflow-hidden text-white flex flex-col">
      <div className="px-6 pt-5 pb-3 shrink-0">
        <h2 className="text-xl font-bold tracking-tight flex items-center gap-2">
          <Building2 size={22} className="text-amber-400" />
          B2B 스폰서 룸 승인
        </h2>
        <p className="text-sm text-gray-400 mt-1">
          스폰서 결제와 대회 스폰서 필드를 조회합니다. 이 화면에서는 바꾸지 않습니다.
        </p>
        <p className="text-xs text-amber-200/90 mt-2">{ACTIVATION_NOTE}</p>
        {error && <p className="text-xs text-amber-400 mt-1">Firestore: {error}</p>}
      </div>

      <div className="flex-1 min-h-0 grid grid-cols-1 lg:grid-cols-2 gap-4 px-6 pb-6">
        <section className="bg-gray-800/80 border border-gray-700 rounded-xl flex flex-col min-h-0 overflow-hidden">
          <div className="px-4 py-3 border-b border-gray-700 shrink-0">
            <h3 className="font-bold text-white">스폰서 결제</h3>
            <p className="text-xs text-gray-400 mt-0.5">
              sponsor_payment ({sponsorPayments.length}건)
            </p>
          </div>
          <div className="flex-1 overflow-y-auto p-3 space-y-2">
            {payments === null ? (
              <p className="text-center text-gray-500 text-sm py-8">불러오는 중...</p>
            ) : sponsorPayments.length === 0 ? (
              <p className="text-center text-gray-500 text-sm py-8">스폰서 결제가 없습니다.</p>
            ) : (
              sponsorPayments.map((intent) => (
                <PaymentRow key={intent.id} intent={intent} />
              ))
            )}
          </div>
        </section>

        <section className="bg-gray-800/80 border border-gray-700 rounded-xl flex flex-col min-h-0 overflow-hidden">
          <div className="px-4 py-3 border-b border-gray-700 shrink-0">
            <h3 className="font-bold text-white">대회 스폰서</h3>
            <p className="text-xs text-gray-400 mt-0.5">tournaments ({tournaments?.length ?? 0}건)</p>
          </div>
          <div className="flex-1 overflow-y-auto p-3 space-y-2">
            {tournaments === null ? (
              <p className="text-center text-gray-500 text-sm py-8">불러오는 중...</p>
            ) : tournaments.length === 0 ? (
              <p className="text-center text-gray-500 text-sm py-8">대회가 없습니다.</p>
            ) : (
              tournaments.map((tournament) => (
                <TournamentRow key={tournament.id} tournament={tournament} />
              ))
            )}
          </div>
        </section>
      </div>
    </div>
  );
}

function PaymentRow({ intent }: { intent: AdminPaymentIntent }) {
  return (
    <div className="rounded-xl px-3 py-3 bg-gray-900/50 border border-gray-700">
      <p className="text-sm font-semibold text-white">
        {intent.amountShare.toLocaleString()} SHARE{' '}
        <span className="text-amber-300 font-normal">· {paymentStatusText(intent.status)}</span>
      </p>
      <p className="text-xs text-gray-400 mt-1 truncate">uid {intent.uid || '-'}</p>
      <p className="text-xs text-gray-500 mt-1 truncate">
        tournament {intent.tournamentId || '-'}
        {intent.option ? ` · ${intent.option}` : ''}
      </p>
      <p className="text-xs text-gray-500 mt-1">{formatWhen(intent.createdAt)}</p>
    </div>
  );
}

function TournamentRow({ tournament }: { tournament: AdminTournament }) {
  return (
    <div className="rounded-xl px-3 py-3 bg-gray-900/50 border border-gray-700">
      <p className="text-sm font-semibold text-white truncate">
        {tournament.title || '-'}{' '}
        <span className="text-gray-400 font-normal">· {tournament.status || '-'}</span>
      </p>
      <p className="text-xs text-gray-400 mt-1 truncate">
        sponsorName {tournament.sponsorName || '-'}
      </p>
      <p className="text-xs text-gray-300 mt-1">
        상금 지원 {tournament.sponsorPrizeSupportShare.toLocaleString()} SHARE · 기부 지원{' '}
        {tournament.sponsorDonationSupportShare.toLocaleString()} SHARE
      </p>
      <p className="text-xs text-gray-500 mt-1 break-words">
        전광판 {billboardText(tournament.sponsorBillboardMessages)}
      </p>
    </div>
  );
}

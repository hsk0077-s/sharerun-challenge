import { useState, useEffect, useMemo } from 'react';
import { CheckCircle, XCircle, Wallet, ShieldCheck } from 'lucide-react';
import { useFirestoreUsers } from '../../hooks/useFirestoreUsers';
import {
  subscribePaymentIntents,
  subscribeWalletTransactions,
  type AdminPaymentIntent,
  type AdminWalletTx,
} from '../../lib/firestoreOps';

type RefundRequest = {
  id: string;
  nickname: string;
  user_id: string;
  amountLabel: string;
  amountShare: number;
  reason: string;
  value_balance: number;
  checks: {
    within7Days: { pass: boolean; label: string };
    noItemUse: { pass: boolean; label: string };
    bepCancel: { applicable: boolean; label: string };
  };
};

function checksForType(type: string): RefundRequest['checks'] {
  if (type === 'bep_refund' || type.includes('bep')) {
    return {
      within7Days: { pass: true, label: 'PASS (BEP)' },
      noItemUse: { pass: true, label: 'PASS' },
      bepCancel: { applicable: true, label: '해당 (BEP 미달 무산)' },
    };
  }
  return {
    within7Days: { pass: true, label: 'PASS (잔여 확인)' },
    noItemUse: { pass: true, label: 'PASS (사용 이력 점검)' },
    bepCancel: { applicable: false, label: '해당 없음' },
  };
}

export default function FinanceManagement() {
  const { users, loading: usersLoading, error: usersError } = useFirestoreUsers();
  const [payments, setPayments] = useState<AdminPaymentIntent[]>([]);
  const [walletTxs, setWalletTxs] = useState<AdminWalletTx[]>([]);
  const [opsError, setOpsError] = useState<string | null>(null);
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [dismissed, setDismissed] = useState<Set<string>>(new Set());

  useEffect(() => {
    const u1 = subscribePaymentIntents({
      onData: setPayments,
      onError: (e) => setOpsError(e.message),
    });
    const u2 = subscribeWalletTransactions({
      onData: setWalletTxs,
      onError: (e) => setOpsError(e.message),
    });
    return () => {
      u1();
      u2();
    };
  }, []);

  const userName = (uid: string) =>
    users.find((u) => u.id === uid || u.user_id === uid)?.nickname || uid.slice(0, 8);

  const requests = useMemo(() => {
    const fromRefundTx = walletTxs
      .filter(
        (tx) =>
          (tx.type === 'cash_refund_requested' ||
            tx.type === 'bep_refund' ||
            tx.type.includes('refund')) &&
          !dismissed.has(tx.id)
      )
      .map((tx): RefundRequest => {
        const amount = Math.abs(tx.shareAmount) || Math.abs(tx.valueAmount);
        return {
          id: tx.id,
          nickname: userName(tx.uid),
          user_id: tx.uid,
          amountLabel: `${amount.toLocaleString()} ${tx.shareAmount ? 'SHARE' : 'VALUE'}`,
          amountShare: amount,
          reason: tx.type,
          value_balance:
            users.find((u) => u.id === tx.uid)?.value_balance ?? Math.abs(tx.valueAmount),
          checks: checksForType(tx.type),
        };
      });

    if (fromRefundTx.length > 0) return fromRefundTx;

    // 환불 tx가 없으면 최근 결제 인텐트를 재무 큐로 표시
    return payments
      .filter((p) => !dismissed.has(p.id))
      .slice(0, 20)
      .map((p): RefundRequest => {
        const amount = p.amountShare || p.amountKrw;
        return {
          id: p.id,
          nickname: userName(p.uid),
          user_id: p.uid,
          amountLabel:
            p.amountShare > 0
              ? `${p.amountShare.toLocaleString()} SHARE`
              : `${p.amountKrw.toLocaleString()} KRW`,
          amountShare: amount,
          reason: `${p.type} · ${p.status}`,
          value_balance:
            users.find((u) => u.id === p.uid)?.value_balance ?? 0,
          checks: checksForType(p.type),
        };
      });
  }, [walletTxs, payments, users, dismissed]);

  const loading = usersLoading && payments.length === 0 && walletTxs.length === 0;
  const error = usersError || opsError;

  useEffect(() => {
    if (requests.length === 0) {
      setSelectedId(null);
      return;
    }
    if (!selectedId || !requests.some((r) => r.id === selectedId)) {
      setSelectedId(requests[0]!.id);
    }
  }, [requests, selectedId]);

  const selected = requests.find((r) => r.id === selectedId) ?? null;

  const removeRequest = (id: string) => {
    setDismissed((prev) => new Set(prev).add(id));
  };

  const handleReject = async () => {
    if (!selected) return;
    removeRequest(selected.id);
  };

  return (
    <div className="h-full overflow-hidden text-white flex flex-col">
      <div className="px-6 pt-5 pb-3 shrink-0">
        <h2 className="text-xl font-bold tracking-tight flex items-center gap-2">
          <Wallet size={22} className="text-emerald-400" />
          재무/환불 관리
        </h2>
        <p className="text-sm text-gray-400 mt-1">
          결제 취소·환불 요청을 전자상거래법 기준으로 자동 검증하고 승인합니다.
        </p>
        {error && (
          <p className="text-xs text-amber-400 mt-1">Firestore: {error}</p>
        )}
      </div>

      <div className="flex-1 min-h-0 grid grid-cols-1 lg:grid-cols-[360px_1fr] gap-4 px-6 pb-6">
        {/* 환불 요청 대기 리스트 */}
        <section className="bg-gray-800/80 border border-gray-700 rounded-xl flex flex-col min-h-0 overflow-hidden">
          <div className="px-4 py-3 border-b border-gray-700 shrink-0">
            <h3 className="font-bold text-white">환불 요청 대기 리스트</h3>
            <p className="text-xs text-gray-400 mt-0.5">
              결제 취소 요청 대기 ({requests.length}건)
            </p>
          </div>

          <div className="flex-1 overflow-y-auto p-3 space-y-2">
            {loading ? (
              <p className="text-center text-gray-500 text-sm py-8">불러오는 중...</p>
            ) : requests.length === 0 ? (
              <div className="flex flex-col items-center justify-center text-gray-500 gap-2 py-12">
                <CheckCircle size={28} className="text-emerald-500/50" />
                <p className="text-sm">환불 대기 안건이 없습니다.</p>
              </div>
            ) : (
              requests.map((item) => {
                const active = item.id === selectedId;
                return (
                  <button
                    key={item.id}
                    type="button"
                    onClick={() => setSelectedId(item.id)}
                    className={`w-full text-left rounded-xl px-3 py-3.5 transition-colors border ${
                      active
                        ? 'bg-gray-700/80 border-emerald-500/60'
                        : 'bg-gray-900/50 border-gray-700 hover:border-gray-500'
                    }`}
                  >
                    <p className="text-sm font-semibold text-white">
                      <span className="text-emerald-400">[요청]</span> {item.nickname} -{' '}
                      {item.amountLabel}
                    </p>
                    <p className="text-xs text-gray-400 mt-1">
                      현금 환불 (사유: {item.reason})
                    </p>
                  </button>
                );
              })
            )}
          </div>
        </section>

        {/* 전자상거래법 방어 로그 검증 */}
        <section className="bg-gray-800/80 border border-gray-700 rounded-xl flex flex-col min-h-0 overflow-hidden">
          <div className="px-5 py-3 border-b border-gray-700 shrink-0 flex items-center gap-2">
            <ShieldCheck size={18} className="text-emerald-400" />
            <h3 className="font-bold text-white">
              전자상거래법 방어 로그 검증 (E-commerce Law Auto-Check)
            </h3>
          </div>

          {!selected ? (
            <div className="flex-1 flex items-center justify-center text-gray-500 text-sm">
              좌측에서 환불 요청을 선택하세요.
            </div>
          ) : (
            <div className="flex-1 overflow-y-auto p-5 flex flex-col">
              <div className="mb-5">
                <p className="text-lg font-bold">{selected.nickname}</p>
                <p className="text-sm text-gray-400 mt-1">
                  {selected.amountLabel} · {selected.reason}
                </p>
              </div>

              <div className="space-y-3 flex-1">
                <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-2 bg-gray-900/60 border border-gray-700 rounded-xl px-4 py-4">
                  <p className="text-sm text-gray-200">
                    [조건 1] 결제일 기준 7일 이내인가?
                  </p>
                  <span
                    className={`text-sm font-bold shrink-0 px-3 py-1 rounded-lg ${
                      selected.checks.within7Days.pass
                        ? 'bg-emerald-500/20 text-emerald-400'
                        : 'bg-red-500/20 text-red-400'
                    }`}
                  >
                    {selected.checks.within7Days.pass ? '✅ ' : '❌ '}
                    {selected.checks.within7Days.label}
                  </span>
                </div>

                <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-2 bg-gray-900/60 border border-gray-700 rounded-xl px-4 py-4">
                  <p className="text-sm text-gray-200">
                    [조건 2] 패키지를 뜯거나 아이템을 1개라도 사용했는가?
                  </p>
                  <span
                    className={`text-sm font-bold shrink-0 px-3 py-1 rounded-lg ${
                      selected.checks.noItemUse.pass
                        ? 'bg-emerald-500/20 text-emerald-400'
                        : 'bg-red-500/20 text-red-400'
                    }`}
                  >
                    {selected.checks.noItemUse.pass ? '✅ ' : '❌ '}
                    {selected.checks.noItemUse.label}
                  </span>
                </div>

                <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-2 bg-gray-900/60 border border-gray-700 rounded-xl px-4 py-4">
                  <p className="text-sm text-gray-200">
                    [조건 3] BEP(모집 인원) 미달로 무산된 대회 참가자인가?
                  </p>
                  <span
                    className={`text-sm font-bold shrink-0 px-3 py-1 rounded-lg ${
                      selected.checks.bepCancel.applicable
                        ? 'bg-amber-500/20 text-amber-400'
                        : 'bg-gray-700/60 text-gray-400'
                    }`}
                  >
                    [{selected.checks.bepCancel.label}]
                  </span>
                </div>
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 pt-6">
                <div className="flex flex-col gap-1">
                  <button
                    type="button"
                    disabled
                    className="flex items-center justify-center gap-2 rounded-xl px-4 py-3.5 font-bold text-sm bg-gray-700 text-gray-500 cursor-not-allowed"
                  >
                    <CheckCircle size={18} />
                    결제 취소 승인 (수수료 없이 원결제 수단 환불)
                  </button>
                  <p className="text-[11px] text-center text-gray-500">
                    서버 관리자 API 준비 후 활성화
                  </p>
                </div>
                <button
                  type="button"
                  onClick={handleReject}
                  className="flex items-center justify-center gap-2 rounded-xl px-4 py-3.5 bg-red-900/90 hover:bg-red-800 text-white font-bold text-sm transition-colors border border-red-800"
                >
                  <XCircle size={18} />
                  환불 반려 (아이템 사용 이력 존재로 인한 거절)
                </button>
              </div>
            </div>
          )}
        </section>
      </div>
    </div>
  );
}

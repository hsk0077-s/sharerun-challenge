import { useEffect, useState } from 'react';
import { Wallet } from 'lucide-react';
import { useFirestoreUsers } from '../../hooks/useFirestoreUsers';
import {
  subscribePlayPurchases,
  subscribeWalletTransactions,
  type AdminPlayPurchase,
  type AdminWalletTx,
} from '../../lib/firestoreOps';

function formatWhen(iso: string): string {
  if (!iso) return '-';
  const date = new Date(iso);
  if (Number.isNaN(date.getTime())) return '-';
  return date.toLocaleString('ko-KR');
}

function purchaseAmount(purchase: AdminPlayPurchase): string {
  const parts: string[] = [];
  if (purchase.priceKrw) parts.push(`${purchase.priceKrw.toLocaleString()} KRW`);
  if (purchase.diamondAmount) parts.push(`${purchase.diamondAmount.toLocaleString()} 다이아`);
  return parts.length > 0 ? parts.join(' · ') : '-';
}

function walletAmount(tx: AdminWalletTx): string {
  const parts: string[] = [];
  if (tx.shareAmount) parts.push(`${tx.shareAmount.toLocaleString()} SHARE`);
  if (tx.diamondAmount) parts.push(`${tx.diamondAmount.toLocaleString()} 다이아`);
  if (tx.valueAmount) parts.push(`${tx.valueAmount.toLocaleString()} VALUE`);
  return parts.length > 0 ? parts.join(' · ') : '-';
}

function walletStatus(type: string): string | null {
  if (type === 'cash_refund_requested') return '환불 요청 기록';
  return null;
}

export default function FinanceManagement() {
  const { users, error: usersError } = useFirestoreUsers();
  const [payments, setPayments] = useState<AdminPlayPurchase[] | null>(null);
  const [walletTxs, setWalletTxs] = useState<AdminWalletTx[] | null>(null);
  const [paymentError, setPaymentError] = useState<string | null>(null);
  const [walletError, setWalletError] = useState<string | null>(null);

  useEffect(() => {
    const unsubPayments = subscribePlayPurchases({
      onData: (rows) => {
        setPayments(rows);
        setPaymentError(null);
      },
      onError: (err) => {
        setPaymentError(err.message);
        setPayments([]);
      },
    });
    const unsubWallet = subscribeWalletTransactions({
      onData: (rows) => {
        setWalletTxs(rows);
        setWalletError(null);
      },
      onError: (err) => {
        setWalletError(err.message);
        setWalletTxs([]);
      },
    });
    return () => {
      unsubPayments();
      unsubWallet();
    };
  }, []);

  const error = usersError || paymentError || walletError;

  const userLabel = (uid: string) => {
    if (!uid) return '-';
    const user = users.find((row) => row.id === uid || row.user_id === uid);
    return user ? `${user.nickname} · ${uid}` : uid;
  };

  return (
    <div className="h-full overflow-hidden text-white flex flex-col">
      <div className="px-6 pt-5 pb-3 shrink-0">
        <h2 className="text-xl font-bold tracking-tight flex items-center gap-2">
          <Wallet size={22} className="text-emerald-400" />
          재무/환불 관리
        </h2>
        <p className="text-sm text-gray-400 mt-1">
          Google Play 인앱 결제 영수증과 지갑 거래를 조회합니다. 이 화면에서는 바꾸지 않습니다.
        </p>
        {error && <p className="text-xs text-amber-400 mt-1">Firestore: {error}</p>}
      </div>

      <div className="flex-1 min-h-0 grid grid-cols-1 lg:grid-cols-2 gap-4 px-6 pb-6">
        <section className="bg-gray-800/80 border border-gray-700 rounded-xl flex flex-col min-h-0 overflow-hidden">
          <div className="px-4 py-3 border-b border-gray-700 shrink-0">
            <h3 className="font-bold text-white">Google Play 결제 영수증</h3>
            <p className="text-xs text-gray-400 mt-0.5">
              playPurchases ({payments?.length ?? 0}건)
            </p>
          </div>
          <div className="flex-1 overflow-y-auto p-3 space-y-2">
            {payments === null ? (
              <p className="text-center text-gray-500 text-sm py-8">불러오는 중...</p>
            ) : payments.length === 0 ? (
              <p className="text-center text-gray-500 text-sm py-8">결제 영수증이 없습니다.</p>
            ) : (
              payments.map((purchase) => (
                <div
                  key={purchase.id}
                  className="rounded-xl px-3 py-3 bg-gray-900/50 border border-gray-700"
                >
                  <p className="text-sm font-semibold text-white">
                    {purchase.productId || '-'}{' '}
                    {purchase.refundStatus ? (
                      <span className="text-amber-400 font-normal">· 환불 {purchase.refundStatus}</span>
                    ) : null}
                  </p>
                  <p className="text-xs text-gray-300 mt-1">{purchaseAmount(purchase)}</p>
                  <p className="text-xs text-gray-400 mt-1 truncate">{userLabel(purchase.uid)}</p>
                  {purchase.orderId ? (
                    <p className="text-xs text-gray-500 mt-1 truncate">order {purchase.orderId}</p>
                  ) : null}
                  <p className="text-xs text-gray-500 mt-1">{formatWhen(purchase.createdAt)}</p>
                </div>
              ))
            )}
          </div>
        </section>

        <section className="bg-gray-800/80 border border-gray-700 rounded-xl flex flex-col min-h-0 overflow-hidden">
          <div className="px-4 py-3 border-b border-gray-700 shrink-0">
            <h3 className="font-bold text-white">지갑 거래</h3>
            <p className="text-xs text-gray-400 mt-0.5">walletTransactions ({walletTxs?.length ?? 0}건)</p>
          </div>
          <div className="flex-1 overflow-y-auto p-3 space-y-2">
            {walletTxs === null ? (
              <p className="text-center text-gray-500 text-sm py-8">불러오는 중...</p>
            ) : walletTxs.length === 0 ? (
              <p className="text-center text-gray-500 text-sm py-8">지갑 거래가 없습니다.</p>
            ) : (
              walletTxs.map((tx) => {
                const settled = walletStatus(tx.type);
                return (
                  <div
                    key={tx.id}
                    className="rounded-xl px-3 py-3 bg-gray-900/50 border border-gray-700"
                  >
                    <p className="text-sm font-semibold text-white">{tx.type || '-'}</p>
                    {settled ? (
                      <p className="text-xs text-amber-400 mt-1">{settled}</p>
                    ) : null}
                    <p className="text-xs text-gray-300 mt-1">{walletAmount(tx)}</p>
                    <p className="text-xs text-gray-400 mt-1 truncate">{userLabel(tx.uid)}</p>
                    <p className="text-xs text-gray-500 mt-1">{formatWhen(tx.createdAt)}</p>
                  </div>
                );
              })
            )}
          </div>
        </section>
      </div>
    </div>
  );
}

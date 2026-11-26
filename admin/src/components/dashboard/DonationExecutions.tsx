import { useEffect, useState, type FormEvent } from 'react';
import { HandHeart } from 'lucide-react';
import { ref, uploadBytes } from 'firebase/storage';
import { ensureAdminAuth } from '../../lib/adminAuth';
import { getStorageClient } from '../../lib/firebase';
import { currentKstMonth, subscribeDonationExecutions, type DonationExecution } from '../../lib/firestoreOps';
import { saveDonationExecution } from '../../lib/jenaApi';

const MAX_IMAGE_BYTES = 10 * 1024 * 1024;

function safeFileName(name: string): string {
  const cleaned = name.replace(/[^A-Za-z0-9._-]+/g, '-').replace(/^[^A-Za-z0-9]+/, '');
  return (cleaned || 'receipt').slice(-80);
}

function errorText(err: unknown): string {
  if (err instanceof Error && err.message === 'forbidden') return '권한 없음(관리자만 저장할 수 있습니다).';
  if (err instanceof Error && err.message === 'jena') return '서버에 저장하지 못했습니다. 입력값을 확인하세요.';
  if (err instanceof Error && /storage\//.test(err.message)) return '증빙 이미지를 올리지 못했습니다(권한 또는 크기).';
  return '저장하지 못했습니다.';
}

/** 실제로 보낸 기부를 달마다 한 건씩 적는다. 저장하면 그 달 원장 행이 receiptIssued 가 된다. */
export default function DonationExecutions() {
  const [rows, setRows] = useState<DonationExecution[] | null>(null);
  const [month, setMonth] = useState(currentKstMonth());
  const [amount, setAmount] = useState('');
  const [executedAt, setExecutedAt] = useState('');
  const [partner, setPartner] = useState('');
  const [note, setNote] = useState('');
  const [file, setFile] = useState<File | null>(null);
  const [busy, setBusy] = useState(false);
  const [message, setMessage] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(
    () =>
      subscribeDonationExecutions(setRows, (err) => {
        console.error('[DonationExecutions]', err);
        setError('기록을 불러오지 못했습니다.');
      }),
    []
  );

  async function onSubmit(event: FormEvent) {
    event.preventDefault();
    setMessage(null);
    setError(null);
    const amountWon = Number(amount.replace(/,/g, ''));
    if (!/^\d{4}-(0[1-9]|1[0-2])$/.test(month)) return setError('월은 YYYY-MM 형식으로 적으세요.');
    if (!Number.isInteger(amountWon) || amountWon <= 0) return setError('금액은 1원 이상의 정수로 적으세요.');
    if (!executedAt) return setError('집행일을 고르세요.');
    if (!partner.trim()) return setError('기부처를 적으세요.');
    const existing = rows?.find((row) => row.month === month);
    if (!file && !existing) return setError('증빙 이미지를 고르세요.');
    if (file && !file.type.startsWith('image/')) return setError('증빙은 이미지 파일이어야 합니다.');
    if (file && file.size >= MAX_IMAGE_BYTES) return setError('증빙 이미지는 10MB보다 작아야 합니다.');

    setBusy(true);
    try {
      const admin = await ensureAdminAuth();
      if (!admin) throw new Error('forbidden');
      let path = existing?.receiptImagePath ?? '';
      if (file) {
        path = `donation-receipts/${month}/${Date.now()}-${safeFileName(file.name)}`;
        await uploadBytes(ref(getStorageClient(), path), file, { contentType: file.type });
      }
      const result = await saveDonationExecution(await admin.getIdToken(), {
        month,
        amount_won: amountWon,
        executed_at: executedAt,
        partner_name: partner.trim(),
        receipt_image_path: path,
        note: note.trim(),
      });
      setMessage(
        `${result.month} 기록을 ${result.replaced ? '바꿔 저장' : '저장'}했습니다. 원장 ${result.ledger_rows_marked.toLocaleString()}건을 증빙 완료로 표시했습니다.`
      );
      setFile(null);
    } catch (err) {
      setError(errorText(err));
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="p-6 space-y-6">
      <div className="flex items-center gap-3">
        <HandHeart className="text-emerald-400" size={22} />
        <h2 className="text-xl font-bold text-white">기부 집행 기록</h2>
      </div>
      <p className="text-sm text-gray-400">
        실제로 보낸 기부만 적습니다. 저장하면 앱의 기부 화면에 금액, 집행일, 기부처, 증빙 이미지가 공개됩니다.
        같은 달을 다시 저장하면 바뀝니다.
      </p>

      <form onSubmit={onSubmit} className="bg-gray-800 border border-gray-700 rounded-xl p-6 grid gap-4 max-w-2xl">
        <label className="grid gap-1 text-sm text-gray-300">
          대상 월(KST)
          <input value={month} onChange={(e) => setMonth(e.target.value)} placeholder="2026-11"
            className="bg-gray-900 border border-gray-700 rounded px-3 py-2 text-white" />
        </label>
        <label className="grid gap-1 text-sm text-gray-300">
          집행 금액(원)
          <input value={amount} onChange={(e) => setAmount(e.target.value)} inputMode="numeric" placeholder="예: 150000"
            className="bg-gray-900 border border-gray-700 rounded px-3 py-2 text-white" />
        </label>
        <label className="grid gap-1 text-sm text-gray-300">
          집행일
          <input type="date" value={executedAt} onChange={(e) => setExecutedAt(e.target.value)}
            className="bg-gray-900 border border-gray-700 rounded px-3 py-2 text-white" />
        </label>
        <label className="grid gap-1 text-sm text-gray-300">
          기부처 이름
          <input value={partner} onChange={(e) => setPartner(e.target.value)} maxLength={100}
            className="bg-gray-900 border border-gray-700 rounded px-3 py-2 text-white" />
        </label>
        <label className="grid gap-1 text-sm text-gray-300">
          증빙 이미지(10MB 미만)
          <input type="file" accept="image/*" onChange={(e) => setFile(e.target.files?.[0] ?? null)}
            className="text-gray-300" />
          {rows?.some((row) => row.month === month) && (
            <span className="text-xs text-gray-500">이미 기록이 있는 달입니다. 이미지를 고르지 않으면 기존 증빙을 그대로 씁니다.</span>
          )}
        </label>
        <label className="grid gap-1 text-sm text-gray-300">
          메모(선택, 500자까지)
          <textarea value={note} onChange={(e) => setNote(e.target.value)} maxLength={500} rows={3}
            className="bg-gray-900 border border-gray-700 rounded px-3 py-2 text-white" />
        </label>
        <button type="submit" disabled={busy}
          className="bg-emerald-600 hover:bg-emerald-500 disabled:opacity-50 text-white font-bold rounded px-4 py-2">
          {busy ? '저장 중…' : '저장'}
        </button>
        {message && <p className="text-sm text-emerald-400">{message}</p>}
        {error && <p className="text-sm text-red-400">{error}</p>}
      </form>

      <div className="bg-gray-800 border border-gray-700 rounded-xl overflow-hidden">
        <table className="w-full text-sm text-left text-gray-300">
          <thead className="bg-gray-900 text-gray-400">
            <tr>
              <th className="px-4 py-2">월</th>
              <th className="px-4 py-2">금액</th>
              <th className="px-4 py-2">집행일</th>
              <th className="px-4 py-2">기부처</th>
              <th className="px-4 py-2">증빙</th>
            </tr>
          </thead>
          <tbody>
            {rows === null && (
              <tr><td className="px-4 py-3 text-gray-500" colSpan={5}>불러오는 중</td></tr>
            )}
            {rows?.length === 0 && (
              <tr><td className="px-4 py-3 text-gray-500" colSpan={5}>아직 기록이 없습니다.</td></tr>
            )}
            {rows?.map((row) => (
              <tr key={row.month} className="border-t border-gray-700">
                <td className="px-4 py-2">{row.month}</td>
                <td className="px-4 py-2">{row.amountWon.toLocaleString()}원</td>
                <td className="px-4 py-2">{row.executedAt ? row.executedAt.slice(0, 10) : '-'}</td>
                <td className="px-4 py-2">{row.partnerName}</td>
                <td className="px-4 py-2 text-gray-400">{row.receiptImagePath ? '있음' : '-'}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}

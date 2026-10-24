import { useEffect, useState } from 'react';
import { ScrollText } from 'lucide-react';
import { subscribeAuditLogs, type AdminAuditLog } from '../../lib/firestoreOps';

function formatWhen(iso: string): string {
  if (!iso) return '-';
  const date = new Date(iso);
  return Number.isNaN(date.getTime()) ? '-' : date.toLocaleString('ko-KR');
}

export default function AuditLogs() {
  const [logs, setLogs] = useState<AdminAuditLog[] | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    return subscribeAuditLogs({
      onData: (rows) => {
        setLogs(rows);
        setError(null);
      },
      onError: (err) => {
        setError(err.message);
        setLogs([]);
      },
    });
  }, []);

  return (
    <div className="p-6 text-white h-full overflow-y-auto space-y-4">
      <div>
        <h2 className="text-2xl font-bold tracking-tight flex items-center gap-2">
          <ScrollText size={22} className="text-emerald-400" />
          감사 로그
        </h2>
        <p className="text-sm text-gray-400 mt-1">
          관리자 작업 기록 최근 100건입니다. 서버만 쓰고 이 화면에서는 바꾸지 않습니다.
        </p>
        {error && <p className="text-xs text-amber-400 mt-1">Firestore: {error}</p>}
      </div>

      <div className="bg-gray-800 rounded-xl border border-gray-700 overflow-x-auto">
        <table className="w-full text-left text-sm text-gray-300">
          <thead className="text-xs uppercase bg-gray-900/60 text-gray-400 border-b border-gray-700">
            <tr>
              <th className="py-3 px-4">시각</th>
              <th className="py-3 px-4">관리자</th>
              <th className="py-3 px-4">액션</th>
              <th className="py-3 px-4">대상 uid</th>
              <th className="py-3 px-4">사유</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-700/50">
            {logs === null ? (
              <tr>
                <td colSpan={5} className="py-8 text-center text-gray-400">
                  불러오는 중...
                </td>
              </tr>
            ) : logs.length === 0 ? (
              <tr>
                <td colSpan={5} className="py-8 text-center text-gray-400">
                  기록이 없습니다.
                </td>
              </tr>
            ) : (
              logs.map((log) => (
                <tr key={log.id} className="hover:bg-gray-700/30">
                  <td className="py-2.5 px-4 whitespace-nowrap text-gray-400">
                    {formatWhen(log.createdAt)}
                  </td>
                  <td className="py-2.5 px-4">
                    <div className="text-white">{log.email || '-'}</div>
                    <div className="text-xs text-gray-500">{log.uid}</div>
                  </td>
                  <td className="py-2.5 px-4 font-mono text-emerald-300">{log.action || '-'}</td>
                  <td className="py-2.5 px-4 text-xs">{log.targetUid || '-'}</td>
                  <td className="py-2.5 px-4 text-gray-400 max-w-xs truncate" title={log.reason}>
                    {log.reason || '-'}
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}

import { useEffect, useState } from 'react';
import { Settings } from 'lucide-react';
import { ensureAdminAuth } from '../../lib/adminAuth';
import { fetchConfigDocuments, type AdminConfigDocument } from '../../lib/jenaApi';

export default function ConfigView() {
  const [docs, setDocs] = useState<AdminConfigDocument[] | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;
    void (async () => {
      try {
        const user = await ensureAdminAuth();
        if (!user) {
          if (!cancelled) setError('로그인 필요');
          return;
        }
        const next = await fetchConfigDocuments(await user.getIdToken());
        if (!cancelled) setDocs(next);
      } catch (err) {
        if (cancelled) return;
        setError(
          err instanceof Error && err.message === 'forbidden'
            ? '권한 없음'
            : 'Jena 서버에 연결하지 못했습니다. 잠시 뒤 다시 시도하세요.'
        );
      }
    })();
    return () => {
      cancelled = true;
    };
  }, []);

  return (
    <div className="p-6 text-white h-full overflow-y-auto space-y-4 pb-32">
      <div>
        <h2 className="text-2xl font-bold tracking-tight flex items-center gap-2">
          <Settings size={22} className="text-emerald-400" />
          설정 값 (조회 전용)
        </h2>
        <p className="text-sm text-gray-400 mt-1">
          가격·추천인·프로모션 같은 운영 설정이 지금 어떤 값인지 봅니다. 값은 이 화면에서 바꾸지 않습니다.
          열람은 감사 로그에 남습니다.
        </p>
        {error && <p className="text-xs text-amber-400 mt-2">{error}</p>}
      </div>
      {!docs && !error && <p className="text-sm text-gray-400">불러오는 중...</p>}
      {docs?.map((doc) => (
        <section key={doc.id} className="bg-gray-800 border border-gray-700 rounded-xl p-4">
          <h3 className="font-bold text-white">
            {doc.title} <span className="text-xs text-gray-500 font-normal">config/{doc.id}</span>
          </h3>
          {doc.exists ? (
            <pre className="mt-3 text-xs text-gray-300 bg-gray-900 rounded-lg p-3 overflow-x-auto">
              {JSON.stringify(doc.data, null, 2)}
            </pre>
          ) : (
            <p className="mt-2 text-sm text-gray-500">문서가 없습니다. 서버의 기본값이 쓰입니다.</p>
          )}
        </section>
      ))}
    </div>
  );
}

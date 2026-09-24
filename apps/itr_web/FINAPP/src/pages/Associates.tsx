import { useEffect, useState } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import { associatesApi, getErrorMessage } from '../services/api';

const Associates = () => {
  const navigate = useNavigate();
  const [params] = useSearchParams();
  const serviceId = params.get('serviceId') || '';
  const [associates, setAssociates] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    setLoading(true);
    associatesApi
      .list(serviceId ? { serviceId } : undefined)
      .then((res) => {
        const list = res?.data?.associates || res?.associates || [];
        setAssociates(Array.isArray(list) ? list : []);
      })
      .catch((err) => setError(getErrorMessage(err)))
      .finally(() => setLoading(false));
  }, [serviceId]);

  const feeFor = (associate: any) => {
    const fees = associate.services || [];
    const match = serviceId
      ? fees.find((f: any) => String(f.service_id) === String(serviceId))
      : fees[0];
    return match?.listed_fee;
  };

  return (
    <div className="min-h-screen bg-gray-950 py-8 px-4">
      <div className="max-w-6xl mx-auto">
        <div className="mb-8">
          <button className="text-gray-400 hover:text-white mb-4" onClick={() => navigate('/services')}>
            ← Services
          </button>
          <h1 className="text-4xl font-bold text-white mb-2">Choose your associate</h1>
          <p className="text-gray-400">You pay this associate’s listed fee, plus GST and filing charges.</p>
        </div>
        {error && <div className="mb-6 p-4 bg-red-900 border border-red-700 text-red-100 rounded">{error}</div>}
        {loading ? (
          <p className="text-gray-400">Loading associates…</p>
        ) : associates.length === 0 ? (
          <p className="text-gray-400">No approved associates for this service yet.</p>
        ) : (
          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
            {associates.map((associate) => (
              <button
                key={associate.user_id || associate.id}
                onClick={() =>
                  navigate(
                    `/associates/${associate.user_id || associate.id}${serviceId ? `?serviceId=${serviceId}` : ''}`
                  )
                }
                className="text-left bg-gray-900 rounded-lg border border-gray-800 p-6 hover:border-blue-500 transition"
              >
                <h2 className="text-xl font-bold text-white">{associate.name}</h2>
                <p className="text-blue-300 text-sm mt-1">{associate.role}</p>
                <p className="text-gray-400 text-sm mt-2">
                  {associate.city || 'India'}
                  {associate.years_experience ? ` · ${associate.years_experience} yrs` : ''}
                </p>
                {feeFor(associate) != null && (
                  <p className="text-white text-2xl font-bold mt-4">₹{feeFor(associate)}</p>
                )}
                <span className="inline-block mt-3 text-blue-400 text-sm">View profile →</span>
              </button>
            ))}
          </div>
        )}
      </div>
    </div>
  );
};

export default Associates;

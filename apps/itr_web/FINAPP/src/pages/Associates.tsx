import { useEffect, useState } from 'react';
import { Link, useSearchParams } from 'react-router-dom';
import { associatesApi, getErrorMessage } from '../services/api';

const Associates = () => {
  const [searchParams] = useSearchParams();
  const serviceId = searchParams.get('serviceId') || '';
  const [associates, setAssociates] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const load = async () => {
      setLoading(true);
      try {
        const res = await associatesApi.list(serviceId ? { serviceId } : undefined);
        setAssociates(res?.data?.associates || []);
      } catch (err) {
        setError(getErrorMessage(err));
      } finally {
        setLoading(false);
      }
    };
    load();
  }, [serviceId]);

  return (
    <main className="min-h-screen bg-gray-950 py-12 px-4">
      <div className="max-w-5xl mx-auto">
        <Link to="/services" className="text-sm text-gray-400 hover:text-white">
          ← Services
        </Link>
        <h1 className="text-4xl font-bold text-white mt-4 mb-3">Verified associates</h1>
        <p className="text-gray-400 mb-10">Only admin-approved professionals are listed here.</p>

        {loading && <p className="text-gray-400">Loading associates…</p>}
        {error && <p className="text-red-400">{error}</p>}
        {!loading && associates.length === 0 && (
          <p className="text-gray-400">No associates are listed for this service yet.</p>
        )}

        <div className="grid gap-5 sm:grid-cols-2">
          {associates.map((associate) => (
            <Link
              key={associate.id}
              to={`/associates/${associate.id}${serviceId ? `?serviceId=${serviceId}` : ''}`}
              className="rounded-2xl border border-gray-800 bg-gray-900 p-6 hover:border-white transition"
            >
              <div className="flex items-start justify-between gap-3">
                <div>
                  <h2 className="text-xl font-semibold text-white">{associate.name}</h2>
                  <p className="text-sm text-gray-400 mt-1">
                    {associate.role} · {associate.yearsExperience || 0} yrs · {associate.city || 'India'}
                  </p>
                </div>
                {associate.listedFee != null && (
                  <p className="text-lg font-bold text-white">₹{associate.listedFee}</p>
                )}
              </div>
              {associate.bio && (
                <p className="mt-3 text-sm text-gray-400 line-clamp-2">{associate.bio}</p>
              )}
            </Link>
          ))}
        </div>
      </div>
    </main>
  );
};

export default Associates;

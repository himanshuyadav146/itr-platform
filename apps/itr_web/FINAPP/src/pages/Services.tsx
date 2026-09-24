import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { associatesApi, getErrorMessage } from '../services/api';

const Services = () => {
  const navigate = useNavigate();
  const [services, setServices] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    associatesApi
      .getServices()
      .then((res) => {
        const list = res?.data?.services || res?.services || [];
        setServices(Array.isArray(list) ? list : []);
      })
      .catch((err) => setError(getErrorMessage(err)))
      .finally(() => setLoading(false));
  }, []);

  return (
    <div className="min-h-screen bg-gray-950 py-8 px-4">
      <div className="max-w-6xl mx-auto">
        <div className="text-center mb-12">
          <h1 className="text-4xl font-bold text-white mb-3">Choose a service</h1>
          <p className="text-gray-400">Pick what you need, then book a named associate at their listed fee.</p>
        </div>
        {error && <div className="mb-6 p-4 bg-red-900 border border-red-700 text-red-100 rounded">{error}</div>}
        {loading ? (
          <p className="text-center text-gray-400">Loading services…</p>
        ) : (
          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
            {services.map((service) => (
              <button
                key={service.id}
                onClick={() => navigate(`/associates?serviceId=${service.id}`)}
                className="text-left bg-gray-900 rounded-lg border border-gray-800 p-6 hover:border-blue-500 transition"
              >
                <h2 className="text-xl font-bold text-white mb-2">{service.name}</h2>
                <p className="text-gray-400 text-sm">{service.description || 'File with a listed associate.'}</p>
                <span className="inline-block mt-4 text-blue-400 text-sm font-medium">View associates →</span>
              </button>
            ))}
            {services.length === 0 && (
              <p className="text-gray-400 col-span-full text-center">No services listed yet.</p>
            )}
          </div>
        )}
      </div>
    </div>
  );
};

export default Services;

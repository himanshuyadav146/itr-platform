import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { associatesApi, getErrorMessage } from '../services/api';

const Services = () => {
  const navigate = useNavigate();
  const [services, setServices] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const load = async () => {
      try {
        const res = await associatesApi.getServices();
        setServices(res?.data?.services || res?.services || []);
      } catch (err) {
        setError(getErrorMessage(err));
      } finally {
        setLoading(false);
      }
    };
    load();
  }, []);

  return (
    <main className="min-h-screen bg-gray-950 py-12 px-4">
      <div className="max-w-5xl mx-auto">
        <h1 className="text-4xl font-bold text-white mb-3">Choose a service</h1>
        <p className="text-gray-400 mb-10">
          Then pick a verified associate and pay their listed fee.
        </p>

        {loading && <p className="text-gray-400">Loading services…</p>}
        {error && <p className="text-red-400">{error}</p>}

        <div className="grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
          {services.map((service) => (
            <button
              key={service.id}
              onClick={() => navigate(`/associates?serviceId=${service.id}`)}
              className="text-left rounded-2xl border border-gray-800 bg-gray-900 p-6 hover:border-white transition"
            >
              <h2 className="text-xl font-semibold text-white">{service.name}</h2>
              <p className="mt-2 text-sm text-gray-400">{service.description}</p>
              <span className="mt-4 inline-block text-sm text-white">Browse associates →</span>
            </button>
          ))}
        </div>
      </div>
    </main>
  );
};

export default Services;

import { useEffect, useMemo, useState } from 'react';
import { Link, useNavigate, useParams, useSearchParams } from 'react-router-dom';
import { useDispatch } from 'react-redux';
import { associatesApi, getErrorMessage } from '../services/api';
import { setSelectedAssociate, setSelectedPackage } from '../store/slices/authSlice';
import type { AppDispatch } from '../store/index';

const AssociateDetail = () => {
  const { id } = useParams();
  const [searchParams] = useSearchParams();
  const navigate = useNavigate();
  const dispatch = useDispatch<AppDispatch>();
  const preferredServiceId = Number(searchParams.get('serviceId') || 0);

  const [associate, setAssociate] = useState<any | null>(null);
  const [selectedServiceId, setSelectedServiceId] = useState<number>(preferredServiceId);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const load = async () => {
      if (!id) return;
      try {
        const res = await associatesApi.detail(id);
        const data = res?.data?.associate;
        setAssociate(data);
        const services = data?.services || [];
        if (!preferredServiceId && services.length) {
          setSelectedServiceId(services[0].serviceId);
        }
      } catch (err) {
        setError(getErrorMessage(err));
      } finally {
        setLoading(false);
      }
    };
    load();
  }, [id, preferredServiceId]);

  const selectedService = useMemo(() => {
    return (associate?.services || []).find((s: any) => s.serviceId === selectedServiceId) || null;
  }, [associate, selectedServiceId]);

  const handleSelect = () => {
    if (!associate || !selectedService) {
      setError('Select a service to continue');
      return;
    }
    dispatch(
      setSelectedAssociate({
        id: associate.id,
        name: associate.name,
        role: associate.role,
        city: associate.city,
        yearsExperience: associate.yearsExperience,
        bio: associate.bio,
        serviceId: selectedService.serviceId,
        serviceName: selectedService.serviceName,
        quotedFee: selectedService.fee,
      })
    );
    dispatch(setSelectedPackage(null));
    navigate('/personal-details');
  };

  return (
    <main className="min-h-screen bg-gray-950 py-12 px-4">
      <div className="max-w-3xl mx-auto">
        <Link to={`/associates${preferredServiceId ? `?serviceId=${preferredServiceId}` : ''}`} className="text-sm text-gray-400 hover:text-white">
          ← Associates
        </Link>

        {loading && <p className="text-gray-400 mt-8">Loading profile…</p>}
        {error && <p className="text-red-400 mt-8">{error}</p>}

        {associate && (
          <div className="mt-6 rounded-3xl border border-gray-800 bg-gray-900 p-8">
            <p className="text-sm text-gray-400 uppercase tracking-wide">{associate.role}</p>
            <h1 className="text-3xl font-bold text-white mt-1">{associate.name}</h1>
            <p className="text-gray-400 mt-2">
              {associate.yearsExperience || 0} years · {associate.city || 'India'}
              {associate.qualification ? ` · ${associate.qualification}` : ''}
            </p>
            {associate.bio && <p className="mt-6 text-gray-300 leading-relaxed">{associate.bio}</p>}

            <h2 className="mt-8 text-lg font-semibold text-white">Services and fees</h2>
            <div className="mt-4 space-y-3">
              {(associate.services || []).map((service: any) => (
                <label
                  key={service.serviceId}
                  className={`flex items-center justify-between gap-3 rounded-xl border p-4 cursor-pointer ${
                    selectedServiceId === service.serviceId ? 'border-white bg-gray-800' : 'border-gray-800'
                  }`}
                >
                  <div className="flex items-center gap-3">
                    <input
                      type="radio"
                      name="service"
                      checked={selectedServiceId === service.serviceId}
                      onChange={() => setSelectedServiceId(service.serviceId)}
                    />
                    <div>
                      <p className="text-white font-medium">{service.serviceName}</p>
                      {service.description && (
                        <p className="text-xs text-gray-400">{service.description}</p>
                      )}
                    </div>
                  </div>
                  <p className="text-white font-bold">₹{service.fee}</p>
                </label>
              ))}
            </div>

            <button
              onClick={handleSelect}
              className="mt-8 w-full rounded-xl bg-white px-4 py-3 text-sm font-semibold text-black hover:bg-gray-200"
            >
              Select associate
            </button>
          </div>
        )}
      </div>
    </main>
  );
};

export default AssociateDetail;

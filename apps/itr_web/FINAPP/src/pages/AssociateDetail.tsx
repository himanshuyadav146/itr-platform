import { useEffect, useState } from 'react';
import { useNavigate, useParams, useSearchParams } from 'react-router-dom';
import { useDispatch, useSelector } from 'react-redux';
import { associatesApi, getErrorMessage } from '../services/api';
import { setSelectedAssociate, setSelectedService } from '../store/slices/authSlice';
import type { AppDispatch, RootState } from '../store/index';

const AssociateDetail = () => {
  const { id } = useParams();
  const [params] = useSearchParams();
  const serviceId = params.get('serviceId');
  const navigate = useNavigate();
  const dispatch = useDispatch<AppDispatch>();
  const { isAuthenticated } = useSelector((state: RootState) => state.auth);
  const [associate, setAssociate] = useState<any | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!id) return;
    associatesApi
      .get(id)
      .then((res) => {
        setAssociate(res?.data?.associate || res?.associate || null);
      })
      .catch((err) => setError(getErrorMessage(err)))
      .finally(() => setLoading(false));
  }, [id]);

  const selectedFee = (associate?.services || []).find((f: any) =>
    serviceId ? String(f.service_id) === String(serviceId) : true
  ) || associate?.services?.[0];

  const book = () => {
    if (!associate || !selectedFee) return;
    dispatch(setSelectedAssociate(associate));
    dispatch(
      setSelectedService({
        id: selectedFee.service_id,
        name: selectedFee.service_name,
        listed_fee: selectedFee.listed_fee,
      })
    );
    localStorage.setItem('selectedAssociate', JSON.stringify(associate));
    localStorage.setItem(
      'selectedService',
      JSON.stringify({
        id: selectedFee.service_id,
        name: selectedFee.service_name,
        listed_fee: selectedFee.listed_fee,
      })
    );
    if (!isAuthenticated) {
      navigate('/login');
      return;
    }
    navigate('/personal-details');
  };

  return (
    <div className="min-h-screen bg-gray-950 py-8 px-4">
      <div className="max-w-3xl mx-auto">
        <button className="text-gray-400 hover:text-white mb-6" onClick={() => navigate(-1)}>
          ← Back
        </button>
        {loading && <p className="text-gray-400">Loading profile…</p>}
        {error && <div className="p-4 bg-red-900 border border-red-700 text-red-100 rounded">{error}</div>}
        {associate && (
          <div className="bg-gray-900 border border-gray-800 rounded-2xl p-8">
            <h1 className="text-3xl font-bold text-white">{associate.name}</h1>
            <p className="text-blue-300 mt-1">{associate.role}</p>
            <p className="text-gray-400 mt-2">
              {[associate.city, associate.state].filter(Boolean).join(', ') || 'India'}
              {associate.years_experience ? ` · ${associate.years_experience} years` : ''}
            </p>
            {associate.icai_membership_no && (
              <p className="text-gray-400 mt-1">ICAI: {associate.icai_membership_no}</p>
            )}
            <p className="text-gray-300 mt-6">{associate.bio || 'Experienced tax professional.'}</p>

            <div className="mt-8 border-t border-gray-800 pt-6">
              <h2 className="text-white font-semibold mb-3">Listed fees</h2>
              {(associate.services || []).map((fee: any) => (
                <div key={fee.service_id} className="flex justify-between text-gray-300 py-2">
                  <span>{fee.service_name}</span>
                  <span className="text-white font-bold">₹{fee.listed_fee}</span>
                </div>
              ))}
            </div>

            {selectedFee && (
              <div className="mt-8 flex items-center justify-between gap-4">
                <div>
                  <p className="text-gray-400 text-sm">{selectedFee.service_name}</p>
                  <p className="text-3xl font-bold text-white">₹{selectedFee.listed_fee}</p>
                  <p className="text-gray-500 text-xs mt-1">GST and additional filing fees apply at checkout.</p>
                </div>
                <button
                  onClick={book}
                  className="rounded-xl bg-blue-600 px-6 py-3 font-semibold text-white hover:bg-blue-500"
                >
                  Book this associate
                </button>
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  );
};

export default AssociateDetail;

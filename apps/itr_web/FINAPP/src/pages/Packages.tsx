import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useDispatch, useSelector } from 'react-redux';
import { packagesApi, getErrorMessage } from '../services/api';
import { setSelectedPackage } from '../store/slices/authSlice';
import type { RootState, AppDispatch } from '../store/index';

const Packages = () => {
  const navigate = useNavigate();
  const dispatch = useDispatch<AppDispatch>();
  const { selectedPackage } = useSelector((state: RootState) => state.auth);

  const [packages, setPackages] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    fetchPackages();
  }, []);

  const fetchPackages = async () => {
    try {
      setLoading(true);
      setError(null);
      console.log('[Packages.fetchPackages] Fetching packages...');
      const res = await packagesApi.getPackages();
      console.log('[Packages.fetchPackages] Response:', res);

      // Handle different response formats
      let packagesList = [];
      if (Array.isArray(res)) {
        packagesList = res;
      } else if (res?.data?.packages && Array.isArray(res.data.packages)) {
        // API returns { data: { packages: [...] } }
        packagesList = res.data.packages;
      } else if (res?.data && Array.isArray(res.data)) {
        packagesList = res.data;
      } else if (res?.packages && Array.isArray(res.packages)) {
        packagesList = res.packages;
      }

      console.log('[Packages.fetchPackages] Extracted packages:', packagesList);
      setPackages(packagesList);
    } catch (err) {
      console.error('[Packages.fetchPackages] Error:', err);
      setError(getErrorMessage(err));
    } finally {
      setLoading(false);
    }
  };

  const handleSelectPackage = (pkg: any) => {
    console.log('[Packages.handleSelectPackage] Selected package:', pkg);
    dispatch(setSelectedPackage(pkg));
    navigate('/personal-details');
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-black py-12 px-4">
        <div className="max-w-6xl mx-auto">
          <div className="text-center py-12">
            <p className="text-gray-300">Loading packages...</p>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-950 py-8 px-4">
      <div className="max-w-6xl mx-auto">
        {/* Header */}
        <div className="text-center mb-12">
          <h1 className="text-5xl font-bold text-white mb-4">
            Choose Your ITR Filing Package
          </h1>
          <p className="text-lg text-gray-400">
            Select a package that fits your needs and get started with your ITR filing
          </p>
        </div>

        {/* Error Message */}
        {error && (
          <div className="mb-8 p-4 bg-red-900 border border-red-700 text-red-100 rounded">
            {error}
          </div>
        )}

        {/* Packages Grid */}
        {packages.length === 0 ? (
          <div className="text-center py-12">
            <p className="text-gray-400">No packages available at the moment</p>
            <button
              onClick={fetchPackages}
              className="mt-4 px-6 py-2 bg-gray-800 text-white rounded hover:bg-gray-700 border border-gray-600 transition"
            >
              Try Again
            </button>
          </div>
        ) : (
          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-8">
            {packages.map((pkg, idx) => (
              <div
                key={idx}
                className="bg-gray-900 rounded-lg border border-gray-800 overflow-hidden hover:border-gray-600 transition-all duration-300 hover:shadow-2xl hover:shadow-gray-900"
              >
                {/* Package Header */}
                <div className="bg-gradient-to-r from-gray-900 to-black p-6 border-b border-gray-800">
                  <h2 className="text-2xl font-bold mb-2 text-white">{pkg.packagename || pkg.name || pkg.packageName || `Package ${idx + 1}`}</h2>
                  <p className="text-gray-400 text-sm">{pkg.description1 ? pkg.description1.replace(/<[^>]*>/g, '').substring(0, 100) : (pkg.description || '')}</p>
                </div>

                {/* Package Content */}
                <div className="p-6">
                  {/* Price */}
                  <div className="mb-6">
                    <div className="text-4xl font-bold text-white">
                      ₹{parseFloat(pkg.price) || pkg.cost || '0'}
                    </div>
                    {pkg.originalPrice && (
                      <div className="text-sm text-gray-500 line-through">
                        ₹{pkg.originalPrice}
                      </div>
                    )}
                    {pkg.turnover && (
                      <div className="text-xs text-gray-400 mt-1">
                        Turnover: {pkg.turnover}
                      </div>
                    )}
                  </div>

                  {/* Features */}
                  <div className="mb-6 space-y-3">
                    {pkg.features && Array.isArray(pkg.features) ? (
                      pkg.features.map((feature: any, fidx: number) => (
                        <div key={fidx} className="flex items-start gap-2">
                          <span className="text-gray-400 mt-1">→</span>
                          <span className="text-gray-300 text-sm">
                            {typeof feature === 'string' ? feature : feature.name || feature.feature}
                          </span>
                        </div>
                      ))
                    ) : pkg.description1 ? (
                      <div className="text-gray-300 text-sm space-y-2">
                        {/* Extract list items from HTML */}
                        <div dangerouslySetInnerHTML={{ 
                          __html: pkg.description1.substring(0, 300) 
                        }} />
                      </div>
                    ) : (
                      <p className="text-gray-400 text-sm">No features listed</p>
                    )}
                  </div>

                  {/* Select Button */}
                  <button
                    onClick={() => handleSelectPackage(pkg)}
                    className={`w-full py-3 px-4 rounded font-medium transition-all duration-300 ${
                      selectedPackage?.id === pkg.id || selectedPackage?.name === pkg.packagename || selectedPackage?.name === pkg.name || selectedPackage?.packageName === pkg.packagename
                        ? 'bg-white text-black hover:bg-gray-200 border border-white'
                        : 'bg-gray-800 text-white hover:bg-gray-700 border border-gray-600'
                    }`}
                  >
                    {selectedPackage?.id === pkg.id || selectedPackage?.name === pkg.packagename || selectedPackage?.name === pkg.name || selectedPackage?.packageName === pkg.packagename
                      ? '✓ Selected'
                      : 'Select Package'}
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}

        {/* Back Button */}
        <div className="text-center mt-12">
          <button
            onClick={() => navigate('/')}
            className="px-6 py-2 text-gray-400 hover:text-white transition duration-300"
          >
            ← Back to Home
          </button>
        </div>
      </div>
    </div>
  );
};

export default Packages;

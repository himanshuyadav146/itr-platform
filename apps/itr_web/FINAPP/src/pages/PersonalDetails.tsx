import { useState, useEffect, useCallback } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import { useSelector } from 'react-redux';
import { itrDetailsApi, getErrorMessage } from '../services/api';
import type { RootState } from '../store/index';

const PersonalDetails = () => {
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const { user, selectedPackage, selectedAssociate, selectedService, isAuthenticated, token } = useSelector(
    (state: RootState) => state.auth
  );

  const [formData, setFormData] = useState({
    panNumber: '',
    firstName: '',
    middleName: '',
    lastName: '',
    email: '',
    mobileNumber: '',
    aadhaarCardNumber: '',
    gender: '',
    financialYear: '',
    address: '',
    country: 'India',
  });

  const [loading, setLoading] = useState(false);
  const [fetching, setFetching] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);

  // ─── Auth Guard ──────────────────────────────────────────────────────────
  useEffect(() => {
    const storedToken = localStorage.getItem('authToken');
    if (!isAuthenticated && !token && !storedToken) {
      navigate('/login', { replace: true });
    }
  }, [isAuthenticated, token, navigate]);

  // ─── Resolve PAN number from available sources ──────────────────────────
  const resolvePanNumber = useCallback((): string | null => {
    // 1. From URL query param (e.g. /personal-details?PanNumber=ABCDE1234F)
    const panFromUrl = searchParams.get('PanNumber') || searchParams.get('panNumber');
    if (panFromUrl) return panFromUrl;

    // 2. From the user object in Redux
    if (user?.PanNumber) return user.PanNumber;
    if (user?.pan) return user.pan;

    // 3. From localStorage (previously saved by dashboard)
    try {
      const saved = localStorage.getItem('selectedPersonalDetails');
      if (saved) {
        const details = JSON.parse(saved);
        return details.PANNumber || details.PanNumber || details.panNumber || null;
      }
    } catch { /* ignore */ }

    return null;
  }, [searchParams, user]);

  // ─── Fetch personal details from API ────────────────────────────────────
  const fetchPersonalDetails = useCallback(async (panNumber: string) => {
    try {
      setFetching(true);
      setError(null);
      console.log('[PersonalDetails] Fetching from API for PAN:', panNumber);

      // Get userId for the API call
      const userId = (user as any)?.id || (user as any)?.userId || (user as any)?.UserId
        || localStorage.getItem('userId')?.replace(/^"|"$/g, '').trim()
        || undefined;

      const res = await itrDetailsApi.getPersonalDetails(panNumber, userId);
      console.log('[PersonalDetails] API Response:', res);

      // Extract details from various response formats
      let details: any = null;
      if (res?.data?.personal_details) {
        // { data: { personal_details: {...} } }
        details = Array.isArray(res.data.personal_details)
          ? res.data.personal_details[0]
          : res.data.personal_details;
      } else if (res?.data?.personalDetails) {
        details = Array.isArray(res.data.personalDetails)
          ? res.data.personalDetails[0]
          : res.data.personalDetails;
      } else if (res?.data && typeof res.data === 'object' && !Array.isArray(res.data)) {
        details = res.data;
      } else if (res?.personal_details) {
        details = Array.isArray(res.personal_details) ? res.personal_details[0] : res.personal_details;
      } else if (res?.personalDetails) {
        details = Array.isArray(res.personalDetails) ? res.personalDetails[0] : res.personalDetails;
      }

      if (details) {
        console.log('[PersonalDetails] Extracted details from API:', details);
        mapDetailsToForm(details);
      } else {
        console.log('[PersonalDetails] No details found in API response, pre-filling PAN');
        // No existing record, just pre-fill PAN
        setFormData(prev => ({ ...prev, panNumber }));
      }
    } catch (err: any) {
      console.warn('[PersonalDetails] API fetch error:', err);
      // Not a critical error — might be a new user with no saved details
      // Just pre-fill whatever we can
      setFormData(prev => ({
        ...prev,
        panNumber,
        email: user?.email || prev.email,
        mobileNumber: user?.mobile || prev.mobileNumber,
      }));
    } finally {
      setFetching(false);
    }
  }, [user]);

  // ─── Map API response fields to form ────────────────────────────────────
  const mapDetailsToForm = (details: any) => {
    setFormData({
      panNumber: details.PANNumber || details.PanNumber || details.panNumber || '',
      firstName: details.FirstName || details.firstName || '',
      middleName: details.MiddleName || details.middleName || '',
      lastName: details.LastName || details.lastName || '',
      email: details.EMAIL || details.Email || details.email || '',
      mobileNumber: details.MobileNumber || details.mobileNumber || details.mobile || '',
      aadhaarCardNumber: details.aadharCardNumber || details.AadharCardNumber || details.aadhaarCardNumber || '',
      gender: details.Gender || details.gender || '',
      financialYear: details.FinancialYear || details.financialYear || '',
      address: details.Address || details.address || '',
      country: details.Country || details.country || 'India',
    });
  };

  // ─── On mount: fetch from API ───────────────────────────────────────────
  useEffect(() => {
    const panNumber = resolvePanNumber();

    if (panNumber) {
      // Fetch fresh data from API
      fetchPersonalDetails(panNumber);
    } else {
      // No PAN — pre-fill from user object only
      console.log('[PersonalDetails] No PAN number found, pre-filling from user');
      setFormData(prev => ({
        ...prev,
        email: user?.email || '',
        mobileNumber: user?.mobile || '',
      }));
    }
  }, [resolvePanNumber, fetchPersonalDetails]);

  // Redirect to packages if no package selected
  useEffect(() => {
    if (!selectedPackage) {
      console.log('[PersonalDetails] No package selected, redirecting to packages');
      navigate('/services');
    }
  }, [selectedPackage, navigate]);

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement>) => {
    const { name, value } = e.target;
    setFormData(prev => ({ ...prev, [name]: value }));
  };

  const validate = (): string | null => {
    if (!formData.panNumber) return 'PAN Number is required';
    if (!/^[A-Z]{5}[0-9]{4}[A-Z]{1}$/i.test(formData.panNumber)) return 'Invalid PAN format (e.g. ABCDE1234F)';
    if (!formData.firstName) return 'First Name is required';
    if (!formData.email) return 'Email is required';
    if (!formData.mobileNumber) return 'Mobile Number is required';
    if (formData.aadhaarCardNumber && !/^\d{12}$/.test(formData.aadhaarCardNumber.replace(/\s/g, '')))
      return 'Aadhaar should be 12 digits';
    return null;
  };

  const handleSubmit = async (e?: React.FormEvent) => {
    e?.preventDefault();
    setError(null);
    setSuccess(null);
    const v = validate();
    if (v) { setError(v); return; }
    setLoading(true);
    try {
      const userId = (user as any)?.id || (user as any)?.userId || (user as any)?.UserId
        || localStorage.getItem('userId')?.replace(/^"|"$/g, '').trim()
        || undefined;

      const packageId =
        (selectedPackage as any)?.id ??
        (selectedPackage as any)?.packageId ??
        (selectedPackage as any)?.PackageId ??
        undefined;
      const associateId =
        (selectedAssociate as any)?.user_id ??
        (selectedAssociate as any)?.id ??
        undefined;
      const serviceId =
        (selectedService as any)?.id ??
        (selectedService as any)?.service_id ??
        undefined;

      const payload = {
        panNumber: formData.panNumber,
        firstName: formData.firstName,
        middleName: formData.middleName,
        lastName: formData.lastName,
        email: formData.email,
        mobileNumber: formData.mobileNumber,
        aadhaarCardNumber: formData.aadhaarCardNumber,
        gender: formData.gender,
        financialYear: formData.financialYear,
        address: formData.address,
        country: formData.country,
        journeyType: 'ITR',
        ...(packageId != null ? { packageId: Number(packageId) || packageId } : {}),
        ...(associateId != null ? { associateId: Number(associateId) } : {}),
        ...(serviceId != null ? { serviceId: Number(serviceId) } : {}),
        ...(userId ? { userId } : {}),
      };
      console.log('[PersonalDetails] Submitting payload:', payload);
      const res = await itrDetailsApi.addPersonalDetails(payload);
      console.log('[PersonalDetails] add_personal_details response:', res);
      setSuccess('Details saved successfully!');

      // Clean up localStorage (no longer needed since we fetch from API)
      localStorage.removeItem('selectedPersonalDetails');

      // Navigate to documents upload page with PAN number
      const pan = payload.panNumber || res?.data?.PanNumber || res?.PanNumber || user?.PanNumber || user?.pan;
      if (pan) {
        setTimeout(() => navigate(`/documents?PanNumber=${encodeURIComponent(pan)}`), 800);
      } else {
        setTimeout(() => navigate('/dashboard'), 800);
      }
    } catch (err) {
      const msg = getErrorMessage(err);
      setError(msg);
      console.error('[PersonalDetails] Submit error:', err);
    } finally {
      setLoading(false);
    }
  };


  return (
    // <main className="min-h-screen bg-gray-950">
    //   {/* Header */}
    //   <div className="border-b border-gray-800 bg-gray-900/50 sticky top-0 z-40">
    //     <div className="max-w-7xl mx-auto px-6 py-4 flex items-center justify-between">
    //       <div>
    //         <h1 className="text-2xl font-bold text-white">Personal Details</h1>
    //         <p className="text-sm text-gray-400 mt-1">Step 1: Enter your personal information</p>
    //       </div>
    //       <button
    //         onClick={() => navigate('/dashboard')}
    //         className="text-gray-400 hover:text-white transition text-sm px-4 py-2"
    //       >
    //         ← Back
    //       </button>
    //     </div>
    //   </div>

    //   <div className="max-w-6xl mx-auto px-6 py-8">
    //     {/* Fetching indicator */}
    //     {fetching && (
    //       <div className="mb-6 p-4 bg-blue-950/30 border border-blue-900/40 rounded-lg flex items-center gap-3">
    //         <div className="animate-spin h-4 w-4 border-2 border-blue-400 border-t-transparent rounded-full"></div>
    //         <p className="text-sm text-blue-300">Loading your details from server...</p>
    //       </div>
    //     )}

    //     <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
    //       {/* Main Form - Left Side (2/3) */}
    //       <div className="lg:col-span-2">
    //         <div className="bg-gray-900/80 border border-gray-800 rounded-lg p-8">
    //           {error && (
    //             <div className="mb-6 p-4 bg-red-900/20 border border-red-800/50 rounded-lg flex items-start gap-3">
    //               <span className="text-red-400 mt-0.5">⚠</span>
    //               <p className="text-sm text-red-300">{error}</p>
    //             </div>
    //           )}
    //           {success && (
    //             <div className="mb-6 p-4 bg-green-900/20 border border-green-800/50 rounded-lg flex items-start gap-3">
    //               <span className="text-green-400 mt-0.5">✓</span>
    //               <p className="text-sm text-green-300">{success}</p>
    //             </div>
    //           )}

    //           <form onSubmit={handleSubmit} className="space-y-6">
    //             {/* Row 1: First Name, Middle Name, Last Name */}
    //             <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
    //               <div>
    //                 <label className="block text-xs font-medium text-gray-400 mb-2 uppercase tracking-wide">First Name *</label>
    //                 <input
    //                   name="firstName"
    //                   value={formData.firstName}
    //                   onChange={handleChange}
    //                   placeholder="John"
    //                   className="w-full border border-gray-700 bg-gray-800/50 text-white placeholder-gray-500 rounded-lg px-4 py-2.5 text-sm focus:outline-none focus:border-gray-500 focus:bg-gray-800/80 transition"
    //                 />
    //               </div>
    //               <div>
    //                 <label className="block text-xs font-medium text-gray-400 mb-2 uppercase tracking-wide">Middle Name</label>
    //                 <input
    //                   name="middleName"
    //                   value={formData.middleName}
    //                   onChange={handleChange}
    //                   placeholder="Optional"
    //                   className="w-full border border-gray-700 bg-gray-800/50 text-white placeholder-gray-500 rounded-lg px-4 py-2.5 text-sm focus:outline-none focus:border-gray-500 focus:bg-gray-800/80 transition"
    //                 />
    //               </div>
    //               <div>
    //                 <label className="block text-xs font-medium text-gray-400 mb-2 uppercase tracking-wide">Last Name</label>
    //                 <input
    //                   name="lastName"
    //                   value={formData.lastName}
    //                   onChange={handleChange}
    //                   placeholder="Doe"
    //                   className="w-full border border-gray-700 bg-gray-800/50 text-white placeholder-gray-500 rounded-lg px-4 py-2.5 text-sm focus:outline-none focus:border-gray-500 focus:bg-gray-800/80 transition"
    //                 />
    //               </div>
    //             </div>

    //             {/* Row 2: Mobile, Email */}
    //             <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
    //               <div>
    //                 <label className="block text-xs font-medium text-gray-400 mb-2 uppercase tracking-wide">Mobile Number *</label>
    //                 <input
    //                   name="mobileNumber"
    //                   value={formData.mobileNumber}
    //                   onChange={handleChange}
    //                   placeholder="+91 9876543210"
    //                   className="w-full border border-gray-700 bg-gray-800/50 text-white placeholder-gray-500 rounded-lg px-4 py-2.5 text-sm focus:outline-none focus:border-gray-500 focus:bg-gray-800/80 transition"
    //                 />
    //               </div>
    //               <div>
    //                 <label className="block text-xs font-medium text-gray-400 mb-2 uppercase tracking-wide">Email Address *</label>
    //                 <input
    //                   name="email"
    //                   type="email"
    //                   value={formData.email}
    //                   onChange={handleChange}
    //                   placeholder="john@example.com"
    //                   className="w-full border border-gray-700 bg-gray-800/50 text-white placeholder-gray-500 rounded-lg px-4 py-2.5 text-sm focus:outline-none focus:border-gray-500 focus:bg-gray-800/80 transition"
    //                 />
    //               </div>
    //             </div>

    //             {/* Row 3: PAN, Aadhaar */}
    //             <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
    //               <div>
    //                 <label className="block text-xs font-medium text-gray-400 mb-2 uppercase tracking-wide">PAN Number *</label>
    //                 <div className="flex gap-2">
    //                   <input
    //                     name="panNumber"
    //                     value={formData.panNumber}
    //                     onChange={handleChange}
    //                     placeholder="ABCDE1234F"
    //                     className="flex-1 border border-gray-700 bg-gray-800/50 text-white placeholder-gray-500 rounded-lg px-4 py-2.5 text-sm focus:outline-none focus:border-gray-500 focus:bg-gray-800/80 transition uppercase"
    //                   />
                      
    //                 </div>
    //               </div>
    //               <div>
    //                 <label className="block text-xs font-medium text-gray-400 mb-2 uppercase tracking-wide">Aadhaar Number</label>
    //                 <input
    //                   name="aadhaarCardNumber"
    //                   value={formData.aadhaarCardNumber}
    //                   onChange={handleChange}
    //                   placeholder="1234 5678 9012"
    //                   className="w-full border border-gray-700 bg-gray-800/50 text-white placeholder-gray-500 rounded-lg px-4 py-2.5 text-sm focus:outline-none focus:border-gray-500 focus:bg-gray-800/80 transition"
    //                 />
    //               </div>
    //             </div>

    //             {/* Row 4: Financial Year, Gender */}
    //             <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
    //               <div>
    //                 <label className="block text-xs font-medium text-gray-400 mb-2 uppercase tracking-wide">Financial Year</label>
    //                 <input
    //                   name="financialYear"
    //                   value={formData.financialYear}
    //                   onChange={handleChange}
    //                   placeholder="2025-26"
    //                   className="w-full border border-gray-700 bg-gray-800/50 text-white placeholder-gray-500 rounded-lg px-4 py-2.5 text-sm focus:outline-none focus:border-gray-500 focus:bg-gray-800/80 transition"
    //                 />
    //               </div>
    //               <div>
    //                 <label className="block text-xs font-medium text-gray-400 mb-2 uppercase tracking-wide">Gender</label>
    //                 <select
    //                   name="gender"
    //                   value={formData.gender}
    //                   onChange={handleChange}
    //                   className="w-full border border-gray-700 bg-gray-800/50 text-white rounded-lg px-4 py-2.5 text-sm focus:outline-none focus:border-gray-500 focus:bg-gray-800/80 transition"
    //                 >
    //                   <option value="">Select Gender</option>
    //                   <option value="Male">Male</option>
    //                   <option value="Female">Female</option>
    //                   <option value="Other">Other</option>
    //                 </select>
    //               </div>
    //             </div>

    //             {/* Address */}
    //             <div>
    //               <label className="block text-xs font-medium text-gray-400 mb-2 uppercase tracking-wide">Address</label>
    //               <textarea
    //                 name="address"
    //                 value={formData.address}
    //                 onChange={handleChange}
    //                 placeholder="Enter your full address..."
    //                 className="w-full border border-gray-700 bg-gray-800/50 text-white placeholder-gray-500 rounded-lg px-4 py-2.5 text-sm focus:outline-none focus:border-gray-500 focus:bg-gray-800/80 transition resize-none h-24"
    //               ></textarea>
    //             </div>

    //             {/* Action Buttons */}
    //             <div className="flex items-center gap-3 pt-4">
    //               <button
    //                 type="submit"
    //                 disabled={loading || fetching}
    //                 className="px-8 py-2.5 bg-white text-black text-sm font-semibold rounded-lg hover:bg-gray-100 disabled:bg-gray-600 disabled:cursor-not-allowed transition"
    //               >
    //                 {loading ? 'Saving...' : 'Save & Continue'}
    //               </button>
    //               <button
    //                 type="button"
    //                 onClick={() => navigate('/dashboard')}
    //                 className="px-6 py-2.5 bg-gray-800 text-gray-300 text-sm font-medium rounded-lg hover:bg-gray-700 transition"
    //               >
    //                 Cancel
    //               </button>
    //             </div>
    //           </form>
    //         </div>
    //       </div>

    //       {/* Sidebar - Package Info (1/3) */}
    //       {selectedPackage && (
    //         <div className="lg:col-span-1">
    //           <div className="sticky top-24 bg-gradient-to-b from-gray-900 to-gray-900/50 border border-gray-800 rounded-lg p-6 space-y-6">
    //             <div>
    //               <p className="text-xs font-medium text-gray-500 uppercase tracking-wide mb-2">Selected Package</p>
    //               <h3 className="text-lg font-bold text-white">{selectedPackage.packagename || selectedPackage.name || selectedPackage.packageName}</h3>
    //             </div>

    //             <div className="border-t border-gray-800 pt-6">
    //               <p className="text-xs font-medium text-gray-500 uppercase tracking-wide mb-2">Price</p>
    //               <p className="text-3xl font-bold text-white">₹{parseFloat(selectedPackage.price) || selectedPackage.cost || '0'}</p>
    //               <p className="text-xs text-gray-500 mt-2">All taxes included</p>
    //             </div>

    //             <div className="bg-gray-800/30 border border-gray-800 rounded-lg p-4">
    //               <p className="text-xs text-gray-400 text-center">
    //                 Complete your personal details to proceed to document upload
    //               </p>
    //             </div>

    //             <div className="border-t border-gray-800 pt-4">
    //               <p className="text-xs text-gray-500 mb-3">Steps</p>
    //               <div className="space-y-2">
    //                 <div className="flex items-center gap-3">
    //                   <span className="flex items-center justify-center w-6 h-6 rounded-full bg-white text-black text-xs font-bold">1</span>
    //                   <span className="text-sm text-gray-300">Personal Details</span>
    //                 </div>
    //                 <div className="flex items-center gap-3 opacity-50">
    //                   <span className="flex items-center justify-center w-6 h-6 rounded-full bg-gray-700 text-xs font-bold">2</span>
    //                   <span className="text-sm text-gray-400">Upload Documents</span>
    //                 </div>
    //                 <div className="flex items-center gap-3 opacity-50">
    //                   <span className="flex items-center justify-center w-6 h-6 rounded-full bg-gray-700 text-xs font-bold">3</span>
    //                   <span className="text-sm text-gray-400">Payment</span>
    //                 </div>
    //               </div>
    //             </div>
    //           </div>
    //         </div>
    //       )}
    //     </div>
    //   </div>
    // </main>
<div className="max-w-6xl mx-auto px-4 py-5">
  {/* Fetching indicator */}
  {fetching && (
    <div className="mb-4 p-3 bg-blue-950/30 border border-blue-900/40 rounded-lg flex items-center gap-3">
      <div className="animate-spin h-4 w-4 border-2 border-blue-400 border-t-transparent rounded-full" />
      <p className="text-sm text-blue-300">
        Loading your details from server...
      </p>
    </div>
  )}

  <div className="grid grid-cols-1 lg:grid-cols-3 gap-5">

    {/* Main Form */}
    <div className="lg:col-span-2">
      <div className="bg-gray-900/80 border border-gray-800 rounded-lg p-5">

        {/* Alerts */}
        {error && (
          <div className="mb-4 p-3 bg-red-900/20 border border-red-800/50 rounded-lg flex items-start gap-2">
            <span className="text-red-400 text-sm">⚠</span>
            <p className="text-sm text-red-300">{error}</p>
          </div>
        )}

        {success && (
          <div className="mb-4 p-3 bg-green-900/20 border border-green-800/50 rounded-lg flex items-start gap-2">
            <span className="text-green-400 text-sm">✓</span>
            <p className="text-sm text-green-300">{success}</p>
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-4">

          {/* Name */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
            <div>
              <label className="block text-xs font-medium text-gray-400 mb-1">
                First Name *
              </label>
              <input
                name="firstName"
                value={formData.firstName}
                onChange={handleChange}
                placeholder="John"
                className="w-full h-9 border border-gray-700 bg-gray-800/50 text-white placeholder-gray-500 rounded-md px-3 text-sm focus:outline-none focus:border-gray-500 focus:bg-gray-800/80 transition"
              />
            </div>

            <div>
              <label className="block text-xs font-medium text-gray-400 mb-1">
                Middle Name
              </label>
              <input
                name="middleName"
                value={formData.middleName}
                onChange={handleChange}
                placeholder="Optional"
                className="w-full h-9 border border-gray-700 bg-gray-800/50 text-white placeholder-gray-500 rounded-md px-3 text-sm focus:outline-none focus:border-gray-500 focus:bg-gray-800/80 transition"
              />
            </div>

            <div>
              <label className="block text-xs font-medium text-gray-400 mb-1">
                Last Name
              </label>
              <input
                name="lastName"
                value={formData.lastName}
                onChange={handleChange}
                placeholder="Doe"
                className="w-full h-9 border border-gray-700 bg-gray-800/50 text-white placeholder-gray-500 rounded-md px-3 text-sm focus:outline-none focus:border-gray-500 focus:bg-gray-800/80 transition"
              />
            </div>
          </div>

          {/* Mobile + Email */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
            <div>
              <label className="block text-xs font-medium text-gray-400 mb-1">
                Mobile Number *
              </label>
              <input
                name="mobileNumber"
                value={formData.mobileNumber}
                onChange={handleChange}
                placeholder="+91 9876543210"
                className="w-full h-9 border border-gray-700 bg-gray-800/50 text-white placeholder-gray-500 rounded-md px-3 text-sm focus:outline-none focus:border-gray-500 focus:bg-gray-800/80 transition"
              />
            </div>

            <div>
              <label className="block text-xs font-medium text-gray-400 mb-1">
                Email Address *
              </label>
              <input
                name="email"
                type="email"
                value={formData.email}
                onChange={handleChange}
                placeholder="john@example.com"
                className="w-full h-9 border border-gray-700 bg-gray-800/50 text-white placeholder-gray-500 rounded-md px-3 text-sm focus:outline-none focus:border-gray-500 focus:bg-gray-800/80 transition"
              />
            </div>
          </div>

          {/* PAN + Aadhaar */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
            <div>
              <label className="block text-xs font-medium text-gray-400 mb-1">
                PAN Number *
              </label>
              <input
                name="panNumber"
                value={formData.panNumber}
                onChange={handleChange}
                placeholder="ABCDE1234F"
                className="w-full h-9 border border-gray-700 bg-gray-800/50 text-white placeholder-gray-500 rounded-md px-3 text-sm focus:outline-none focus:border-gray-500 focus:bg-gray-800/80 transition uppercase"
              />
            </div>

            <div>
              <label className="block text-xs font-medium text-gray-400 mb-1">
                Aadhaar Number
              </label>
              <input
                name="aadhaarCardNumber"
                value={formData.aadhaarCardNumber}
                onChange={handleChange}
                placeholder="1234 5678 9012"
                className="w-full h-9 border border-gray-700 bg-gray-800/50 text-white placeholder-gray-500 rounded-md px-3 text-sm focus:outline-none focus:border-gray-500 focus:bg-gray-800/80 transition"
              />
            </div>
          </div>

          {/* Financial Year + Gender */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
            <div>
              <label className="block text-xs font-medium text-gray-400 mb-1">
                Financial Year
              </label>
              <input
                name="financialYear"
                value={formData.financialYear}
                onChange={handleChange}
                placeholder="2025-26"
                className="w-full h-9 border border-gray-700 bg-gray-800/50 text-white placeholder-gray-500 rounded-md px-3 text-sm focus:outline-none focus:border-gray-500 focus:bg-gray-800/80 transition"
              />
            </div>

            <div>
              <label className="block text-xs font-medium text-gray-400 mb-1">
                Gender
              </label>
              <select
                name="gender"
                value={formData.gender}
                onChange={handleChange}
                className="w-full h-9 border border-gray-700 bg-gray-800/50 text-white rounded-md px-3 text-sm focus:outline-none focus:border-gray-500 focus:bg-gray-800/80 transition"
              >
                <option value="">Select Gender</option>
                <option value="Male">Male</option>
                <option value="Female">Female</option>
                <option value="Other">Other</option>
              </select>
            </div>
          </div>

          {/* Address */}
          <div>
            <label className="block text-xs font-medium text-gray-400 mb-1">
              Address
            </label>
            <textarea
              name="address"
              value={formData.address}
              onChange={handleChange}
              placeholder="Enter your full address..."
              className="w-full border border-gray-700 bg-gray-800/50 text-white placeholder-gray-500 rounded-md px-3 py-2 text-sm focus:outline-none focus:border-gray-500 focus:bg-gray-800/80 transition resize-none h-20"
            />
          </div>

          {/* Actions */}
          <div className="flex items-center gap-2 pt-1">
            <button
              type="submit"
              disabled={loading || fetching}
              className="h-9 px-6 bg-white text-black text-sm font-semibold rounded-md hover:bg-gray-100 disabled:bg-gray-600 disabled:cursor-not-allowed transition"
            >
              {loading ? "Saving..." : "Save & Continue"}
            </button>

            <button
              type="button"
              onClick={() => navigate("/dashboard")}
              className="h-9 px-5 bg-gray-800 text-gray-300 text-sm font-medium rounded-md hover:bg-gray-700 transition"
            >
              Cancel
            </button>
          </div>

        </form>
      </div>
    </div>

    {/* Sidebar */}
    {selectedPackage && (
      <div className="lg:col-span-1">
        <div className="sticky top-20 bg-gradient-to-b from-gray-900 to-gray-900/50 border border-gray-800 rounded-lg p-4 space-y-4">

          <div>
            <p className="text-[11px] font-medium text-gray-500 uppercase tracking-wide mb-1">
              Selected Package
            </p>
            <h3 className="text-base font-semibold text-white">
              {selectedPackage.packagename ||
                selectedPackage.name ||
                selectedPackage.packageName}
            </h3>
          </div>

          <div className="border-t border-gray-800 pt-4">
            <p className="text-[11px] font-medium text-gray-500 uppercase tracking-wide mb-1">
              Price
            </p>
            <p className="text-2xl font-bold text-white">
              ₹{parseFloat(selectedPackage.price) ||
                selectedPackage.cost ||
                "0"}
            </p>
            <p className="text-[11px] text-gray-500 mt-1">
              All taxes included
            </p>
          </div>

          <div className="bg-gray-800/30 border border-gray-800 rounded-md p-3">
            <p className="text-xs text-gray-400 text-center leading-4">
              Complete your personal details to proceed to document upload
            </p>
          </div>

          <div className="border-t border-gray-800 pt-3">
            <p className="text-[11px] text-gray-500 mb-2">
              Steps
            </p>

            <div className="space-y-2">
              <div className="flex items-center gap-2">
                <span className="flex items-center justify-center w-5 h-5 rounded-full bg-white text-black text-[10px] font-bold">
                  1
                </span>
                <span className="text-xs text-gray-300">
                  Personal Details
                </span>
              </div>

              <div className="flex items-center gap-2 opacity-50">
                <span className="flex items-center justify-center w-5 h-5 rounded-full bg-gray-700 text-[10px] font-bold">
                  2
                </span>
                <span className="text-xs text-gray-400">
                  Upload Documents
                </span>
              </div>

              <div className="flex items-center gap-2 opacity-50">
                <span className="flex items-center justify-center w-5 h-5 rounded-full bg-gray-700 text-[10px] font-bold">
                  3
                </span>
                <span className="text-xs text-gray-400">
                  Payment
                </span>
              </div>
            </div>
          </div>

        </div>
      </div>
    )}

  </div>
</div>
  );
};

export default PersonalDetails;

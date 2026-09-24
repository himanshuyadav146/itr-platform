import { useEffect, useState } from 'react';
import { useSelector } from 'react-redux';
import { useNavigate } from 'react-router-dom';
import { itrApi, getErrorMessage } from '../services/api';
import type { RootState } from '../store/index';

// Helper: return user object stored in localStorage or null
const getStoredUser = (): any | null => {
    try {
        const s = localStorage.getItem('user');
        return s ? JSON.parse(s) : null;
    } catch (e) {
        console.warn('Failed to parse stored user', e);
        return null;
    }
};

// Helper: normalize and return userId from Redux user or stored user
const getUserId = (reduxUser: any): string | null => {
    const stored = getStoredUser();
    const u = reduxUser ?? stored;
    
    // First, try to get userId from user object
    if (u) {
        // Try common variants in user object
        const id = u.id ?? u.userId ?? u.UserId ?? u.UserID ?? u.user_id ?? u.ID ?? null;
        if (id) {
            let idStr = String(id).trim();
            // Remove JSON quotes if they exist (e.g., "23" -> 23)
            if (idStr.startsWith('"') && idStr.endsWith('"')) {
                idStr = idStr.slice(1, -1).trim();
            }
            if (idStr && idStr !== 'undefined' && idStr !== 'null') {
                return idStr;
            }
        }
    }
    
    // If not found in user object, check localStorage for direct userId entries
    let localUserId = (
        localStorage.getItem('userId') ??
        localStorage.getItem('user_id') ??
        localStorage.getItem('userID') ??
        localStorage.getItem('UserID') ??
        localStorage.getItem('id')
    );
    
    if (localUserId) {
        localUserId = localUserId.trim();
        // Remove JSON quotes if they exist (e.g., "23" -> 23)
        if (localUserId.startsWith('"') && localUserId.endsWith('"')) {
            localUserId = localUserId.slice(1, -1).trim();
        }
        if (localUserId) {
            return localUserId;
        }
    }
    
    // Log all available keys for debugging
    console.log('[Dashboard.getUserId] Available localStorage keys:', 
        Object.keys(localStorage).filter(k => k.toLowerCase().includes('user') || k.toLowerCase().includes('id')));
    
    return null;
};

const Dashboard = () => {
    const { user, token, isAuthenticated } = useSelector((state: RootState) => state.auth);
    const [itrs, setItrs] = useState<any[] | null>(null);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState<string | null>(null);
    const navigate = useNavigate();

    useEffect(() => {
        const fetchItrs = async () => {
            try {
                // Get userId from Redux, localStorage, or stored user
                let userId = getUserId(user);
                const storedToken = localStorage.getItem('authToken');
                const isAuth = isAuthenticated || !!storedToken;

                const debugData = {
                    reduxUser: user ? { id: (user as any).id, email: (user as any).email, UserId: (user as any).UserId } : null,
                    userId,
                    isAuthenticated,
                    hasReduxToken: !!token,
                    hasStoredToken: !!storedToken,
                    timestamp: new Date().toISOString()
                };

                console.log('[Dashboard] Init Debug:', debugData);

                // If not authenticated and no token, redirect to login
                if (!isAuth) {
                    console.warn('[Dashboard] Not authenticated, redirecting to login');
                    navigate('/login');
                    return;
                }

                // If no userId found, show error
                if (!userId) {
                    console.error('[Dashboard] No userId available');
                    setError('User ID not found. Please log in again.');
                    setItrs([]);
                    return;
                }

                setLoading(true);
                setError(null);

                console.log('[Dashboard] Fetching ITRs for userId:', userId);
                console.log('[Dashboard] Request URL: get_itrbyuser.php?userId=' + userId);
                
                // Make the API call
                const res = await itrApi.getByUser(String(userId));
                console.log('[Dashboard] Raw API Response:', res);
                
                // Backend response structure:
                // {
                //   statusCode: 200,
                //   status: "success",
                //   data: {
                //     personalDetails: [...]  <- This is what we need
                //   }
                // }
                
                let finalData: any[] = [];
                
                // Handle the backend response format
                if (res?.data?.personalDetails && Array.isArray(res.data.personalDetails)) {
                    finalData = res.data.personalDetails;
                    console.log('[Dashboard] Extracted personalDetails:', finalData.length, 'items');
                } else if (res?.personalDetails && Array.isArray(res.personalDetails)) {
                    // Alternative format
                    finalData = res.personalDetails;
                } else if (res?.data && Array.isArray(res.data)) {
                    // If data is directly an array
                    finalData = res.data;
                } else if (Array.isArray(res)) {
                    // If response is directly an array
                    finalData = res;
                }
                
                console.log('[Dashboard] Final ITRs Count:', finalData.length);
                console.log('[Dashboard] Processed ITRs:', finalData);
                setItrs(finalData);
            } catch (err: any) {
                const msg = getErrorMessage(err);
                console.error('[Dashboard] Error fetching ITRs:', {
                    message: msg,
                    status: err?.status,
                    error: err
                });
                setError(msg);
                setItrs([]);
            } finally {
                setLoading(false);
            }
        };

        fetchItrs();
    }, [user, token, isAuthenticated, navigate]);

    return (
        <main className="min-h-screen bg-gray-950">
            {/* Header */}
            <div className="border-b border-gray-800 bg-gray-900/50 sticky top-0 z-40">
                <div className="max-w-7xl mx-auto px-6 py-6 flex items-center justify-between">
                    <div>
                        <h1 className="text-3xl font-bold text-white">Dashboard</h1>
                        <p className="text-sm text-gray-400 mt-1">View and manage your ITR filings</p>
                    </div>
                    <button
                        onClick={() => navigate('/services')}
                        className="px-6 py-2.5 bg-white text-black text-sm font-semibold rounded-lg hover:bg-gray-100 transition-colors"
                    >
                        + File New ITR
                    </button>
                </div>
            </div>

            <div className="max-w-7xl mx-auto px-6 py-8">

                {loading && (
                    <div className="text-center py-20">
                        <div className="inline-block">
                            <div className="animate-spin h-10 w-10 border-4 border-gray-600 border-t-white rounded-full mb-4"></div>
                            <p className="text-gray-400 text-sm">Loading your ITR filings...</p>
                        </div>
                    </div>
                )}

                {error && (
                    <div className="mb-6 p-4 bg-red-900/20 border border-red-800/50 rounded-lg flex items-start gap-3">
                        <span className="text-red-400 mt-0.5 text-lg">⚠</span>
                        <div>
                            <p className="text-sm font-medium text-red-300">{error}</p>
                            <p className="text-xs text-red-400 mt-1">Check browser console (F12) for detailed logs</p>
                        </div>
                    </div>
                )}

                {!loading && !error && (
                    <div>
                        {itrs && itrs.length > 0 ? (
                            <div>
                                <div className="mb-6">
                                    <h2 className="text-sm font-semibold text-gray-400 uppercase tracking-wide">Your ITR Filings</h2>
                                </div>
                                <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
                                    {itrs.map((item, idx) => (
                                        <div
                                            key={item.id ?? idx}
                                            className="group bg-gray-900/80 border border-gray-800 rounded-lg p-6 hover:border-gray-700 hover:bg-gray-900 transition-all"
                                        >
                                            {/* Header with PAN and Status */}
                                            <div className="flex items-start justify-between mb-4 pb-4 border-b border-gray-800">
                                                <div className="flex-1">
                                                    <p className="text-xs font-medium text-gray-500 uppercase tracking-wide mb-1">PAN Number</p>
                                                    <p className="text-xl font-bold text-white">{item.PANNumber || item.PanNumber || item.pan || 'N/A'}</p>
                                                </div>
                                                <span className="inline-flex items-center px-3 py-1 bg-green-900/30 border border-green-800/50 text-green-300 text-xs font-semibold rounded-full flex-shrink-0">
                                                    <span className="w-2 h-2 bg-green-400 rounded-full mr-2"></span>
                                                    {item.itrStatus || item.status || 'Filed'}
                                                </span>
                                            </div>

                                            {/* Details Grid */}
                                            <div className="space-y-4 mb-6">
                                                {/* Name */}
                                                <div className="flex items-center justify-between">
                                                    <p className="text-xs text-gray-500 uppercase tracking-wide">Name</p>
                                                    <p className="text-sm font-semibold text-white">
                                                        {item.FirstName} {item.LastName}
                                                    </p>
                                                </div>
                                                
                                                {/* Financial Year */}
                                                {item.FinancialYear && (
                                                    <div className="flex items-center justify-between">
                                                        <p className="text-xs text-gray-500 uppercase tracking-wide">Financial Year</p>
                                                        <p className="text-sm font-semibold text-white">{item.FinancialYear}</p>
                                                    </div>
                                                )}
                                                
                                                {/* Email */}
                                                {item.EMAIL && (
                                                    <div className="flex items-center justify-between">
                                                        <p className="text-xs text-gray-500 uppercase tracking-wide">Email</p>
                                                        <p className="text-sm font-semibold text-white truncate">{item.EMAIL}</p>
                                                    </div>
                                                )}
                                                
                                                {/* Documents */}
                                                {item.documentCount && (
                                                    <div className="flex items-center justify-between">
                                                        <p className="text-xs text-gray-500 uppercase tracking-wide">Documents</p>
                                                        <p className="text-sm font-semibold text-white">{item.documentCount}</p>
                                                    </div>
                                                )}
                                            </div>

                                            {/* Filing Date */}
                                            {item.createdAt && (
                                                <div className="mb-6 pt-4 border-t border-gray-800">
                                                    <p className="text-xs text-gray-500">
                                                        Created on <span className="text-gray-300 font-medium">{new Date(item.createdAt).toLocaleDateString()}</span>
                                                    </p>
                                                </div>
                                            )}

                                            {/* Action Button */}
                                            <button
                                                onClick={() => {
                                                    const panNumber = item.PANNumber || item.PanNumber || item.pan;
                                                    
                                                    if (!panNumber) {
                                                        alert('PAN Number not found');
                                                        return;
                                                    }
                                                    
                                                    // Navigate with PAN as URL param — PersonalDetails page will fetch from API
                                                    navigate(`/personal-details?PanNumber=${encodeURIComponent(panNumber)}`);
                                                }}
                                                className="w-full py-2.5 px-4 bg-gray-800 text-white text-sm font-medium rounded-lg hover:bg-gray-700 group-hover:bg-white group-hover:text-black transition-colors"
                                            >
                                                View Details
                                            </button>
                                        </div>
                                    ))}
                                </div>
                            </div>
                        ) : (
                            <div className="text-center">
                                <div className="max-w-md mx-auto bg-gray-900/80 border border-gray-800 rounded-lg p-12">
                                    <div className="mb-4">
                                        <svg className="w-16 h-16 text-gray-600 mx-auto" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                                        </svg>
                                    </div>
                                    <h3 className="text-lg font-bold text-white mb-2">No ITR Filings Yet</h3>
                                    <p className="text-gray-400 text-sm mb-6">Start filing your income tax return today to get started</p>
                                    <button
                                        onClick={() => navigate('/services')}
                                        className="w-full px-6 py-3 bg-white text-black text-sm font-semibold rounded-lg hover:bg-gray-100 transition-colors"
                                    >
                                        File Your First ITR
                                    </button>
                                </div>
                            </div>
                        )}
                    </div>
                )}
            </div>
        </main>
    );
};

export default Dashboard;
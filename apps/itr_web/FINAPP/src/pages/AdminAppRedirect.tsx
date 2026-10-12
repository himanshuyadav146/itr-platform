import { useEffect, useMemo } from 'react';
import { getAdminUrl } from '../config/adminUrl';

/** Website has no /admin routes. Send associates to the admin Vite/app instead of a 404. */
const AdminAppRedirect = () => {
  const dest = useMemo(
    () => getAdminUrl(window.location.pathname + window.location.search + window.location.hash),
    []
  );

  useEffect(() => {
    const next = new URL(dest, window.location.href);
    if (next.origin !== window.location.origin) {
      window.location.replace(next.href);
    }
  }, [dest]);

  return (
    <main className="min-h-screen bg-gray-950 text-white flex items-center justify-center p-6">
      <div className="text-center space-y-3">
        <p className="text-gray-300">Associate login lives in the admin app.</p>
        <a href={dest} className="text-blue-400 hover:text-blue-300 underline">
          Continue to associate login
        </a>
      </div>
    </main>
  );
};

export default AdminAppRedirect;

import { useCallback, useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useDispatch, useSelector } from 'react-redux';
import { NAV_LINKS, CTA_LINK } from '../../utils/links';
import { logoutUser } from '../../store/slices/authSlice';
import type { AppDispatch, RootState } from '../../store/index';

const Header = () => {
  const [open, setOpen] = useState(false);
  const navigate = useNavigate();
  const dispatch = useDispatch<AppDispatch>();

  const { isAuthenticated, user, loading } = useSelector(
    (state: RootState) => state.auth
  );

  const toggleMenu = useCallback(() => {
    setOpen(prev => !prev);
  }, []);

  const closeMenu = useCallback(() => {
    setOpen(false);
  }, []);

  const handleLogout = async () => {
    try {
      await dispatch(logoutUser()).unwrap();
      closeMenu();
      localStorage.clear();
      navigate('/');
    } catch (error) {
      console.error('Logout failed:', error);
    }
  };

  return (
    <header className="sticky top-0 z-50 border-b border-gray-700 bg-gray-900">
      <div className="mx-auto max-w-[1280px] px-4 sm:px-6 lg:px-8">
        <div className="flex h-16 items-center justify-between">

          {/* LOGO */}
          <Link to="/" className="flex items-center gap-2">
            <img src="/public/logo.jpeg" alt="FinApp - Next Gen" className="ml-[32px]h-20 w-20" />
          </Link>

          {/* DESKTOP NAV */}
          <nav className="hidden items-center gap-6 md:flex">
            {NAV_LINKS.map(link => (
              <Link
                key={link.to}
                to={link.to}
                className="text-sm font-medium text-gray-400 hover:text-white transition-colors"
              >
                {link.label}
              </Link>
            ))}

            {/* AUTH SECTION */}
            {!loading && (
              isAuthenticated ? (
                <div className="flex items-center gap-4">
                  <Link
                    to="/dashboard"
                    className="text-sm font-medium text-gray-400 hover:text-white transition-colors"
                  >
                    Dashboard
                  </Link>
                  
                  <span className="text-sm font-medium text-gray-400">
                    {user?.name}
                  </span>

                  <button
                    onClick={handleLogout}
                    className="rounded-xl bg-red-900 px-4 py-2 text-sm
                               font-medium text-red-100 hover:bg-red-800
                               transition active:scale-95 border border-red-800"
                  >
                    Logout
                  </button>
                </div>
              ) : (
                <>
                  <Link
                    to="/login"
                    className="text-sm font-medium text-gray-400 hover:text-white transition-colors"
                  >
                    Login
                  </Link>

                  <Link
                    to={CTA_LINK.to}
                    className="rounded-xl bg-white px-4 py-2 text-sm
                               font-medium text-black hover:bg-gray-200
                               transition active:scale-95"
                  >
                    {CTA_LINK.label}
                  </Link>
                </>
              )
            )}
          </nav>

          {/* MOBILE TOGGLE */}
          <button
            aria-label="Toggle menu"
            onClick={toggleMenu}
            className="rounded-lg p-2 hover:bg-gray-900 md:hidden"
          >
            <svg
              className="h-6 w-6 text-gray-400"
              fill="none"
              stroke="currentColor"
              strokeWidth={2}
              viewBox="0 0 24 24"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                d={
                  open
                    ? 'M6 18L18 6M6 6l12 12'
                    : 'M4 6h16M4 12h16M4 18h16'
                }
              />
            </svg>
          </button>
        </div>

        {/* MOBILE MENU */}
        {open && (
          <div className="border-t border-gray-800 bg-gray-900 py-4 md:hidden">
            <nav className="flex flex-col gap-4">

              {NAV_LINKS.map(link => (
                <Link
                  key={link.to}
                  to={link.to}
                  onClick={closeMenu}
                  className="text-sm font-medium text-gray-400 hover:text-white transition-colors"
                >
                  {link.label}
                </Link>
              ))}

              {!loading && (
                isAuthenticated ? (
                  <div className="flex flex-col gap-3 border-t border-gray-800 pt-4">
                    <Link
                      to="/dashboard"
                      onClick={closeMenu}
                      className="text-sm font-medium text-gray-400 hover:text-white transition-colors"
                    >
                      Dashboard
                    </Link>

                    <span className="text-sm font-medium text-gray-400">
                      {user?.name}
                    </span>

                    <button
                      onClick={handleLogout}
                      className="rounded-xl bg-red-900 px-4 py-2 text-sm
                                 font-medium text-red-100 hover:bg-red-800 border border-red-800"
                    >
                      Logout
                    </button>
                  </div>
                ) : (
                  <div className="flex flex-col gap-3 border-t border-gray-800 pt-4">
                    <Link
                      to="/login"
                      onClick={closeMenu}
                      className="rounded-xl bg-gray-800 px-4 py-2 text-center
                                 text-sm font-medium text-white hover:bg-gray-700 border border-gray-700"
                    >
                      Login
                    </Link>

                    <Link
                      to={CTA_LINK.to}
                      onClick={closeMenu}
                      className="rounded-xl bg-white px-4 py-2 text-center
                                 text-sm font-medium text-black hover:bg-gray-200"
                    >
                      {CTA_LINK.label}
                    </Link>
                  </div>
                )
              )}
            </nav>
          </div>
        )}

      </div>
    </header>
  );
};

export default Header;

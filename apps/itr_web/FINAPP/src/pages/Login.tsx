import { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useDispatch } from 'react-redux';
import InputField from '../components/InputField';
import { useFormValidation } from '../hooks/useFormValidation';
import type { ValidationRule } from '../utils/validation';
import { getErrorMessage } from '../services/api';
import { loginUser } from '../store/slices/authSlice';
import type { AppDispatch } from '../store/index';

const Login = () => {
  const navigate = useNavigate();
  const [apiError, setApiError] = useState<string>('');

  const initialFormData = {
    email: '',
    password: '',
    platform:'web',
    version:'1.0.0'
  };

  const getValidationRules = (formData: typeof initialFormData): ValidationRule[] => [
    {
      field: 'email',
      value: formData.email,
      rules: {
        required: true,
        custom: (val: string) => {
          const isEmail = /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(val);
          const isMobile = /^[6-9]\d{9}$/.test(val);
          return isEmail || isMobile ? true : 'Enter valid email or 10-digit mobile number';
        },
      },
    },
    {
      field: 'password',
      value: formData.password,
      rules: {
        required: true,
        minLength: 6,
      },
    },
  ];

  const { formData, errors, loading, handleChange, handleSubmit } = useFormValidation(
    initialFormData,
    getValidationRules
  );

  const dispatch = useDispatch<AppDispatch>();

  const handleLoginSubmit = async (data: typeof initialFormData) => {
    try {
      setApiError('');
      // Use redux thunk to login which will update store and localStorage
      await dispatch(
        loginUser({ email: data.email, password: data.password,platform:data.platform,version:data.version}) as any
      ).unwrap();

      // Redirect to dashboard after successful login
      navigate('/dashboard');
    } catch (error) {
      const errorMsg = getErrorMessage(error);
      setApiError(errorMsg);
      console.error('Login failed:', error);
    }
  };

  return (
    <main className="min-h-screen bg-gray-950">
      <div className="mx-auto max-w-md px-4 py-10">

        <div className="rounded-3xl bg-gray-900 border border-gray-800 p-8 shadow-2xl shadow-gray-900">
          <h1 className="text-2xl font-bold text-white">
            Welcome back
          </h1>
          <p className="mt-2 text-sm text-gray-400">
            Login to continue filing your income tax returns
          </p>

          <form onSubmit={async (e) => (await handleSubmit(handleLoginSubmit))(e)} className="mt-8 space-y-5">

            {apiError && (
              <div className="rounded-lg bg-red-900 p-4 text-sm text-red-100 border border-red-700">
                {apiError}
              </div>
            )}

            <InputField
              label="Email"
              name="email"
              placeholder="Enter email or mobile number"
              value={formData.email}
              onChange={handleChange}
              error={errors.email}
            />

            <InputField
              label="Password"
              type="password"
              name="password"
              placeholder="Enter your password"
              value={formData.password}
              onChange={handleChange}
              error={errors.password}
            />

            <div className="flex items-center justify-between text-sm">
              <label className="flex items-center gap-2">
                <input
                  type="checkbox"
                  className="h-4 w-4 rounded border-gray-700 bg-gray-800 text-white focus:ring-gray-500 accent-white"
                />
                <span className="text-gray-400">Remember me</span>
              </label>

              <Link
                to="/forgot-password"
                className="font-medium text-gray-300 hover:text-white transition-colors"
              >
                Forgot password?
              </Link>
            </div>

            <button
              type="submit"
              disabled={loading}
              className="mt-2 w-full rounded-xl bg-white text-black px-4 py-3
                         text-sm font-semibold transition
                         hover:bg-gray-200 active:scale-95
                         disabled:cursor-not-allowed disabled:bg-gray-600 disabled:opacity-70"
            >
              {loading ? 'Logging in...' : 'Login'}
            </button>

          </form>

          <p className="mt-6 text-center text-sm text-gray-400">
            Don't have an account?{' '}
            <Link
              to="/sign-up"
              className="font-medium text-white hover:text-gray-300 transition-colors"
            >
              Sign up
            </Link>
          </p>
        </div>

      </div>
    </main>
  );
};

export default Login;

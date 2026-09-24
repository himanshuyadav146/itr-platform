import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useDispatch, useSelector } from 'react-redux';
import InputField from '../components/InputField';
import { useFormValidation } from '../hooks/useFormValidation';
import type { ValidationRule } from '../utils/validation';
import { validators } from '../utils/validation';
import { signupUser } from '../store/slices/authSlice';
import type { AppDispatch, RootState } from '../store/index';

const Signup = () => {
  const navigate = useNavigate();
  const dispatch = useDispatch<AppDispatch>();
  const { loading, error } = useSelector((state: RootState) => state.auth);
  const [apiError, setApiError] = useState<string>('');

  const initialFormData = {
    name: '',
    email: '',
    mobile: '',
    password: '',
  };

  const getValidationRules = (formData: typeof initialFormData): ValidationRule[] => [
    {
      field: 'name',
      value: formData.name,
      rules: validators.name(),
    },
    {
      field: 'email',
      value: formData.email,
      rules: validators.email(),
    },
    {
      field: 'mobile',
      value: formData.mobile,
      rules: validators.mobile(),
    },
    {
      field: 'password',
      value: formData.password,
      rules: validators.password(),
    },
  ];

  const { formData, errors, handleChange, handleSubmit } = useFormValidation(
    initialFormData,
    getValidationRules
  );

  const handleSignupSubmit = async (data: typeof initialFormData) => {
    try {
      setApiError('');
      await dispatch(
        signupUser({
          name: data.name,
          email: data.email,
          mobile: data.mobile,
          password: data.password,
          platform: 'web',
          version: '1.0',
          role: 'CLIENT',
        }) as any
      ).unwrap();

      // Redirect to dashboard on successful signup
      navigate('/dashboard');
    } catch (error: any) {
      setApiError(error || 'Signup failed. Please try again.');
      console.error('Signup failed:', error);
    }
  };

  return (
    <main className="min-h-screen bg-gray-950">
      <div className="mx-auto max-w-2xl px-4 py-10">

        <div className="rounded-3xl bg-gray-900 border border-gray-800 p-8 shadow-2xl shadow-gray-900">
          <h1 className="text-2xl font-bold text-white">
            Create your account
          </h1>
          <p className="mt-2 text-sm text-gray-400">
            Sign up to start filing your income tax returns
          </p>

          <form onSubmit={async (e) => (await handleSubmit(handleSignupSubmit))(e)} className="mt-8 space-y-5">

            {(apiError || error) && (
              <div className="rounded-lg bg-red-900 p-4 text-sm text-red-100 border border-red-700">
                {apiError || error}
              </div>
            )}

            {/* Row 1 - Name and Email */}
            <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
              <InputField
                label="Full Name"
                name="name"
                placeholder="Enter your full name"
                value={formData.name}
                onChange={handleChange}
                error={errors.name}
              />

              <InputField
                label="Email Address"
                type="email"
                name="email"
                placeholder="you@example.com"
                value={formData.email}
                onChange={handleChange}
                error={errors.email}
              />
            </div>

            {/* Row 2 - Mobile and Password */}
            <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
              <InputField
                label="Mobile Number"
                name="mobile"
                maxLength={10}
                placeholder="10-digit mobile number"
                value={formData.mobile}
                onChange={handleChange}
                error={errors.mobile}
              />

              <InputField
                label="Password"
                type="password"
                name="password"
                placeholder="Create a strong password"
                value={formData.password}
                onChange={handleChange}
                error={errors.password}
                helperText="Min 8 chars: uppercase, lowercase, number, special char"
              />
            </div>

            <button
              type="submit"
              disabled={loading}
              className="mt-2 w-full rounded-xl bg-white text-black px-4 py-3
                         text-sm font-semibold transition
                         hover:bg-gray-200 active:scale-95
                         disabled:cursor-not-allowed disabled:bg-gray-600 disabled:opacity-70"
            >
              {loading ? 'Creating account...' : 'Sign Up'}
            </button>

          </form>

          <p className="mt-6 text-center text-sm text-gray-400">
            Already have an account?{' '}
            <a
              href="/login"
              className="font-medium text-white hover:text-gray-300 transition-colors"
            >
              Login
            </a>
            <span className="block mt-2">
              CA, Accountant, or Tax Expert?{' '}
              <a href="/associate-register" className="font-medium text-white hover:text-gray-300">
                Join as associate
              </a>
            </span>
          </p>
        </div>

      </div>
    </main>
  );
};

export default Signup;

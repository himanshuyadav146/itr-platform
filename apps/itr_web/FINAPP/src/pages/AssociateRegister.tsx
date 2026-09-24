import { useState } from 'react';
import { Link } from 'react-router-dom';
import InputField from '../components/InputField';
import { useFormValidation } from '../hooks/useFormValidation';
import type { ValidationRule } from '../utils/validation';
import { validators } from '../utils/validation';
import { associatesApi, getErrorMessage } from '../services/api';
import { ADMIN_LOGIN_URL } from '../utils/links';

const AssociateRegister = () => {
  const [apiError, setApiError] = useState('');
  const [loading, setLoading] = useState(false);

  const initialFormData = {
    name: '',
    email: '',
    mobile: '',
    password: '',
    role: 'CA',
  };

  const getValidationRules = (formData: typeof initialFormData): ValidationRule[] => [
    { field: 'name', value: formData.name, rules: validators.name() },
    { field: 'email', value: formData.email, rules: validators.email() },
    { field: 'mobile', value: formData.mobile, rules: validators.mobile() },
    { field: 'password', value: formData.password, rules: validators.password() },
  ];

  const { formData, errors, handleChange, handleSubmit } = useFormValidation(
    initialFormData,
    getValidationRules
  );

  const onSubmit = async (data: typeof initialFormData) => {
    setApiError('');
    setLoading(true);
    try {
      await associatesApi.register({
        name: data.name,
        email: data.email,
        mobile: data.mobile,
        password: data.password,
        role: data.role,
        platform: 'web',
        version: '1.0',
      });
      window.location.href = `${ADMIN_LOGIN_URL}?registered=1`;
    } catch (err) {
      setApiError(getErrorMessage(err) || 'Registration failed. Please try again.');
      setLoading(false);
    }
  };

  return (
    <main className="min-h-screen bg-gray-950">
      <div className="mx-auto max-w-2xl px-4 py-10">
        <div className="rounded-3xl bg-gray-900 border border-gray-800 p-8 shadow-2xl">
          <h1 className="text-2xl font-bold text-white">Join as an associate</h1>
          <p className="mt-2 text-sm text-gray-400">
            Create a CA, Accountant, or Tax Expert account. You will sign in on the admin dashboard to add experience, services, and fees.
          </p>

          <form onSubmit={async (e) => (await handleSubmit(onSubmit))(e)} className="mt-8 space-y-5">
            {apiError && (
              <div className="rounded-lg bg-red-900 p-4 text-sm text-red-100 border border-red-700">
                {apiError}
              </div>
            )}

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

            <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
              <InputField
                label="Mobile"
                name="mobile"
                placeholder="10-digit mobile"
                value={formData.mobile}
                onChange={handleChange}
                error={errors.mobile}
              />
              <InputField
                label="Password"
                type="password"
                name="password"
                placeholder="Create a password"
                value={formData.password}
                onChange={handleChange}
                error={errors.password}
              />
            </div>

            <div>
              <label className="mb-1 block text-sm font-medium text-gray-300">Role</label>
              <select
                name="role"
                value={formData.role}
                onChange={handleChange}
                className="w-full rounded-xl border border-gray-700 bg-gray-800 px-4 py-3 text-white"
              >
                <option value="CA">Chartered Accountant</option>
                <option value="ACCOUNTANT">Accountant</option>
                <option value="TAX_EXPERT">Tax Expert</option>
              </select>
            </div>

            <button
              type="submit"
              disabled={loading}
              className="w-full rounded-xl bg-white px-4 py-3 text-sm font-semibold text-black hover:bg-gray-200 disabled:opacity-60"
            >
              {loading ? 'Creating account…' : 'Create associate account'}
            </button>
          </form>

          <p className="mt-6 text-sm text-gray-500">
            Already registered?{' '}
            <a href={`${ADMIN_LOGIN_URL}`} className="text-white hover:underline">
              Sign in to admin
            </a>
            {' · '}
            <Link to="/sign-up" className="text-white hover:underline">
              File as a client instead
            </Link>
          </p>
        </div>
      </div>
    </main>
  );
};

export default AssociateRegister;

import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { apiPost, getErrorMessage } from '../services/api';
import { apiUrl } from '../config/baseUrlConstant';
import InputField from '../components/InputField';

const AssociateRegister = () => {
  const navigate = useNavigate();
  const [form, setForm] = useState({
    name: '',
    email: '',
    mobile: '',
    password: '',
    role: 'CA',
    icai_membership_no: '',
    city: '',
    state: '',
  });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  const onChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) => {
    setForm((prev) => ({ ...prev, [e.target.name]: e.target.value }));
  };

  const onSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setSuccess('');
    setLoading(true);
    try {
      await apiPost(apiUrl.registerAssociate, {
        ...form,
        platform: 'web',
        version: '1.0',
      });
      setSuccess('Registration received. Redirecting to associate login…');
      setTimeout(() => {
        window.location.href = '/admin/login';
      }, 1200);
    } catch (err) {
      setError(getErrorMessage(err));
      setLoading(false);
    }
  };

  return (
    <main className="min-h-screen bg-gray-950">
      <div className="mx-auto max-w-2xl px-4 py-10">
        <div className="rounded-3xl bg-gray-900 border border-gray-800 p-8 shadow-2xl">
          <h1 className="text-2xl font-bold text-white">Become an associate</h1>
          <p className="mt-2 text-gray-400">
            Register as a CA, accountant, or tax expert. You can sign in to complete credentials, but clients will not see you until an admin approves your profile.
          </p>

          {error && <div className="mt-4 rounded border border-red-700 bg-red-900/40 p-3 text-red-100">{error}</div>}
          {success && <div className="mt-4 rounded border border-emerald-700 bg-emerald-900/40 p-3 text-emerald-100">{success}</div>}

          <form className="mt-6 space-y-4" onSubmit={onSubmit}>
            <InputField name="name" label="Full name" value={form.name} onChange={onChange} required />
            <InputField name="email" label="Email" type="email" value={form.email} onChange={onChange} required />
            <InputField name="mobile" label="Mobile" value={form.mobile} onChange={onChange} required />
            <InputField name="password" label="Password" type="password" value={form.password} onChange={onChange} required />
            <label className="block text-sm text-gray-300">
              Role
              <select
                name="role"
                value={form.role}
                onChange={onChange}
                className="mt-1 w-full rounded-xl border border-gray-700 bg-gray-800 px-3 py-2 text-white"
              >
                <option value="CA">Chartered Accountant</option>
                <option value="ACCOUNTANT">Accountant</option>
                <option value="TAX_EXPERT">Tax Expert</option>
              </select>
            </label>
            <InputField name="icai_membership_no" label="ICAI / membership no." value={form.icai_membership_no} onChange={onChange} />
            <InputField name="city" label="City" value={form.city} onChange={onChange} />
            <InputField name="state" label="State" value={form.state} onChange={onChange} />
            <button
              type="submit"
              disabled={loading}
              className="w-full rounded-xl bg-blue-600 px-4 py-3 font-semibold text-white hover:bg-blue-500 disabled:opacity-60"
            >
              {loading ? 'Submitting…' : 'Create associate account'}
            </button>
          </form>

          <button className="mt-4 text-sm text-gray-400 hover:text-white" onClick={() => navigate('/login')}>
            Client? Sign in here
          </button>
        </div>
      </div>
    </main>
  );
};

export default AssociateRegister;

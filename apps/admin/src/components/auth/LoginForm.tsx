import { useState } from 'react';
import {
  Box,
  TextField,
  Button,
  Alert,
  CircularProgress,
} from '@mui/material';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { authApi } from '../../api/auth';
import { useAuth } from '../../hooks/useAuth';
import { useNavigate, useSearchParams } from 'react-router-dom';
import { useAppDispatch } from '../../store/hooks';
import { addNotification } from '../../store/slices/uiSlice';
import { UserRole } from '../../types/enums';
import type { User } from '../../types';

const loginSchema = z.object({
  email: z.string().email('Invalid email address'),
  password: z.string().min(1, 'Password is required'),
});

type LoginFormData = z.infer<typeof loginSchema>;

export const LoginForm = () => {
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const { login } = useAuth();
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const dispatch = useAppDispatch();
  const redirectTo = searchParams.get('redirect');
  const safeRedirect = redirectTo && redirectTo.startsWith('/') && !redirectTo.startsWith('//') ? redirectTo : null;

  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<LoginFormData>({
    resolver: zodResolver(loginSchema),
  });

  const onSubmit = async (data: LoginFormData) => {
    setError(null);
    setLoading(true);

    try {
      const response = await authApi.login({
        email: data.email,
        password: data.password,
        platform: 'web',
        version: '1.0',
      });

      const token = response.data?.token ?? '';
      const hasSuccess = response.status === 'success' || (token && response.statusCode === 200);

      if (hasSuccess && token) {
        const apiRole = response.data?.role;
        const normalizedRole = apiRole
          ? (String(apiRole).toUpperCase().trim() as UserRole)
          : UserRole.CLIENT;

        const user: User = {
          UserId: response.data?.UserId ?? 0,
          Email: response.data?.email ?? '',
          FirstName: '',
          LastName: '',
          role: normalizedRole,
        };

        login(user, token);

        const storedToken = localStorage.getItem('auth_token');
        if (!storedToken) {
          setError('Failed to store authentication token');
          setLoading(false);
          return;
        }

        dispatch(
          addNotification({
            message: 'Login successful!',
            type: 'success',
          })
        );
        
        // Small delay to ensure token is fully persisted
        await new Promise(resolve => setTimeout(resolve, 100));

        // Redirect to requested path (e.g. /delete-account) or dashboard
        navigate(safeRedirect ?? '/dashboard', { replace: true });
      } else {
        setError(response.data?.message || 'Login failed');
      }
    } catch (err: any) {
      setError(err.response?.data?.data?.message || 'An error occurred during login');
    } finally {
      setLoading(false);
    }
  };

  return (
    <Box component="form" onSubmit={handleSubmit(onSubmit)} sx={{ width: '100%' }}>
      {error && (
        <Alert severity="error" sx={{ mb: 2 }}>
          {error}
        </Alert>
      )}

      <TextField
        {...register('email')}
        label="Email"
        type="email"
        fullWidth
        margin="normal"
        error={!!errors.email}
        helperText={errors.email?.message}
        autoComplete="email"
      />

      <TextField
        {...register('password')}
        label="Password"
        type="password"
        fullWidth
        margin="normal"
        error={!!errors.password}
        helperText={errors.password?.message}
        autoComplete="current-password"
      />

      <Button
        type="submit"
        fullWidth
        variant="contained"
        sx={{ mt: 3, mb: 2 }}
        disabled={loading}
      >
        {loading ? <CircularProgress size={24} /> : 'Sign In'}
      </Button>
    </Box>
  );
};


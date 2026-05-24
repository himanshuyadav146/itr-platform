import { useState } from 'react';
import {
  Box,
  TextField,
  Button,
  Alert,
  CircularProgress,
  MenuItem,
} from '@mui/material';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { authApi } from '../../api/auth';
import { useNavigate } from 'react-router-dom';
import { useAppDispatch } from '../../store/hooks';
import { addNotification } from '../../store/slices/uiSlice';
import { ProfessionalOccupation } from '../../types/enums';

const registerSchema = z.object({
  name: z.string().min(2, 'Name must be at least 2 characters'),
  email: z.string().email('Invalid email address'),
  phone: z.string().min(10, 'Phone number must be at least 10 digits'),
  password: z.string().min(6, 'Password must be at least 6 characters'),
  occupation: z.nativeEnum(ProfessionalOccupation),
});

type RegisterFormData = z.infer<typeof registerSchema>;

export const RegisterForm = () => {
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();
  const dispatch = useAppDispatch();

  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<RegisterFormData>({
    resolver: zodResolver(registerSchema),
  });

  const onSubmit = async (data: RegisterFormData) => {
    setError(null);
    setLoading(true);

    try {
      const response = await authApi.registerProfessional({
        name: data.name,
        email: data.email,
        phone: data.phone,
        password: data.password,
        occupation: data.occupation,
      });

      if (response.status === 'success') {
        dispatch(
          addNotification({
            message: 'Registration successful! Please login.',
            type: 'success',
          })
        );
        navigate('/login');
      } else {
        setError(response.data?.message || 'Registration failed');
      }
    } catch (err: any) {
      setError(err.response?.data?.data?.message || 'An error occurred during registration');
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
        {...register('name')}
        label="Full Name"
        fullWidth
        margin="normal"
        error={!!errors.name}
        helperText={errors.name?.message}
      />

      <TextField
        {...register('email')}
        label="Email"
        type="email"
        fullWidth
        margin="normal"
        error={!!errors.email}
        helperText={errors.email?.message}
      />

      <TextField
        {...register('phone')}
        label="Phone Number"
        fullWidth
        margin="normal"
        error={!!errors.phone}
        helperText={errors.phone?.message}
      />

      <TextField
        {...register('occupation')}
        select
        label="Occupation"
        fullWidth
        margin="normal"
        error={!!errors.occupation}
        helperText={errors.occupation?.message}
        defaultValue=""
      >
        <MenuItem value={ProfessionalOccupation.CA}>CA</MenuItem>
        <MenuItem value={ProfessionalOccupation.TAX_EXPERT}>Tax Expert</MenuItem>
        <MenuItem value={ProfessionalOccupation.ACCOUNTANT}>Accountant</MenuItem>
      </TextField>

      <TextField
        {...register('password')}
        label="Password"
        type="password"
        fullWidth
        margin="normal"
        error={!!errors.password}
        helperText={errors.password?.message}
      />

      <Button
        type="submit"
        fullWidth
        variant="contained"
        sx={{ mt: 3, mb: 2 }}
        disabled={loading}
      >
        {loading ? <CircularProgress size={24} /> : 'Register'}
      </Button>
    </Box>
  );
};


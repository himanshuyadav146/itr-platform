import { useState } from 'react';
import {
  Box,
  TextField,
  Button,
  Paper,
  MenuItem,
  Alert,
  CircularProgress,
} from '@mui/material';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { usersApi } from '../../api/users';
import type { UserDetails } from '../../types';
import { UserRole } from '../../types/enums';
import { useNavigate } from 'react-router-dom';
import { useAppDispatch } from '../../store/hooks';
import { addNotification } from '../../store/slices/uiSlice';

const userFormSchema = z.object({
  FirstName: z.string().min(1, 'First name is required'),
  MiddleName: z.string().optional(),
  LastName: z.string().min(1, 'Last name is required'),
  Email: z.string().email('Invalid email address'),
  Mobile: z.string().optional(),
  role: z.nativeEnum(UserRole).optional(),
});

type UserFormData = z.infer<typeof userFormSchema>;

interface UserFormProps {
  user: UserDetails;
}

export const UserForm = ({ user }: UserFormProps) => {
  const [error, setError] = useState<string | null>(null);
  const navigate = useNavigate();
  const dispatch = useAppDispatch();
  const queryClient = useQueryClient();

  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<UserFormData>({
    resolver: zodResolver(userFormSchema),
    defaultValues: {
      FirstName: user.FirstName || '',
      MiddleName: user.MiddleName || '',
      LastName: user.LastName || '',
      Email: user.Email || '',
      Mobile: user.Mobile || '',
      role: (user.role as UserRole) || UserRole.CLIENT,
    },
  });

  const updateMutation = useMutation({
    mutationFn: (data: Partial<UserFormData>) => usersApi.updateUser(user.UserId, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['user', user.UserId] });
      queryClient.invalidateQueries({ queryKey: ['users'] });
      dispatch(
        addNotification({
          message: 'User updated successfully',
          type: 'success',
        })
      );
      navigate(`/users/${user.UserId}`);
    },
    onError: (err: any) => {
      setError(err.response?.data?.data?.message || 'Failed to update user');
    },
  });

  const onSubmit = async (data: UserFormData) => {
    setError(null);
    try {
      await updateMutation.mutateAsync(data);
    } catch (err) {
      // Error handled in mutation callbacks
    }
  };

  return (
    <Paper sx={{ p: 3 }}>
      {error && (
        <Alert severity="error" sx={{ mb: 2 }}>
          {error}
        </Alert>
      )}

      <Box component="form" onSubmit={handleSubmit(onSubmit)}>
        <TextField
          {...register('FirstName')}
          label="First Name"
          fullWidth
          margin="normal"
          error={!!errors.FirstName}
          helperText={errors.FirstName?.message}
          required
        />

        <TextField
          {...register('MiddleName')}
          label="Middle Name"
          fullWidth
          margin="normal"
          error={!!errors.MiddleName}
          helperText={errors.MiddleName?.message}
        />

        <TextField
          {...register('LastName')}
          label="Last Name"
          fullWidth
          margin="normal"
          error={!!errors.LastName}
          helperText={errors.LastName?.message}
          required
        />

        <TextField
          {...register('Email')}
          label="Email"
          type="email"
          fullWidth
          margin="normal"
          error={!!errors.Email}
          helperText={errors.Email?.message}
          required
        />

        <TextField
          {...register('Mobile')}
          label="Phone"
          fullWidth
          margin="normal"
          error={!!errors.Mobile}
          helperText={errors.Mobile?.message}
        />

        <TextField
          {...register('role')}
          select
          label="Role"
          fullWidth
          margin="normal"
          error={!!errors.role}
          helperText={errors.role?.message}
        >
          {(Object.values(UserRole) as string[]).map((role) => (
            <MenuItem key={role} value={role}>
              {role}
            </MenuItem>
          ))}
        </TextField>

        <Box sx={{ mt: 3, display: 'flex', gap: 2 }}>
          <Button
            type="submit"
            variant="contained"
            disabled={isSubmitting || updateMutation.isPending}
          >
            {isSubmitting || updateMutation.isPending ? (
              <CircularProgress size={24} />
            ) : (
              'Save Changes'
            )}
          </Button>
          <Button variant="outlined" onClick={() => navigate(`/users/${user.UserId}`)}>
            Cancel
          </Button>
        </Box>
      </Box>
    </Paper>
  );
};

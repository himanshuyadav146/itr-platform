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
import { ArrowBack as ArrowBackIcon } from '@mui/icons-material';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { useNavigate } from 'react-router-dom';
import { packagesApi } from '../../api/packages';
import type { Package, PackageFormPayload } from '../../types/package';
import { useAppDispatch } from '../../store/hooks';
import { addNotification } from '../../store/slices/uiSlice';

const packageSchema = z.object({
  packagename: z.string().min(1, 'Package name is required'),
  price: z.number().min(0, 'Price must be 0 or more'),
  description1: z.string().min(1, 'Description is required'),
  turnover: z.string().min(1, 'Turnover is required'),
  icon: z.string().min(1, 'Icon is required'),
  color: z.string().min(1, 'Color is required'),
  isActive: z.number().min(0).max(1),
});

type PackageFormData = z.infer<typeof packageSchema>;

const ICON_OPTIONS = [
  'business_outline',
  'business_center',
  'receipt_long',
  'account_balance',
  'savings',
  'trending_up',
  'description',
  'folder',
];

const COLOR_OPTIONS = [
  'red',
  'blue',
  'green',
  'orange',
  'purple',
  'lightblue',
  'grey',
  'teal',
];

interface PackageFormProps {
  pkg: Package | null;
  isEdit: boolean;
}

export const PackageForm = ({ pkg, isEdit }: PackageFormProps) => {
  const [error, setError] = useState<string | null>(null);
  const navigate = useNavigate();
  const dispatch = useAppDispatch();
  const queryClient = useQueryClient();

  const defaultValues: PackageFormData = pkg
    ? {
        packagename: pkg.packagename ?? '',
        price: pkg.price ?? 0,
        description1: pkg.description1 ?? '',
        turnover: pkg.turnover ?? '',
        icon: pkg.icon ?? '',
        color: pkg.color ?? '',
        isActive: pkg.isActive ?? 1,
      }
    : {
        packagename: '',
        price: 0,
        description1: '',
        turnover: '',
        icon: '',
        color: '',
        isActive: 1,
      };

  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<PackageFormData>({
    resolver: zodResolver(packageSchema),
    defaultValues,
  });

  const addMutation = useMutation({
    mutationFn: (data: PackageFormPayload) => packagesApi.addPackage(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['packages'] });
      dispatch(addNotification({ message: 'Package added successfully', type: 'success' }));
      navigate('/packages');
    },
    onError: (err: unknown) => {
      const res = err && typeof err === 'object' && 'response' in err
        ? (err as { response?: { data?: { message?: string; data?: { message?: string } } } }).response?.data
        : null;
      setError(res?.message ?? res?.data?.message ?? 'Failed to add package');
    },
  });

  const updateMutation = useMutation({
    mutationFn: (data: PackageFormPayload & { id: number }) => packagesApi.updatePackage(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['packages'] });
      queryClient.invalidateQueries({ queryKey: ['package', pkg?.id] });
      dispatch(addNotification({ message: 'Package updated successfully', type: 'success' }));
      navigate('/packages');
    },
    onError: (err: unknown) => {
      const res = err && typeof err === 'object' && 'response' in err
        ? (err as { response?: { data?: { message?: string; data?: { message?: string } } } }).response?.data
        : null;
      setError(res?.message ?? res?.data?.message ?? 'Failed to update package');
    },
  });

  const onSubmit = (data: PackageFormData) => {
    setError(null);
    const payload: PackageFormPayload = {
      packagename: data.packagename,
      price: data.price,
      description1: data.description1,
      turnover: data.turnover,
      icon: data.icon,
      color: data.color,
      isActive: data.isActive,
    };
    if (isEdit && pkg) {
      updateMutation.mutate({ ...payload, id: pkg.id });
    } else {
      addMutation.mutate(payload);
    }
  };

  const loading = addMutation.isPending || updateMutation.isPending;

  return (
    <Paper sx={{ p: 3 }}>
      <Button startIcon={<ArrowBackIcon />} onClick={() => navigate('/packages')} sx={{ mb: 2 }}>
        Back to Packages
      </Button>

      {error && (
        <Alert severity="error" sx={{ mb: 2 }}>
          {error}
        </Alert>
      )}

      <Box component="form" onSubmit={handleSubmit(onSubmit)}>
        <TextField
          {...register('packagename')}
          label="Package Name"
          fullWidth
          margin="normal"
          error={!!errors.packagename}
          helperText={errors.packagename?.message}
        />
        <TextField
          {...register('price', { valueAsNumber: true })}
          label="Price (₹)"
          type="number"
          fullWidth
          margin="normal"
          inputProps={{ min: 0, step: 1 }}
          error={!!errors.price}
          helperText={errors.price?.message}
        />
        <TextField
          {...register('description1')}
          label="Description"
          fullWidth
          margin="normal"
          multiline
          rows={3}
          error={!!errors.description1}
          helperText={errors.description1?.message}
        />
        <TextField
          {...register('turnover')}
          label="Turnover"
          fullWidth
          margin="normal"
          error={!!errors.turnover}
          helperText={errors.turnover?.message}
        />
        <TextField
          {...register('icon')}
          select
          label="Icon"
          fullWidth
          margin="normal"
          error={!!errors.icon}
          helperText={errors.icon?.message}
        >
          {ICON_OPTIONS.map((opt) => (
            <MenuItem key={opt} value={opt}>
              {opt}
            </MenuItem>
          ))}
        </TextField>
        <TextField
          {...register('color')}
          select
          label="Color"
          fullWidth
          margin="normal"
          error={!!errors.color}
          helperText={errors.color?.message}
        >
          {COLOR_OPTIONS.map((opt) => (
            <MenuItem key={opt} value={opt}>
              {opt}
            </MenuItem>
          ))}
        </TextField>
        <TextField
          {...register('isActive', { valueAsNumber: true })}
          select
          label="Active"
          fullWidth
          margin="normal"
          error={!!errors.isActive}
          helperText={errors.isActive?.message}
        >
          <MenuItem value={1}>Yes</MenuItem>
          <MenuItem value={0}>No</MenuItem>
        </TextField>

        <Box sx={{ mt: 3, display: 'flex', gap: 2 }}>
          <Button type="submit" variant="contained" disabled={isSubmitting || loading}>
            {loading ? <CircularProgress size={24} /> : isEdit ? 'Update' : 'Save'}
          </Button>
          <Button variant="outlined" onClick={() => navigate('/packages')}>
            Cancel
          </Button>
        </Box>
      </Box>
    </Paper>
  );
};

import { useState } from 'react';
import {
  Box,
  TextField,
  Button,
  Paper,
  Alert,
  CircularProgress,
} from '@mui/material';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { itrApi } from '../../api/itr';
import type { ITRWithDetails } from '../../types';
import { useNavigate } from 'react-router-dom';
import { useAppDispatch } from '../../store/hooks';
import { addNotification } from '../../store/slices/uiSlice';

const markCompleteSchema = z.object({
  acknowledgementNumber: z.string().min(1, 'Acknowledgement number is required'),
  remarks: z.string().optional(),
});

type MarkCompleteFormData = z.infer<typeof markCompleteSchema>;

interface MarkITRCompleteFormProps {
  itr: ITRWithDetails;
}

function formatAcknowledgementDate(): string {
  const d = new Date();
  return d.toISOString().slice(0, 10);
}

function getAssessmentYear(itr: ITRWithDetails): string {
  const fy = itr.financialYear || '';
  if (fy && /^\d{4}-\d{2}$/.test(fy)) return fy;
  if (fy && typeof fy === 'string' && fy.trim()) return fy.trim();
  const y = new Date().getFullYear();
  return `${y}-${String(y + 1).slice(-2)}`;
}

export const MarkITRCompleteForm = ({ itr }: MarkITRCompleteFormProps) => {
  const [error, setError] = useState<string | null>(null);
  const navigate = useNavigate();
  const dispatch = useAppDispatch();
  const queryClient = useQueryClient();
  const backendItrId = itr.itrId || itr.id;

  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<MarkCompleteFormData>({
    resolver: zodResolver(markCompleteSchema),
    defaultValues: {
      acknowledgementNumber: '',
      remarks: '',
    },
  });

  const submitMutation = useMutation({
    mutationFn: (data: MarkCompleteFormData) => {
      return itrApi.submitAcknowledgement({
        itrId: backendItrId,
        acknowledgementNumber: data.acknowledgementNumber.trim(),
        acknowledgementDate: formatAcknowledgementDate(),
        remarks: data.remarks?.trim() || '',
        itrForm: 'ITR-1',
        assessmentYear: getAssessmentYear(itr),
      });
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['itr', itr.id] });
      queryClient.invalidateQueries({ queryKey: ['itrs'] });
      queryClient.invalidateQueries({ queryKey: ['itrs', 'detail', itr.id] });
      dispatch(
        addNotification({
          message: 'Acknowledgement submitted successfully',
          type: 'success',
        })
      );
      navigate('/itrs');
    },
    onError: (err: any) => {
      setError(err.response?.data?.data?.message || err.response?.data?.message || 'Failed to submit acknowledgement');
    },
  });

  return (
    <Paper sx={{ p: 3 }}>
      {error && (
        <Alert severity="error" sx={{ mb: 2 }} onClose={() => setError(null)}>
          {error}
        </Alert>
      )}

      <Box component="form" onSubmit={handleSubmit((data) => submitMutation.mutate(data))}>
        <TextField
          {...register('acknowledgementNumber')}
          label="Acknowledgement Number"
          fullWidth
          margin="normal"
          placeholder="e.g. ACK123456789"
          error={!!errors.acknowledgementNumber}
          helperText={errors.acknowledgementNumber?.message}
          required
        />

        <TextField
          {...register('remarks')}
          label="Remarks"
          multiline
          rows={4}
          fullWidth
          margin="normal"
          placeholder="e.g. Filed via portal"
          error={!!errors.remarks}
          helperText={errors.remarks?.message}
        />

        <Box sx={{ mt: 3, display: 'flex', gap: 2 }}>
          <Button
            type="submit"
            variant="contained"
            disabled={isSubmitting || submitMutation.isPending}
          >
            {submitMutation.isPending ? (
              <CircularProgress size={24} />
            ) : (
              'Submit'
            )}
          </Button>
          <Button variant="outlined" onClick={() => navigate(`/itrs/${itr.id}`)}>
            Cancel
          </Button>
        </Box>
      </Box>
    </Paper>
  );
};

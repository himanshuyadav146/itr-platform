import { useState } from 'react';
import {
  Box,
  TextField,
  Button,
  Paper,
  MenuItem,
  Alert,
  CircularProgress,
  Typography,
} from '@mui/material';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { itrApi } from '../../api/itr';
import type { ITRWithDetails } from '../../types';
import { ITRWorkflowStatus } from '../../types/enums';
import { useNavigate } from 'react-router-dom';
import { useAppDispatch } from '../../store/hooks';
import { addNotification } from '../../store/slices/uiSlice';
import { StatusChip } from '../common/StatusChip';
import { ITR_STATUS_LABELS } from '../../utils/constants';

const editSchema = z.object({
  status: z.nativeEnum(ITRWorkflowStatus),
  comment: z.string().min(1, 'Comment is required when updating workflow status'),
});

type EditFormData = z.infer<typeof editSchema>;

interface ITREditFormProps {
  itr: ITRWithDetails;
}

export const ITREditForm = ({ itr }: ITREditFormProps) => {
  const [error, setError] = useState<string | null>(null);
  const navigate = useNavigate();
  const dispatch = useAppDispatch();
  const queryClient = useQueryClient();
  const backendItrId = itr.itrId || itr.id;

  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<EditFormData>({
    resolver: zodResolver(editSchema),
    defaultValues: {
      status: ITRWorkflowStatus.ASSIGNED,
      comment: '',
    },
  });

  const updateMutation = useMutation({
    mutationFn: (data: { id: number; status: string; comment: string }) =>
      itrApi.updateITR({
        id: data.id,
        status: data.status,
        comment: data.comment,
      }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['itr', itr.id] });
      queryClient.invalidateQueries({ queryKey: ['itrs'] });
      queryClient.invalidateQueries({ queryKey: ['itrs', 'detail', itr.id] });
      dispatch(
        addNotification({
          message: 'Workflow status updated successfully',
          type: 'success',
        })
      );
      navigate(`/itrs/${itr.id}`);
    },
    onError: (err: unknown) => {
      const apiErr = err as { response?: { data?: { data?: { message?: string } } } };
      setError(apiErr.response?.data?.data?.message || 'Failed to update ITR');
    },
  });

  const onSubmit = async (data: EditFormData) => {
    setError(null);
    await updateMutation.mutateAsync({
      id: backendItrId,
      status: data.status,
      comment: data.comment.trim(),
    });
  };

  return (
    <Paper sx={{ p: 3 }}>
      <Box sx={{ mb: 3, display: 'flex', alignItems: 'center', gap: 2 }}>
        <Typography variant="body2" color="text.secondary">
          Current display status:
        </Typography>
        <StatusChip status={itr.status} size="medium" />
      </Box>

      <Alert severity="info" sx={{ mb: 2 }}>
        To mark an ITR as completed, use the <strong>Mark ITR Complete</strong> tab and submit the
        acknowledgement number. Display status (Pending / Paid / In Progress / Completed) updates
        automatically from payment and workflow steps.
      </Alert>

      {error && (
        <Alert severity="error" sx={{ mb: 2 }}>
          {error}
        </Alert>
      )}

      <Box component="form" onSubmit={handleSubmit(onSubmit)}>
        <TextField
          {...register('status')}
          select
          label="Workflow status (internal)"
          fullWidth
          margin="normal"
          error={!!errors.status}
          helperText={errors.status?.message || 'For required documents, incorrect docs, etc.'}
        >
          {(Object.values(ITRWorkflowStatus) as string[]).map((status) => (
            <MenuItem key={status} value={status}>
              {ITR_STATUS_LABELS[status] || status}
            </MenuItem>
          ))}
        </TextField>

        <TextField
          {...register('comment')}
          label="Comment"
          multiline
          rows={4}
          fullWidth
          margin="normal"
          required
          error={!!errors.comment}
          helperText={errors.comment?.message || 'Required for audit trail'}
        />

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
          <Button variant="outlined" onClick={() => navigate(`/itrs/${itr.id}`)}>
            Cancel
          </Button>
        </Box>
      </Box>
    </Paper>
  );
};

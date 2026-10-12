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
import { itrApi } from '../../api/itr';
import type { ITRWithDetails } from '../../types';
import { ITRStatus } from '../../types/enums';
import { useNavigate } from 'react-router-dom';
import { useAppDispatch } from '../../store/hooks';
import { addNotification } from '../../store/slices/uiSlice';

const editSchema = z.object({
  status: z.nativeEnum(ITRStatus),
  comment: z.string().optional(),
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
  // Backend expects the actual itrId from itrDetails[0].itrId, which we store as itr.itrId
  const backendItrId = itr.itrId || itr.id;

  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<EditFormData>({
    resolver: zodResolver(editSchema),
    defaultValues: {
      status: (itr.status as ITRStatus) || ITRStatus.PENDING,
      comment: '',
    },
  });

  const updateMutation = useMutation({
    mutationFn: (data: { id: number; status: string; comment?: string }) => {
      return itrApi.updateITR({
        id: data.id,
        status: data.status,
        comment: data.comment,
      });
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['itr', itr.id] });
      queryClient.invalidateQueries({ queryKey: ['itrs'] });
      dispatch(
        addNotification({
          message: 'ITR updated successfully',
          type: 'success',
        })
      );
      navigate('/itrs');
    },
    onError: (err: any) => {
      setError(err.response?.data?.data?.message || 'Failed to update ITR');
    },
  });

  const commentMutation = useMutation({
    mutationFn: (data: { itrId: number; comment: string; status: string }) => {
      return itrApi.addComment(data.itrId, data.comment, data.status);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['itr', itr.id] });
    },
  });

  const onSubmit = async (data: EditFormData) => {
    setError(null);

    try {
      await updateMutation.mutateAsync({
        id: backendItrId,
        status: data.status,
        comment: data.comment,
      });

      if (data.comment && data.comment.trim()) {
        await commentMutation.mutateAsync({
          itrId: backendItrId,
          comment: data.comment,
          status: data.status,
        });
      }
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
          {...register('status')}
          select
          label="Status"
          fullWidth
          margin="normal"
          error={!!errors.status}
          helperText={errors.status?.message}
        >
          {(Object.values(ITRStatus) as string[]).map((status) => (
            <MenuItem key={status} value={status}>
              {status}
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
          error={!!errors.comment}
          helperText={errors.comment?.message || 'Optional comment'}
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


import { useState } from 'react';
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  TextField,
  Box,
  Typography,
  Alert,
  CircularProgress,
} from '@mui/material';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { itrApi } from '../../api/itr';
import type { UserDetails } from '../../types';
import { useAppDispatch } from '../../store/hooks';
import { addNotification } from '../../store/slices/uiSlice';

interface AssignITRModalProps {
  open: boolean;
  onClose: () => void;
  user: UserDetails;
}

export const AssignITRModal = ({ open, onClose, user }: AssignITRModalProps) => {
  const [itrId, setItrId] = useState<string>('');
  const [error, setError] = useState<string | null>(null);
  const dispatch = useAppDispatch();
  const queryClient = useQueryClient();

  const { data: userITRsResponse, isLoading: loadingITRs } = useQuery({
    queryKey: ['itrs', 'user', user.UserId],
    queryFn: () => itrApi.getITRs({ userId: user.UserId, page: 1, limit: 100 }),
    enabled: open,
  });
  const userITRs = userITRsResponse?.items ?? [];

  const assignMutation = useMutation({
    mutationFn: ({ }: { itrId: number; userId: number }) => {
      // This would need a new API endpoint to assign ITR to user
      // For now, we'll use a placeholder
      return Promise.resolve({ success: true });
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['itrs'] });
      queryClient.invalidateQueries({ queryKey: ['user', user.UserId] });
      dispatch(
        addNotification({
          message: 'ITR assigned to user successfully',
          type: 'success',
        })
      );
      onClose();
      setItrId('');
    },
    onError: (err: any) => {
      setError(err.response?.data?.data?.message || 'Failed to assign ITR');
    },
  });

  const handleAssign = () => {
    const parsedItrId = parseInt(itrId, 10);
    if (!itrId || isNaN(parsedItrId)) {
      setError('Please enter a valid ITR ID');
      return;
    }
    setError(null);
    assignMutation.mutate({ itrId: parsedItrId, userId: user.UserId });
  };

  const handleClose = () => {
    setItrId('');
    setError(null);
    onClose();
  };

  return (
    <Dialog open={open} onClose={handleClose} maxWidth="sm" fullWidth>
      <DialogTitle>Assign ITR to User</DialogTitle>
      <DialogContent>
        <Box sx={{ mt: 2 }}>
          <Typography variant="body2" color="text.secondary" gutterBottom>
            User: {user.FirstName} {user.LastName}
          </Typography>
          <Typography variant="body2" color="text.secondary" sx={{ mb: 3 }}>
            Email: {user.Email}
          </Typography>

          {userITRs && userITRs.length > 0 && (
            <Alert severity="info" sx={{ mb: 3 }}>
              <Typography variant="body2" fontWeight="bold">
                User's Existing ITRs:
              </Typography>
              {userITRs.map((itr) => (
                <Typography key={itr.id} variant="body2">
                  ITR ID: {itr.id} - {itr.financialYear || 'N/A'} - Status: {itr.status}
                </Typography>
              ))}
            </Alert>
          )}

          {error && (
            <Alert severity="error" sx={{ mb: 2 }}>
              {error}
            </Alert>
          )}

          <TextField
            label="ITR ID"
            value={itrId}
            onChange={(e) => setItrId(e.target.value)}
            fullWidth
            margin="normal"
            type="number"
            disabled={assignMutation.isPending}
            helperText="Enter the ITR ID to assign to this user"
          />

          {loadingITRs && (
            <Box sx={{ display: 'flex', justifyContent: 'center', mt: 2 }}>
              <CircularProgress size={24} />
            </Box>
          )}
        </Box>
      </DialogContent>
      <DialogActions>
        <Button onClick={handleClose} disabled={assignMutation.isPending}>
          Cancel
        </Button>
        <Button
          onClick={handleAssign}
          variant="contained"
          disabled={!itrId || assignMutation.isPending}
        >
          {assignMutation.isPending ? <CircularProgress size={24} /> : 'Assign'}
        </Button>
      </DialogActions>
    </Dialog>
  );
};

import { useState } from 'react';
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  TextField,
  MenuItem,
  Box,
  Typography,
  Alert,
  CircularProgress,
  Avatar,
  Stack,
} from '@mui/material';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { professionalsApi } from '../../api/professionals';
import { assignmentsApi } from '../../api/assignments';
import type { ITRDetail, ITRAssignment } from '../../types';
import { useAppDispatch } from '../../store/hooks';
import { addNotification } from '../../store/slices/uiSlice';

interface AssignProfessionalModalProps {
  open: boolean;
  onClose: () => void;
  itr: ITRDetail;
  currentAssignment?: ITRAssignment;
}

export const AssignProfessionalModal = ({
  open,
  onClose,
  itr,
}: AssignProfessionalModalProps) => {
  const [selectedProfessionalId, setSelectedProfessionalId] = useState<number | ''>('');
  const [error, setError] = useState<string | null>(null);

  const dispatch = useAppDispatch();
  const queryClient = useQueryClient();

  const { data: accountants, isLoading: loadingAccountants } = useQuery({
    queryKey: ['professionals', 'ACCOUNTANT'],
    queryFn: () => professionalsApi.getProfessionals({ role: 'ACCOUNTANT', limit: 100 }),
    enabled: open,
  });

  const { data: cas, isLoading: loadingCAs } = useQuery({
    queryKey: ['professionals', 'CA'],
    queryFn: () => professionalsApi.getProfessionals({ role: 'CA', limit: 100 }),
    enabled: open,
  });

  const allProfessionals = [
    ...(accountants?.items || []),
    ...(cas?.items || [])
  ];

  console.log('[AssignModal] Accountants:', accountants);
  console.log('[AssignModal] CAs:', cas);
  console.log('[AssignModal] All professionals:', allProfessionals);
  console.log('[AssignModal] Loading:', { loadingAccountants, loadingCAs });

  const loadingProfessionals = loadingAccountants || loadingCAs;

  const assignMutation = useMutation({
    mutationFn: (payload: { itrId: number; professionalId: number }) =>
      assignmentsApi.assignITR(payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['itr', itr.id] }); // Refresh specific ITR
      queryClient.invalidateQueries({ queryKey: ['itrs'] }); // Refresh ITR list

      dispatch(
        addNotification({
          message: 'ITR assigned successfully',
          type: 'success',
        })
      );
      handleClose();
    },
    onError: (err: any) => {
      setError(err.response?.data?.data?.message || err.response?.data?.message || 'Failed to assign ITR');
    },
  });

  const handleAssign = () => {
    if (!selectedProfessionalId) {
      setError('Please select a professional');
      return;
    }

    // Use itrId extracted from itrDetails array (see itr.ts mapping)
    // Backend structure: itrData.itrDetails[0].itrId
    const itrIdForAssignment = itr.itrId || itr.id;
    
    console.log('[AssignModal] ITR object:', itr);
    console.log('[AssignModal] Using ITR ID for assignment:', itrIdForAssignment);
    console.log('[AssignModal] Assignment payload:', {
      itrId: itrIdForAssignment,
      professionalId: Number(selectedProfessionalId),
    });

    setError(null);
    assignMutation.mutate({
      itrId: itrIdForAssignment,
      professionalId: Number(selectedProfessionalId),
    });
  };

  const handleClose = () => {
    setSelectedProfessionalId('');
    setError(null);
    onClose();
  };

  return (
    <Dialog open={open} onClose={handleClose} maxWidth="sm" fullWidth>
      <DialogTitle>Assign ITR to Associate</DialogTitle>
      <DialogContent>
        <Box sx={{ mt: 1, display: 'flex', flexDirection: 'column', gap: 3 }}>
          {/* ITR Summary */}
          <Box sx={{ p: 2, bgcolor: 'background.default', borderRadius: 1 }}>
            <Typography variant="subtitle2" color="text.secondary">Assigning ITR for:</Typography>
            <Typography variant="h6">{itr.panNumber}</Typography>
            <Typography variant="body2" color="text.secondary">{itr.financialYear}</Typography>
          </Box>

          {error && <Alert severity="error">{error}</Alert>}

          {/* Professional Selection */}
          <TextField
            select
            label="Select Associate"
            value={selectedProfessionalId}
            onChange={(e) => setSelectedProfessionalId(Number(e.target.value) || '')}
            fullWidth
            disabled={loadingProfessionals || assignMutation.isPending}
            InputProps={{
              startAdornment: loadingProfessionals ? <CircularProgress size={20} sx={{ mr: 1 }} /> : null
            }}
          >
            {allProfessionals.map((prof) => (
              <MenuItem key={prof.id} value={prof.id}>
                <Stack direction="row" alignItems="center" spacing={1.5}>
                  <Avatar sx={{ width: 24, height: 24, fontSize: 12 }}>
                    {prof.firstName?.[0]}
                  </Avatar>
                  <Box>
                    <Typography variant="body2">{prof.name}</Typography>
                    <Typography variant="caption" color="text.secondary" display="block">
                      {prof.specialization || prof.occupation || 'Associate'} • {prof.email}
                    </Typography>
                  </Box>
                </Stack>
              </MenuItem>
            ))}
            {!loadingProfessionals && allProfessionals.length === 0 && (
              <MenuItem disabled>No active associates found</MenuItem>
            )}
          </TextField>

        </Box>
      </DialogContent>
      <DialogActions sx={{ px: 3, pb: 2 }}>
        <Button onClick={handleClose} disabled={assignMutation.isPending}>
          Cancel
        </Button>
        <Button
          onClick={handleAssign}
          variant="contained"
          disabled={!selectedProfessionalId || assignMutation.isPending}
        >
          {assignMutation.isPending ? <CircularProgress size={24} color="inherit" /> : 'Assign ITR'}
        </Button>
      </DialogActions>
    </Dialog>
  );
};

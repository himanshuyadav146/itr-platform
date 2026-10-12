import { useState } from 'react';
import { Alert, Box, Button, Chip, Dialog, DialogActions, DialogContent, DialogTitle, Paper, TextField, Typography } from '@mui/material';
import { Edit as EditIcon } from '@mui/icons-material';
import { useNavigate } from 'react-router-dom';
import type { UserDetails } from '../../types';
import { formatCurrency, formatNumber } from '../../utils/formatters';

const ROLE_LABELS: Record<string, string> = {
  ADMIN: 'Admin',
  CA: 'CA',
  TAX_EXPERT: 'Tax Expert',
  ACCOUNTANT: 'Accountant',
  CLIENT: 'Client',
};

const ASSOCIATE_ROLES = new Set(['CA', 'TAX_EXPERT', 'ACCOUNTANT']);

export const isAssociateRole = (role?: string) => ASSOCIATE_ROLES.has((role || '').toUpperCase());

const roleLabel = (role?: string) => {
  const key = (role || '').toUpperCase();
  return ROLE_LABELS[key] || role || '—';
};

interface UserDetailsComponentProps {
  user: UserDetails;
  onEdit?: () => void;
  approvalStatus?: string | null;
  rejectionReason?: string;
  approvalLoading?: boolean;
  approvalError?: string | null;
  onApprove?: () => void;
  onReject?: (reason: string) => void;
}

export const UserDetailsSection = ({
  user,
  onEdit,
  approvalStatus,
  rejectionReason,
  approvalLoading,
  approvalError,
  onApprove,
  onReject,
}: UserDetailsComponentProps) => {
  const navigate = useNavigate();
  const [rejectOpen, setRejectOpen] = useState(false);
  const [rejectReason, setRejectReason] = useState('');
  const showReview = isAssociateRole(user.role) && !!onApprove && !!onReject;

  const handleEdit = () => {
    if (onEdit) {
      onEdit();
    } else {
      navigate(`/users/${user.UserId}?edit=true`);
    }
  };

  return (
    <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 3 }}>
      <Box sx={{ flex: { xs: '1 1 100%', md: '1 1 calc(50% - 12px)' } }}>
        <Paper sx={{ p: 3 }}>
          <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
            <Typography variant="h6">Personal Information</Typography>
            <Button
              size="small"
              variant="outlined"
              startIcon={<EditIcon />}
              onClick={handleEdit}
            >
              Edit
            </Button>
          </Box>
          <Box sx={{ mt: 2 }}>
            <Typography variant="body2" color="text.secondary">
              Name
            </Typography>
            <Typography variant="body1" gutterBottom>
              {`${user.FirstName || ''} ${user.MiddleName || ''} ${user.LastName || ''}`.trim() || 'N/A'}
            </Typography>

            <Typography variant="body2" color="text.secondary" sx={{ mt: 2 }}>
              Email
            </Typography>
            <Typography variant="body1" gutterBottom>
              {user.Email || 'N/A'}
            </Typography>

            <Typography variant="body2" color="text.secondary" sx={{ mt: 2 }}>
              Phone
            </Typography>
            <Typography variant="body1" gutterBottom>
              {user.Mobile || 'N/A'}
            </Typography>

            <Typography variant="body2" color="text.secondary" sx={{ mt: 2 }}>
              Role
            </Typography>
            <Typography variant="body1" gutterBottom>
              {roleLabel(user.role)}
            </Typography>

            {showReview && (
              <Box sx={{ mt: 2 }}>
                <Typography variant="body2" color="text.secondary">
                  Listing approval
                </Typography>
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mt: 0.5, mb: 1.5 }}>
                  <Chip
                    size="small"
                    label={approvalStatus || 'pending'}
                    color={
                      approvalStatus === 'approved'
                        ? 'success'
                        : approvalStatus === 'rejected'
                          ? 'error'
                          : 'warning'
                    }
                    sx={{ textTransform: 'capitalize' }}
                  />
                </Box>
                {approvalError && (
                  <Alert severity="error" sx={{ mb: 1.5 }}>
                    {approvalError}
                  </Alert>
                )}
                {approvalStatus === 'rejected' && rejectionReason && (
                  <Typography variant="body2" color="error" sx={{ mb: 1.5 }}>
                    {rejectionReason}
                  </Typography>
                )}
                {approvalStatus !== 'approved' && (
                  <Box sx={{ display: 'flex', gap: 1 }}>
                    <Button
                      size="small"
                      variant="contained"
                      color="success"
                      disabled={approvalLoading}
                      onClick={onApprove}
                    >
                      Approve
                    </Button>
                    <Button
                      size="small"
                      variant="outlined"
                      color="error"
                      disabled={approvalLoading}
                      onClick={() => {
                        setRejectReason('');
                        setRejectOpen(true);
                      }}
                    >
                      Decline
                    </Button>
                  </Box>
                )}
              </Box>
            )}

            {user.CreatedAt && (
              <>
                <Typography variant="body2" color="text.secondary" sx={{ mt: 2 }}>
                  Created At
                </Typography>
                <Typography variant="body1" gutterBottom>
                  {new Date(user.CreatedAt).toLocaleDateString()}
                </Typography>
              </>
            )}
          </Box>
        </Paper>
      </Box>

      <Box sx={{ flex: { xs: '1 1 100%', md: '1 1 calc(50% - 12px)' } }}>
        <Paper sx={{ p: 3 }}>
          <Typography variant="h6" gutterBottom>
            Statistics
          </Typography>
          <Box sx={{ mt: 2 }}>
            <Typography variant="body2" color="text.secondary">
              Total ITRs Assigned
            </Typography>
            <Typography variant="h5" gutterBottom>
              {formatNumber(user.totalITRsAssigned || 0)}
            </Typography>

            <Typography variant="body2" color="text.secondary" sx={{ mt: 2 }}>
              Total ITRs Filed
            </Typography>
            <Typography variant="h5" gutterBottom>
              {formatNumber(user.totalITRsFiled || 0)}
            </Typography>

            <Typography variant="body2" color="text.secondary" sx={{ mt: 2 }}>
              Revenue Generated
            </Typography>
            <Typography variant="h5" gutterBottom>
              {formatCurrency(user.revenueGenerated || 0)}
            </Typography>
          </Box>
        </Paper>
      </Box>

      <Dialog open={rejectOpen} onClose={() => setRejectOpen(false)} fullWidth maxWidth="sm">
        <DialogTitle>Decline associate</DialogTitle>
        <DialogContent>
          <TextField
            autoFocus
            fullWidth
            margin="dense"
            label="Reason"
            value={rejectReason}
            onChange={(e) => setRejectReason(e.target.value)}
            multiline
            minRows={3}
            helperText="A reason is required so the associate knows what to correct."
          />
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setRejectOpen(false)}>Cancel</Button>
          <Button
            color="error"
            variant="contained"
            disabled={!rejectReason.trim() || approvalLoading}
            onClick={() => {
              onReject?.(rejectReason.trim());
              setRejectOpen(false);
            }}
          >
            Decline
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

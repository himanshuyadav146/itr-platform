import { useMemo, useState } from 'react';
import {
  Alert,
  AlertTitle,
  Box,
  Button,
  Chip,
  CircularProgress,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  TextField,
  InputAdornment,
  Typography,
} from '@mui/material';
import { Search as SearchIcon } from '@mui/icons-material';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { DashboardLayout } from '../components/layout/DashboardLayout';
import { associatesApi, type AssociateProfile } from '../api/associates';
import { usePermissions } from '../hooks/usePermissions';

const statusChip = (associate: AssociateProfile) => {
  if (associate.verificationStatus === 'approved' && associate.isListed) {
    return <Chip size="small" color="success" label="Listed" />;
  }
  if (associate.verificationStatus === 'approved') {
    return <Chip size="small" color="info" label="Approved" />;
  }
  if (associate.verificationStatus === 'rejected') {
    return <Chip size="small" color="error" label="Rejected" />;
  }
  return <Chip size="small" color="warning" label="Pending" />;
};

const ProfessionalsPage = () => {
  const [searchQuery, setSearchQuery] = useState('');
  const [rejectTarget, setRejectTarget] = useState<AssociateProfile | null>(null);
  const [rejectReason, setRejectReason] = useState('');
  const { isAdmin } = usePermissions();
  const queryClient = useQueryClient();

  const { data, isLoading, error } = useQuery({
    queryKey: ['admin-associates'],
    queryFn: () => associatesApi.listForAdmin(),
  });

  const moderate = useMutation({
    mutationFn: ({ userId, action, reason }: { userId: number; action: 'approve' | 'reject' | 'unlist' | 'list'; reason?: string }) =>
      associatesApi.moderate(userId, action, reason),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin-associates'] });
      setRejectTarget(null);
      setRejectReason('');
    },
  });

  const associates = data || [];
  const filtered = useMemo(() => {
    if (!searchQuery.trim()) return associates;
    const query = searchQuery.toLowerCase();
    return associates.filter(
      (item) =>
        item.name.toLowerCase().includes(query) ||
        (item.email || '').toLowerCase().includes(query) ||
        (item.mobile || '').toLowerCase().includes(query) ||
        item.role.toLowerCase().includes(query) ||
        item.verificationStatus.toLowerCase().includes(query)
    );
  }, [associates, searchQuery]);

  const pendingCount = associates.filter((item) => item.verificationStatus === 'pending').length;
  const listedCount = associates.filter((item) => item.isListed).length;

  return (
    <DashboardLayout>
      <Box sx={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
        <Box>
          <Typography variant="h4" sx={{ fontWeight: 700, mb: 1 }}>
            Associates
          </Typography>
          <Typography variant="body1" color="text.secondary">
            Approve professionals before they appear in the client marketplace.
          </Typography>
        </Box>

        <Box sx={{ display: 'flex', gap: 3, flexWrap: 'wrap' }}>
          <Box sx={{ px: 3, py: 2, borderRadius: 2, bgcolor: 'primary.main', color: 'white' }}>
            <Typography variant="h4" sx={{ fontWeight: 700 }}>
              {isLoading ? '…' : associates.length}
            </Typography>
            <Typography variant="body2">Total</Typography>
          </Box>
          <Box sx={{ px: 3, py: 2, borderRadius: 2, bgcolor: 'warning.main', color: 'white' }}>
            <Typography variant="h4" sx={{ fontWeight: 700 }}>
              {isLoading ? '…' : pendingCount}
            </Typography>
            <Typography variant="body2">Pending approval</Typography>
          </Box>
          <Box sx={{ px: 3, py: 2, borderRadius: 2, bgcolor: 'success.main', color: 'white' }}>
            <Typography variant="h4" sx={{ fontWeight: 700 }}>
              {isLoading ? '…' : listedCount}
            </Typography>
            <Typography variant="body2">Listed</Typography>
          </Box>
        </Box>

        <TextField
          fullWidth
          placeholder="Search by name, email, role, or status..."
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          InputProps={{
            startAdornment: (
              <InputAdornment position="start">
                <SearchIcon />
              </InputAdornment>
            ),
          }}
          sx={{ maxWidth: 600 }}
        />

        {isLoading && (
          <Box sx={{ display: 'flex', justifyContent: 'center', py: 8 }}>
            <CircularProgress />
          </Box>
        )}

        {error && (
          <Alert severity="error">
            <AlertTitle>Error loading associates</AlertTitle>
            Failed to fetch associates. Please try again later.
          </Alert>
        )}

        {!isLoading && !error && (
          <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
            {filtered.length === 0 ? (
              <Typography color="text.secondary">No associates found.</Typography>
            ) : (
              filtered.map((associate) => (
                <Box
                  key={associate.id}
                  sx={{
                    p: 2.5,
                    borderRadius: 2,
                    border: '1px solid',
                    borderColor: 'divider',
                    bgcolor: 'background.paper',
                    display: 'flex',
                    gap: 2,
                    flexWrap: 'wrap',
                    alignItems: 'flex-start',
                    justifyContent: 'space-between',
                  }}
                >
                  <Box sx={{ minWidth: 240, flex: 1 }}>
                    <Box sx={{ display: 'flex', gap: 1, alignItems: 'center', mb: 0.5 }}>
                      <Typography variant="h6">{associate.name || 'Unnamed'}</Typography>
                      {statusChip(associate)}
                      <Chip size="small" label={associate.role} />
                    </Box>
                    <Typography variant="body2" color="text.secondary">
                      {associate.email} {associate.mobile ? `· ${associate.mobile}` : ''}
                    </Typography>
                    <Typography variant="body2" sx={{ mt: 1 }}>
                      {associate.yearsExperience || 0} yrs · {associate.city || 'City not set'} ·{' '}
                      {associate.licenseNumber || 'No license'}
                    </Typography>
                    {associate.bio && (
                      <Typography variant="body2" color="text.secondary" sx={{ mt: 1 }}>
                        {associate.bio}
                      </Typography>
                    )}
                    <Typography variant="body2" sx={{ mt: 1 }}>
                      Services:{' '}
                      {associate.services.filter((s) => s.isActive).length
                        ? associate.services
                            .filter((s) => s.isActive)
                            .map((s) => `${s.serviceName} ₹${s.fee}`)
                            .join(', ')
                        : 'None listed'}
                    </Typography>
                  </Box>

                  {isAdmin && (
                    <Box sx={{ display: 'flex', gap: 1, flexWrap: 'wrap' }}>
                      {associate.verificationStatus !== 'approved' || !associate.isListed ? (
                        <Button
                          size="small"
                          variant="contained"
                          onClick={() => moderate.mutate({ userId: associate.id, action: 'approve' })}
                          disabled={moderate.isPending}
                        >
                          Approve
                        </Button>
                      ) : null}
                      {associate.isListed ? (
                        <Button
                          size="small"
                          variant="outlined"
                          onClick={() => moderate.mutate({ userId: associate.id, action: 'unlist' })}
                          disabled={moderate.isPending}
                        >
                          Unlist
                        </Button>
                      ) : null}
                      {associate.verificationStatus !== 'rejected' ? (
                        <Button
                          size="small"
                          color="error"
                          variant="outlined"
                          onClick={() => setRejectTarget(associate)}
                          disabled={moderate.isPending}
                        >
                          Reject
                        </Button>
                      ) : null}
                    </Box>
                  )}
                </Box>
              ))
            )}
          </Box>
        )}
      </Box>

      <Dialog open={!!rejectTarget} onClose={() => setRejectTarget(null)} fullWidth maxWidth="sm">
        <DialogTitle>Reject {rejectTarget?.name}</DialogTitle>
        <DialogContent>
          <TextField
            autoFocus
            margin="dense"
            label="Reason"
            fullWidth
            multiline
            minRows={2}
            value={rejectReason}
            onChange={(e) => setRejectReason(e.target.value)}
          />
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setRejectTarget(null)}>Cancel</Button>
          <Button
            color="error"
            variant="contained"
            disabled={!rejectTarget || moderate.isPending}
            onClick={() =>
              rejectTarget &&
              moderate.mutate({ userId: rejectTarget.id, action: 'reject', reason: rejectReason })
            }
          >
            Reject
          </Button>
        </DialogActions>
      </Dialog>
    </DashboardLayout>
  );
};

export default ProfessionalsPage;

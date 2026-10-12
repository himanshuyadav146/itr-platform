import { useMemo, useState } from 'react';
import {
  Alert,
  Box,
  Button,
  Chip,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  Grid,
  Paper,
  Tab,
  Tabs,
  TextField,
  Typography,
} from '@mui/material';
import { DataGrid, type GridColDef } from '@mui/x-data-grid';
import {
  CheckCircle as ApprovedIcon,
  HourglassEmpty as PendingIcon,
  Cancel as RejectedIcon,
  VisibilityOff as UnlistedIcon,
} from '@mui/icons-material';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { DashboardLayout } from '../components/layout/DashboardLayout';
import { KPICard } from '../components/dashboard/KPICard';
import { associatesApi, type AssociateApprovalStatus, type AssociateProfile } from '../api/associates';
import { useAuth } from '../hooks/useAuth';
import { UserRole } from '../types/enums';

const statusColor = (status: AssociateApprovalStatus) => {
  if (status === 'approved') return 'success';
  if (status === 'rejected') return 'error';
  if (status === 'unlisted') return 'default';
  return 'warning';
};

const ProfessionalsPage = () => {
  const { role } = useAuth();
  const isAdmin = role === UserRole.ADMIN;
  const queryClient = useQueryClient();
  const [tab, setTab] = useState<AssociateApprovalStatus | 'all'>('pending');
  const [search, setSearch] = useState('');
  const [review, setReview] = useState<AssociateProfile | null>(null);
  const [rejectReason, setRejectReason] = useState('');
  const [actionError, setActionError] = useState<string | null>(null);

  const { data, isLoading, error } = useQuery({
    queryKey: ['associate-approvals', tab, search],
    queryFn: () =>
      associatesApi.list({
        status: tab,
        search: search || undefined,
        limit: 200,
      }),
    enabled: isAdmin,
  });

  const detailQuery = useQuery({
    queryKey: ['associate-detail', review?.user_id],
    queryFn: () => associatesApi.get(review!.user_id),
    enabled: !!review?.user_id,
  });

  const decide = useMutation({
    mutationFn: ({ userId, action, reason }: { userId: number; action: 'approve' | 'reject' | 'unlist'; reason?: string }) =>
      associatesApi.decide(userId, action, reason),
    onSuccess: () => {
      setActionError(null);
      setRejectReason('');
      setReview(null);
      queryClient.invalidateQueries({ queryKey: ['associate-approvals'] });
    },
    onError: (err: any) => {
      setActionError(err?.response?.data?.data?.message || 'Could not update associate status');
    },
  });

  const kpis = data?.kpis || { pending: 0, approved: 0, rejected: 0, unlisted: 0 };
  const rows = data?.associates || [];
  const reviewed = detailQuery.data || review;

  const columns: GridColDef[] = useMemo(
    () => [
      { field: 'name', headerName: 'Associate', flex: 1.2, minWidth: 180 },
      { field: 'role', headerName: 'Role', width: 130 },
      { field: 'icai_membership_no', headerName: 'ICAI / Membership', flex: 1, minWidth: 150 },
      { field: 'city', headerName: 'City', width: 130 },
      { field: 'years_experience', headerName: 'Yrs', width: 80, type: 'number' },
      {
        field: 'approval_status',
        headerName: 'Status',
        width: 130,
        renderCell: (params) => (
          <Chip size="small" label={params.value} color={statusColor(params.value)} sx={{ textTransform: 'capitalize' }} />
        ),
      },
      { field: 'created_at', headerName: 'Submitted', width: 160 },
      {
        field: 'actions',
        headerName: 'Actions',
        width: 280,
        sortable: false,
        renderCell: (params) => {
          const row = params.row as AssociateProfile;
          return (
            <Box sx={{ display: 'flex', gap: 1, alignItems: 'center' }}>
              <Button size="small" onClick={() => setReview(row)}>
                Review
              </Button>
              {row.approval_status === 'pending' && (
                <>
                  <Button
                    size="small"
                    color="success"
                    variant="contained"
                    onClick={() => decide.mutate({ userId: row.user_id, action: 'approve' })}
                  >
                    Approve
                  </Button>
                  <Button size="small" color="error" onClick={() => setReview(row)}>
                    Reject
                  </Button>
                </>
              )}
              {row.approval_status === 'approved' && (
                <Button size="small" color="inherit" onClick={() => decide.mutate({ userId: row.user_id, action: 'unlist' })}>
                  Unlist
                </Button>
              )}
            </Box>
          );
        },
      },
    ],
    [decide]
  );

  if (!isAdmin) {
    return (
      <DashboardLayout>
        <Alert severity="info">Only admins can review associate credentials. Open My Profile to update your listing.</Alert>
      </DashboardLayout>
    );
  }

  return (
    <DashboardLayout>
      <Box sx={{ display: 'flex', flexDirection: 'column', gap: 3 }}>
        <Box>
          <Typography variant="h4" sx={{ fontWeight: 700, mb: 0.5 }}>
            Associate Approvals Queue
          </Typography>
          <Typography variant="body1" color="text.secondary">
            Review ICAI credentials and listed fees before an associate appears in client booking.
          </Typography>
        </Box>

        <Grid container spacing={2}>
          <Grid size={{ xs: 12, sm: 6, md: 3 }}>
            <KPICard title="Pending" value={kpis.pending} icon={<PendingIcon />} color="warning" selected={tab === 'pending'} onClick={() => setTab('pending')} />
          </Grid>
          <Grid size={{ xs: 12, sm: 6, md: 3 }}>
            <KPICard title="Approved" value={kpis.approved} icon={<ApprovedIcon />} color="success" selected={tab === 'approved'} onClick={() => setTab('approved')} />
          </Grid>
          <Grid size={{ xs: 12, sm: 6, md: 3 }}>
            <KPICard title="Rejected" value={kpis.rejected} icon={<RejectedIcon />} color="error" selected={tab === 'rejected'} onClick={() => setTab('rejected')} />
          </Grid>
          <Grid size={{ xs: 12, sm: 6, md: 3 }}>
            <KPICard title="Unlisted" value={kpis.unlisted} icon={<UnlistedIcon />} color="info" selected={tab === 'unlisted'} onClick={() => setTab('unlisted')} />
          </Grid>
        </Grid>

        <Paper sx={{ p: 2 }}>
          <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 2, alignItems: 'center', mb: 2 }}>
            <Tabs
              value={tab}
              onChange={(_e, value) => setTab(value)}
              sx={{ minHeight: 40, '& .MuiTab-root': { textTransform: 'none', fontWeight: 600 } }}
            >
              <Tab value="pending" label="Pending" />
              <Tab value="approved" label="Approved" />
              <Tab value="rejected" label="Rejected" />
              <Tab value="unlisted" label="Unlisted" />
              <Tab value="all" label="All" />
            </Tabs>
            <TextField
              size="small"
              placeholder="Search name, email, ICAI, city"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              sx={{ ml: 'auto', minWidth: 280 }}
            />
          </Box>

          {error && (
            <Alert severity="error" sx={{ mb: 2 }}>
              Could not load the approvals queue. Confirm the associate marketplace migration has run.
            </Alert>
          )}

          <DataGrid
            autoHeight
            rows={rows}
            columns={columns}
            getRowId={(row) => row.user_id}
            loading={isLoading || decide.isPending}
            pageSizeOptions={[10, 25, 50]}
            initialState={{ pagination: { paginationModel: { pageSize: 10 } } }}
            disableRowSelectionOnClick
            sx={{
              border: 0,
              '& .MuiDataGrid-columnHeaders': { backgroundColor: '#f8fafc', fontWeight: 700 },
            }}
          />
        </Paper>
      </Box>

      <Dialog open={!!review} onClose={() => setReview(null)} maxWidth="md" fullWidth>
        <DialogTitle>Review &amp; vetting</DialogTitle>
        <DialogContent dividers>
          {actionError && (
            <Alert severity="error" sx={{ mb: 2 }}>
              {actionError}
            </Alert>
          )}
          {reviewed && (
            <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', sm: '1fr 1fr' }, gap: 2 }}>
              <Typography><strong>Name:</strong> {reviewed.name}</Typography>
              <Typography><strong>Role:</strong> {reviewed.role}</Typography>
              <Typography><strong>Email:</strong> {reviewed.email}</Typography>
              <Typography><strong>Mobile:</strong> {reviewed.mobile}</Typography>
              <Typography><strong>ICAI / Membership:</strong> {reviewed.icai_membership_no || '—'}</Typography>
              <Typography><strong>GSTIN:</strong> {reviewed.gstin || '—'}</Typography>
              <Typography><strong>PAN:</strong> {reviewed.pan || '—'}</Typography>
              <Typography><strong>Location:</strong> {[reviewed.city, reviewed.state].filter(Boolean).join(', ') || '—'}</Typography>
              <Typography><strong>Experience:</strong> {reviewed.years_experience || 0} years</Typography>
              <Typography><strong>Status:</strong> {reviewed.approval_status}</Typography>
              <Typography sx={{ gridColumn: '1 / -1' }}><strong>Bio:</strong> {reviewed.bio || '—'}</Typography>
              {reviewed.rejection_reason && (
                <Typography sx={{ gridColumn: '1 / -1' }} color="error">
                  <strong>Rejection reason:</strong> {reviewed.rejection_reason}
                </Typography>
              )}
              <Box sx={{ gridColumn: '1 / -1' }}>
                <Typography sx={{ fontWeight: 700, mb: 1 }}>Listed services &amp; fees</Typography>
                {(reviewed.services || []).length === 0 ? (
                  <Typography color="text.secondary">No fees listed yet.</Typography>
                ) : (
                  (reviewed.services || []).map((fee) => (
                    <Typography key={fee.service_id}>
                      {fee.service_name}: ₹{fee.listed_fee ?? 0} {fee.is_active ? '' : '(inactive)'}
                    </Typography>
                  ))
                )}
              </Box>
              {reviewed.approval_status === 'pending' && (
                <TextField
                  sx={{ gridColumn: '1 / -1' }}
                  label="Rejection reason (required to reject)"
                  value={rejectReason}
                  onChange={(e) => setRejectReason(e.target.value)}
                  multiline
                  minRows={2}
                />
              )}
            </Box>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setReview(null)}>Close</Button>
          {reviewed?.approval_status === 'approved' && (
            <Button onClick={() => decide.mutate({ userId: reviewed.user_id, action: 'unlist' })}>Unlist</Button>
          )}
          {reviewed?.approval_status === 'pending' && (
            <>
              <Button
                color="error"
                onClick={() => decide.mutate({ userId: reviewed.user_id, action: 'reject', reason: rejectReason })}
              >
                Reject
              </Button>
              <Button
                variant="contained"
                color="success"
                onClick={() => decide.mutate({ userId: reviewed.user_id, action: 'approve' })}
              >
                Approve &amp; list
              </Button>
            </>
          )}
        </DialogActions>
      </Dialog>
    </DashboardLayout>
  );
};

export default ProfessionalsPage;

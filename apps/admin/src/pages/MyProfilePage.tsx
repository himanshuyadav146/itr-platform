import { useEffect, useState } from 'react';
import {
  Alert,
  Box,
  Button,
  Chip,
  Paper,
  Tab,
  Tabs,
  TextField,
  Typography,
} from '@mui/material';
import { DataGrid, type GridColDef } from '@mui/x-data-grid';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { DashboardLayout } from '../components/layout/DashboardLayout';
import { associatesApi, type AssociateProfile, type AssociateServiceFee } from '../api/associates';
import { usePermissions } from '../hooks/usePermissions';

const emptyProfile: Partial<AssociateProfile> = {
  icai_membership_no: '',
  gstin: '',
  pan: '',
  city: '',
  state: '',
  bio: '',
  years_experience: 0,
};

const MyProfilePage = () => {
  const { isProfessional, isAdmin } = usePermissions();
  const queryClient = useQueryClient();
  const [tab, setTab] = useState(0);
  const [form, setForm] = useState(emptyProfile);
  const [fees, setFees] = useState<AssociateServiceFee[]>([]);
  const [message, setMessage] = useState<string | null>(null);

  const profileQuery = useQuery({
    queryKey: ['my-associate-profile'],
    queryFn: () => associatesApi.getProfile(),
    enabled: isProfessional || isAdmin,
  });

  const servicesQuery = useQuery({
    queryKey: ['my-associate-services'],
    queryFn: () => associatesApi.getMyServices(),
    enabled: isProfessional || isAdmin,
  });

  useEffect(() => {
    if (profileQuery.data) {
      setForm({
        icai_membership_no: profileQuery.data.icai_membership_no || '',
        gstin: profileQuery.data.gstin || '',
        pan: profileQuery.data.pan || '',
        city: profileQuery.data.city || '',
        state: profileQuery.data.state || '',
        bio: profileQuery.data.bio || '',
        years_experience: profileQuery.data.years_experience || 0,
        role: profileQuery.data.role,
      });
    }
  }, [profileQuery.data]);

  useEffect(() => {
    if (servicesQuery.data) {
      setFees(servicesQuery.data);
    }
  }, [servicesQuery.data]);

  const saveProfile = useMutation({
    mutationFn: () => associatesApi.saveProfile(form),
    onSuccess: (res) => {
      setMessage(res.message);
      queryClient.invalidateQueries({ queryKey: ['my-associate-profile'] });
    },
  });

  const saveFees = useMutation({
    mutationFn: () => associatesApi.saveMyServices(fees),
    onSuccess: (res) => {
      setMessage(res.message);
      queryClient.invalidateQueries({ queryKey: ['my-associate-services'] });
    },
  });

  const status = profileQuery.data?.approval_status || 'pending';

  const feeColumns: GridColDef[] = [
    { field: 'service_name', headerName: 'Service', flex: 1, minWidth: 180 },
    {
      field: 'listed_fee',
      headerName: 'Your listed fee (₹)',
      flex: 1,
      minWidth: 180,
      renderCell: (params) => (
        <TextField
          size="small"
          type="number"
          value={params.row.listed_fee ?? ''}
          onChange={(e) => {
            const value = e.target.value === '' ? null : Number(e.target.value);
            setFees((prev) =>
              prev.map((row) =>
                row.service_id === params.row.service_id ? { ...row, listed_fee: value, is_active: value != null && value > 0 } : row
              )
            );
          }}
        />
      ),
    },
    {
      field: 'is_active',
      headerName: 'Listed',
      width: 120,
      renderCell: (params) => (
        <Chip size="small" color={params.row.is_active ? 'success' : 'default'} label={params.row.is_active ? 'Yes' : 'No'} />
      ),
    },
  ];

  if (!isProfessional && !isAdmin) {
    return (
      <DashboardLayout>
        <Alert severity="info">My Profile is for CAs, accountants, and tax experts.</Alert>
      </DashboardLayout>
    );
  }

  return (
    <DashboardLayout>
      <Box sx={{ display: 'flex', flexDirection: 'column', gap: 3 }}>
        <Box>
          <Typography variant="h4" sx={{ fontWeight: 700, mb: 0.5 }}>
            My Profile &amp; Credentials
          </Typography>
          <Typography variant="body1" color="text.secondary">
            Keep ICAI details current. Clients only see you after an admin approves this profile.
          </Typography>
        </Box>

        <Chip
          color={status === 'approved' ? 'success' : status === 'rejected' ? 'error' : 'warning'}
          label={`Listing status: ${status}`}
          sx={{ alignSelf: 'flex-start', textTransform: 'capitalize', fontWeight: 600 }}
        />

        {status === 'rejected' && profileQuery.data?.rejection_reason && (
          <Alert severity="error">Rejected: {profileQuery.data.rejection_reason}</Alert>
        )}
        {status === 'pending' && (
          <Alert severity="info">Your profile is pending review. Complete credentials and fees, then wait for listing approval.</Alert>
        )}
        {message && <Alert severity="success">{message}</Alert>}
        {profileQuery.error && (
          <Alert severity="warning">No profile yet — save credentials to create one.</Alert>
        )}

        <Paper>
          <Tabs value={tab} onChange={(_e, value) => setTab(value)} sx={{ px: 2, '& .MuiTab-root': { textTransform: 'none', fontWeight: 600 } }}>
            <Tab label="Credentials" />
            <Tab label="My Services & Fees" />
          </Tabs>

          {tab === 0 && (
            <Box sx={{ p: 3, display: 'grid', gridTemplateColumns: { xs: '1fr', sm: '1fr 1fr' }, gap: 2 }}>
              <TextField
                label="ICAI membership no."
                value={form.icai_membership_no || ''}
                onChange={(e) => setForm({ ...form, icai_membership_no: e.target.value })}
              />
              <TextField label="GSTIN" value={form.gstin || ''} onChange={(e) => setForm({ ...form, gstin: e.target.value })} />
              <TextField label="PAN" value={form.pan || ''} onChange={(e) => setForm({ ...form, pan: e.target.value.toUpperCase() })} />
              <TextField
                label="Years of experience"
                type="number"
                value={form.years_experience ?? 0}
                onChange={(e) => setForm({ ...form, years_experience: Number(e.target.value) })}
              />
              <TextField label="City" value={form.city || ''} onChange={(e) => setForm({ ...form, city: e.target.value })} />
              <TextField label="State" value={form.state || ''} onChange={(e) => setForm({ ...form, state: e.target.value })} />
              <TextField
                sx={{ gridColumn: '1 / -1' }}
                label="Professional bio"
                multiline
                minRows={4}
                value={form.bio || ''}
                onChange={(e) => setForm({ ...form, bio: e.target.value })}
              />
              <Box sx={{ gridColumn: '1 / -1' }}>
                <Button variant="contained" onClick={() => saveProfile.mutate()} disabled={saveProfile.isPending}>
                  Save credentials
                </Button>
              </Box>
            </Box>
          )}

          {tab === 1 && (
            <Box sx={{ p: 3 }}>
              <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                Set the fee clients pay you for each service. GST and platform additional fees are added at checkout.
              </Typography>
              <DataGrid
                autoHeight
                rows={fees}
                columns={feeColumns}
                getRowId={(row) => row.service_id}
                hideFooter
                disableRowSelectionOnClick
                sx={{ border: 0, mb: 2 }}
              />
              <Button variant="contained" onClick={() => saveFees.mutate()} disabled={saveFees.isPending}>
                Save fees
              </Button>
            </Box>
          )}
        </Paper>
      </Box>
    </DashboardLayout>
  );
};

export default MyProfilePage;

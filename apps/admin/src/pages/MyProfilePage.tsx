import { useEffect, useMemo, useState } from 'react';
import {
  Alert,
  Box,
  Button,
  Card,
  CardContent,
  Chip,
  CircularProgress,
  Divider,
  FormControlLabel,
  Switch,
  TextField,
  Typography,
} from '@mui/material';
import { DashboardLayout } from '../components/layout/DashboardLayout';
import { associatesApi, type AssociateProfile, type ServiceCatalogItem } from '../api/associates';
import { usePermissions } from '../hooks/usePermissions';
import { addNotification } from '../store/slices/uiSlice';
import { useAppDispatch } from '../store/hooks';

type FeeDraft = {
  serviceId: number;
  name: string;
  description?: string;
  fee: string;
  isActive: boolean;
};

const statusColor = (status?: string) => {
  if (status === 'approved') return 'success' as const;
  if (status === 'rejected') return 'error' as const;
  return 'warning' as const;
};

const MyProfilePage = () => {
  const { isProfessional, isAdmin } = usePermissions();
  const dispatch = useAppDispatch();
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [profile, setProfile] = useState<AssociateProfile | null>(null);
  const [catalog, setCatalog] = useState<ServiceCatalogItem[]>([]);
  const [form, setForm] = useState({
    bio: '',
    yearsExperience: '0',
    qualification: '',
    licenseNumber: '',
    city: '',
    languages: '',
  });
  const [fees, setFees] = useState<FeeDraft[]>([]);

  const canEdit = isProfessional || isAdmin;

  const load = async () => {
    setLoading(true);
    setError(null);
    try {
      const [nextProfile, servicesPayload] = await Promise.all([
        associatesApi.getMyProfile(),
        associatesApi.getMyServices(),
      ]);
      setProfile(nextProfile);
      setCatalog(servicesPayload.catalog);
      setForm({
        bio: nextProfile.bio || '',
        yearsExperience: String(nextProfile.yearsExperience ?? 0),
        qualification: nextProfile.qualification || '',
        licenseNumber: nextProfile.licenseNumber || '',
        city: nextProfile.city || '',
        languages: (nextProfile.languages || []).join(', '),
      });
      const saved = new Map(servicesPayload.services.map((s) => [s.serviceId, s]));
      setFees(
        (servicesPayload.catalog.length ? servicesPayload.catalog : nextProfile.services).map((item) => {
          const serviceId = 'id' in item ? item.id : item.serviceId;
          const existing = saved.get(serviceId);
          return {
            serviceId,
            name: 'name' in item ? item.name : item.serviceName,
            description: item.description,
            fee: existing ? String(existing.fee) : '0',
            isActive: existing ? existing.isActive : false,
          };
        })
      );
    } catch (err: any) {
      setError(err.response?.data?.data?.message || err.message || 'Failed to load profile');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    if (canEdit) {
      load();
    }
  }, [canEdit]);

  const statusLabel = useMemo(() => {
    if (!profile) return '';
    if (profile.verificationStatus === 'approved' && profile.isListed) return 'Listed';
    return profile.verificationStatus;
  }, [profile]);

  const handleSave = async () => {
    setSaving(true);
    setError(null);
    try {
      const updated = await associatesApi.updateMyProfile({
        bio: form.bio,
        yearsExperience: Number(form.yearsExperience) || 0,
        qualification: form.qualification,
        licenseNumber: form.licenseNumber,
        city: form.city,
        languages: form.languages,
      });
      const savedFees = await associatesApi.updateMyServices(
        fees.map((fee) => ({
          serviceId: fee.serviceId,
          fee: Number(fee.fee) || 0,
          isActive: fee.isActive,
        }))
      );
      setProfile({ ...updated, services: savedFees });
      dispatch(addNotification({ message: 'Profile saved. Admin approval is required before listing.', type: 'success' }));
    } catch (err: any) {
      setError(err.response?.data?.data?.message || err.message || 'Failed to save profile');
    } finally {
      setSaving(false);
    }
  };

  if (!canEdit) {
    return (
      <DashboardLayout>
        <Alert severity="info">My Profile is available for CA, Accountant, and Tax Expert accounts.</Alert>
      </DashboardLayout>
    );
  }

  return (
    <DashboardLayout>
      <Box sx={{ display: 'flex', flexDirection: 'column', gap: 3, maxWidth: 880 }}>
        <Box>
          <Typography variant="h4" sx={{ fontWeight: 700, mb: 1 }}>
            My Profile
          </Typography>
          <Typography color="text.secondary">
            Add experience, services, and fees. You appear on the marketplace only after admin approval.
          </Typography>
        </Box>

        {profile && (
          <Chip
            color={statusColor(profile.verificationStatus)}
            label={`Status: ${statusLabel}`}
            sx={{ alignSelf: 'flex-start', textTransform: 'capitalize' }}
          />
        )}

        {profile?.verificationStatus === 'rejected' && profile.rejectionReason && (
          <Alert severity="error">Rejected: {profile.rejectionReason}</Alert>
        )}

        {error && <Alert severity="error">{error}</Alert>}

        {loading ? (
          <Box sx={{ display: 'flex', justifyContent: 'center', py: 8 }}>
            <CircularProgress />
          </Box>
        ) : (
          <>
            <Card>
              <CardContent sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                <Typography variant="h6">Professional details</Typography>
                <TextField
                  label="Bio"
                  value={form.bio}
                  onChange={(e) => setForm((prev) => ({ ...prev, bio: e.target.value }))}
                  multiline
                  minRows={3}
                  fullWidth
                />
                <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', sm: '1fr 1fr' }, gap: 2 }}>
                  <TextField
                    label="Years of experience"
                    type="number"
                    value={form.yearsExperience}
                    onChange={(e) => setForm((prev) => ({ ...prev, yearsExperience: e.target.value }))}
                  />
                  <TextField
                    label="City"
                    value={form.city}
                    onChange={(e) => setForm((prev) => ({ ...prev, city: e.target.value }))}
                  />
                  <TextField
                    label="Qualification"
                    value={form.qualification}
                    onChange={(e) => setForm((prev) => ({ ...prev, qualification: e.target.value }))}
                  />
                  <TextField
                    label="ICAI / license number"
                    value={form.licenseNumber}
                    onChange={(e) => setForm((prev) => ({ ...prev, licenseNumber: e.target.value }))}
                  />
                </Box>
                <TextField
                  label="Languages (comma separated)"
                  value={form.languages}
                  onChange={(e) => setForm((prev) => ({ ...prev, languages: e.target.value }))}
                  fullWidth
                />
              </CardContent>
            </Card>

            <Card>
              <CardContent>
                <Typography variant="h6" sx={{ mb: 1 }}>
                  Services and fees
                </Typography>
                <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                  Enable each service you offer and set your listed fee. Clients pay this amount plus GST.
                </Typography>
                {fees.length === 0 && (
                  <Alert severity="info">
                    No services in catalog yet{catalog.length === 0 ? '.' : ''}. Ask admin to seed the services table.
                  </Alert>
                )}
                {fees.map((fee, index) => (
                  <Box key={fee.serviceId} sx={{ py: 1.5 }}>
                    {index > 0 && <Divider sx={{ mb: 1.5 }} />}
                    <Box sx={{ display: 'flex', gap: 2, alignItems: 'center', flexWrap: 'wrap' }}>
                      <Box sx={{ flex: 1, minWidth: 180 }}>
                        <Typography fontWeight={600}>{fee.name}</Typography>
                        {fee.description && (
                          <Typography variant="body2" color="text.secondary">
                            {fee.description}
                          </Typography>
                        )}
                      </Box>
                      <TextField
                        label="Fee (INR)"
                        type="number"
                        value={fee.fee}
                        onChange={(e) =>
                          setFees((prev) =>
                            prev.map((item) =>
                              item.serviceId === fee.serviceId ? { ...item, fee: e.target.value } : item
                            )
                          )
                        }
                        sx={{ width: 140 }}
                      />
                      <FormControlLabel
                        control={
                          <Switch
                            checked={fee.isActive}
                            onChange={(e) =>
                              setFees((prev) =>
                                prev.map((item) =>
                                  item.serviceId === fee.serviceId
                                    ? { ...item, isActive: e.target.checked }
                                    : item
                                )
                              )
                            }
                          />
                        }
                        label="Offer this"
                      />
                    </Box>
                  </Box>
                ))}
              </CardContent>
            </Card>

            <Button variant="contained" onClick={handleSave} disabled={saving} sx={{ alignSelf: 'flex-start' }}>
              {saving ? 'Saving…' : 'Save profile'}
            </Button>
          </>
        )}
      </Box>
    </DashboardLayout>
  );
};

export default MyProfilePage;

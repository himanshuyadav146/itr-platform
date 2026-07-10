import { useState } from 'react';
import {
  Box,
  Button,
  Paper,
  TextField,
  Typography,
  FormControlLabel,
  Switch,
  Alert,
  CircularProgress,
} from '@mui/material';
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { notificationTemplatesApi } from '../../api/notificationTemplates';
import type { NotificationSettings } from '../../types/notificationTemplate';
import { useAppDispatch } from '../../store/hooks';
import { addNotification } from '../../store/slices/uiSlice';

interface NotificationSettingsPanelProps {
  settings: NotificationSettings;
}

export const NotificationSettingsPanel = ({ settings }: NotificationSettingsPanelProps) => {
  const dispatch = useAppDispatch();
  const queryClient = useQueryClient();
  const [form, setForm] = useState(settings);

  const mutation = useMutation({
    mutationFn: () => notificationTemplatesApi.updateSettings(form),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['notification-templates'] });
      dispatch(addNotification({ message: 'Notification settings saved', type: 'success' }));
    },
    onError: () => {
      dispatch(addNotification({ message: 'Failed to save settings', type: 'error' }));
    },
  });

  return (
    <Paper sx={{ p: 3, mb: 3 }}>
      <Typography variant="h6" gutterBottom>
        Global Settings
      </Typography>
      <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
        Admin inbox and channel toggles. SMTP credentials are configured on the server in notification_config.php.
      </Typography>

      <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', md: '1fr 1fr' }, gap: 2 }}>
        <TextField
          label="Admin email"
          value={form.adminEmail}
          onChange={(e) => setForm({ ...form, adminEmail: e.target.value })}
          fullWidth
        />
        <TextField
          label="From name"
          value={form.fromName}
          onChange={(e) => setForm({ ...form, fromName: e.target.value })}
          fullWidth
        />
        <TextField
          label="From email"
          value={form.fromEmail}
          onChange={(e) => setForm({ ...form, fromEmail: e.target.value })}
          fullWidth
        />
        <TextField
          label="Admin panel URL"
          value={form.adminPanelUrl}
          onChange={(e) => setForm({ ...form, adminPanelUrl: e.target.value })}
          fullWidth
        />
      </Box>

      <Box sx={{ mt: 2, display: 'flex', gap: 3, flexWrap: 'wrap' }}>
        <FormControlLabel
          control={
            <Switch
              checked={form.emailEnabled}
              onChange={(e) => setForm({ ...form, emailEnabled: e.target.checked })}
            />
          }
          label="Email enabled"
        />
        <FormControlLabel
          control={
            <Switch
              checked={form.pushEnabled}
              onChange={(e) => setForm({ ...form, pushEnabled: e.target.checked })}
            />
          }
          label="Push enabled"
        />
      </Box>

      <Box sx={{ mt: 2, display: 'flex', alignItems: 'center', gap: 2 }}>
        <Button
          variant="contained"
          onClick={() => mutation.mutate()}
          disabled={mutation.isPending}
        >
          Save settings
        </Button>
        {mutation.isPending && <CircularProgress size={22} />}
      </Box>

      {mutation.isError && (
        <Alert severity="error" sx={{ mt: 2 }}>
          Could not save settings. Check server migration and admin permissions.
        </Alert>
      )}
    </Paper>
  );
};

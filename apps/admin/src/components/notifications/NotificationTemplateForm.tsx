import { useState } from 'react';
import {
  Alert,
  Box,
  Button,
  Chip,
  FormControl,
  InputLabel,
  MenuItem,
  Paper,
  Select,
  TextField,
  Typography,
  FormControlLabel,
  Switch,
  CircularProgress,
} from '@mui/material';
import { ArrowBack as ArrowBackIcon } from '@mui/icons-material';
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { useNavigate } from 'react-router-dom';
import { notificationTemplatesApi } from '../../api/notificationTemplates';
import type { NotificationTemplate, NotificationChannel } from '../../types/notificationTemplate';
import { NOTIFICATION_PLACEHOLDERS } from '../../types/notificationTemplate';
import { useAppDispatch } from '../../store/hooks';
import { addNotification } from '../../store/slices/uiSlice';

interface NotificationTemplateFormProps {
  template: NotificationTemplate;
}

export const NotificationTemplateForm = ({ template }: NotificationTemplateFormProps) => {
  const navigate = useNavigate();
  const dispatch = useAppDispatch();
  const queryClient = useQueryClient();
  const [error, setError] = useState<string | null>(null);

  const [form, setForm] = useState({
    channel: template.channel,
    emailSubject: template.emailSubject ?? '',
    emailBodyHtml: template.emailBodyHtml ?? '',
    emailBodyText: template.emailBodyText ?? '',
    pushTitle: template.pushTitle ?? '',
    pushBody: template.pushBody ?? '',
    pushRoute: template.pushRoute ?? '',
    isActive: template.isActive,
  });

  const mutation = useMutation({
    mutationFn: () =>
      notificationTemplatesApi.updateTemplate({
        id: template.id,
        channel: form.channel,
        emailSubject: form.emailSubject || null,
        emailBodyHtml: form.emailBodyHtml || null,
        emailBodyText: form.emailBodyText || null,
        pushTitle: form.pushTitle || null,
        pushBody: form.pushBody || null,
        pushRoute: form.pushRoute || null,
        isActive: form.isActive,
      }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['notification-templates'] });
      queryClient.invalidateQueries({ queryKey: ['notification-template', template.id] });
      dispatch(addNotification({ message: 'Template saved', type: 'success' }));
      navigate('/notification-templates');
    },
    onError: (err: unknown) => {
      const msg =
        err && typeof err === 'object' && 'response' in err
          ? (err as { response?: { data?: { data?: { message?: string } } } }).response?.data?.data?.message ??
            'Save failed'
          : 'Save failed';
      setError(msg);
    },
  });

  const showEmail = form.channel === 'EMAIL' || form.channel === 'BOTH';
  const showPush = form.channel === 'PUSH' || form.channel === 'BOTH';

  return (
    <Paper sx={{ p: 3 }}>
      <Button startIcon={<ArrowBackIcon />} onClick={() => navigate('/notification-templates')} sx={{ mb: 2 }}>
        Back to templates
      </Button>

      <Typography variant="subtitle1" gutterBottom>
        {template.eventKey} · {template.audience}
      </Typography>

      <Box sx={{ mb: 2, display: 'flex', flexWrap: 'wrap', gap: 1 }}>
        {NOTIFICATION_PLACEHOLDERS.map((ph) => (
          <Chip key={ph} label={ph} size="small" variant="outlined" />
        ))}
      </Box>

      {error && (
        <Alert severity="error" sx={{ mb: 2 }}>
          {error}
        </Alert>
      )}

      <Box sx={{ display: 'grid', gap: 2 }}>
        <FormControl fullWidth>
          <InputLabel>Channel</InputLabel>
          <Select
            label="Channel"
            value={form.channel}
            onChange={(e) => setForm({ ...form, channel: e.target.value as NotificationChannel })}
          >
            <MenuItem value="EMAIL">EMAIL</MenuItem>
            <MenuItem value="PUSH">PUSH</MenuItem>
            <MenuItem value="BOTH">BOTH</MenuItem>
          </Select>
        </FormControl>

        <FormControlLabel
          control={
            <Switch
              checked={form.isActive}
              onChange={(e) => setForm({ ...form, isActive: e.target.checked })}
            />
          }
          label="Template active"
        />

        {showEmail && (
          <>
            <TextField
              label="Email subject"
              value={form.emailSubject}
              onChange={(e) => setForm({ ...form, emailSubject: e.target.value })}
              fullWidth
            />
            <TextField
              label="Email body (HTML)"
              value={form.emailBodyHtml}
              onChange={(e) => setForm({ ...form, emailBodyHtml: e.target.value })}
              fullWidth
              multiline
              minRows={5}
            />
            <TextField
              label="Email body (plain text)"
              value={form.emailBodyText}
              onChange={(e) => setForm({ ...form, emailBodyText: e.target.value })}
              fullWidth
              multiline
              minRows={3}
            />
          </>
        )}

        {showPush && (
          <>
            <TextField
              label="Push title"
              value={form.pushTitle}
              onChange={(e) => setForm({ ...form, pushTitle: e.target.value })}
              fullWidth
            />
            <TextField
              label="Push body"
              value={form.pushBody}
              onChange={(e) => setForm({ ...form, pushBody: e.target.value })}
              fullWidth
              multiline
              minRows={2}
            />
            <TextField
              label="Push route (mobile deep link)"
              value={form.pushRoute}
              onChange={(e) => setForm({ ...form, pushRoute: e.target.value })}
              fullWidth
              placeholder="/status"
            />
          </>
        )}
      </Box>

      <Box sx={{ mt: 3, display: 'flex', gap: 2, alignItems: 'center' }}>
        <Button variant="contained" onClick={() => mutation.mutate()} disabled={mutation.isPending}>
          Save template
        </Button>
        <Button variant="outlined" onClick={() => navigate('/notification-templates')}>
          Cancel
        </Button>
        {mutation.isPending && <CircularProgress size={22} />}
      </Box>
    </Paper>
  );
};

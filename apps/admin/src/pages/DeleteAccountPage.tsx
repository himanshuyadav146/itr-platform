import { useState } from 'react';
import {
  Box,
  Container,
  Paper,
  Typography,
  Button,
  Alert,
  CircularProgress,
  List,
  ListItem,
  ListItemText,
} from '@mui/material';
import { useNavigate } from 'react-router-dom';
import { authApi } from '../api/auth';
import { useAuth } from '../hooks/useAuth';
import { gradients } from '../theme/theme';

const APP_NAME = 'ITR Admin Panel';

export default function DeleteAccountPage() {
  const navigate = useNavigate();
  const { isAuthenticated, logout } = useAuth();
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleLogin = () => {
    navigate('/login?redirect=/delete-account');
  };

  const handleDeleteAccount = async () => {
    setError(null);
    setLoading(true);
    try {
      await authApi.deleteAccount();
      logout();
      navigate('/login', { replace: true });
    } catch (err: unknown) {
      const msg =
        err && typeof err === 'object' && 'response' in err
          ? (err as { response?: { data?: { message?: string } } }).response?.data?.message ?? 'Failed to delete account'
          : 'Failed to delete account';
      setError(msg);
    } finally {
      setLoading(false);
    }
  };

  return (
    <Box
      sx={{
        minHeight: '100vh',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        background: gradients.primary,
        py: 4,
      }}
    >
      <Container maxWidth="sm">
        <Paper sx={{ p: 4 }}>
          <Typography variant="h4" gutterBottom component="h1">
            Delete your account and data
          </Typography>
          <Typography variant="body1" color="text.secondary" sx={{ mb: 2 }}>
            This page explains how you can request permanent deletion of your account and associated data for{' '}
            <strong>{APP_NAME}</strong>.
          </Typography>

          <Typography variant="subtitle1" fontWeight={600} sx={{ mt: 3, mb: 1 }}>
            Steps to delete your account
          </Typography>
          <List dense disablePadding>
            <ListItem sx={{ display: 'list-item', listStyleType: 'decimal', pl: 0 }}>
              <ListItemText primary="Log in to your account using the button below (we need to identify which account to delete)." />
            </ListItem>
            <ListItem sx={{ display: 'list-item', listStyleType: 'decimal', pl: 0 }}>
              <ListItemText primary="Return to this page after logging in." />
            </ListItem>
            <ListItem sx={{ display: 'list-item', listStyleType: 'decimal', pl: 0 }}>
              <ListItemText primary="Click the 'Delete account' button and confirm. Your account and associated data will be permanently deleted." />
            </ListItem>
          </List>

          <Typography variant="subtitle1" fontWeight={600} sx={{ mt: 3, mb: 1 }}>
            What we delete
          </Typography>
          <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
            We delete your user account, profile information, and other data associated with your account. Some data
            may be retained as required by law or for a limited period for operational purposes (e.g. audit logs).
            For details, see our Privacy Policy.
          </Typography>

          {error && (
            <Alert severity="error" sx={{ mb: 2 }} onClose={() => setError(null)}>
              {error}
            </Alert>
          )}

          <Box sx={{ mt: 3, display: 'flex', flexDirection: 'column', gap: 2 }}>
            {!isAuthenticated ? (
              <Button variant="contained" size="large" onClick={handleLogin}>
                Log in to delete account
              </Button>
            ) : (
              <Button
                variant="contained"
                color="error"
                size="large"
                onClick={handleDeleteAccount}
                disabled={loading}
              >
                {loading ? <CircularProgress size={24} color="inherit" /> : 'Delete my account'}
              </Button>
            )}
          </Box>
        </Paper>
      </Container>
    </Box>
  );
}

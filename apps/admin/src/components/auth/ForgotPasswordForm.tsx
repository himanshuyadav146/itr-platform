import { useState } from 'react';
import {
    Box,
    TextField,
    Button,
    Alert,
    CircularProgress,
    Typography,
} from '@mui/material';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { useNavigate } from 'react-router-dom';
import { useAppDispatch } from '../../store/hooks';
import { addNotification } from '../../store/slices/uiSlice';

const forgotPasswordSchema = z.object({
    email: z.string().email('Invalid email address'),
});

type ForgotPasswordFormData = z.infer<typeof forgotPasswordSchema>;

export const ForgotPasswordForm = () => {
    const [error, setError] = useState<string | null>(null);
    const [success, setSuccess] = useState(false);
    const [loading, setLoading] = useState(false);
    const navigate = useNavigate();
    const dispatch = useAppDispatch();

    const {
        register,
        handleSubmit,
        formState: { errors },
    } = useForm<ForgotPasswordFormData>({
        resolver: zodResolver(forgotPasswordSchema),
    });

    const onSubmit = async () => {
        setError(null);
        setLoading(true);

        try {
            // TODO: Implement forgot password API call
            // For now, simulate API call
            await new Promise(resolve => setTimeout(resolve, 1500));

            setSuccess(true);
            dispatch(
                addNotification({
                    message: 'Password reset link sent to your email!',
                    type: 'success',
                })
            );

            // Redirect to login after 3 seconds
            setTimeout(() => {
                navigate('/login');
            }, 3000);
        } catch (err: any) {
            setError(err.response?.data?.data?.message || 'An error occurred. Please try again.');
        } finally {
            setLoading(false);
        }
    };

    if (success) {
        return (
            <Box className="fade-in">
                <Alert severity="success" sx={{ mb: 2 }}>
                    Password reset link has been sent to your email address. Please check your inbox.
                </Alert>
                <Typography variant="body2" color="text.secondary" align="center">
                    Redirecting to login page...
                </Typography>
            </Box>
        );
    }

    return (
        <Box component="form" onSubmit={handleSubmit(onSubmit)} sx={{ width: '100%' }}>
            {error && (
                <Alert severity="error" sx={{ mb: 2 }}>
                    {error}
                </Alert>
            )}

            <TextField
                {...register('email')}
                label="Email Address"
                type="email"
                fullWidth
                margin="normal"
                error={!!errors.email}
                helperText={errors.email?.message}
                autoComplete="email"
                autoFocus
                sx={{
                    '& .MuiOutlinedInput-root': {
                        transition: 'all 0.3s',
                    },
                }}
            />

            <Button
                type="submit"
                fullWidth
                variant="contained"
                size="large"
                sx={{
                    mt: 3,
                    mb: 2,
                    py: 1.5,
                    fontSize: '1rem',
                    fontWeight: 600,
                    background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
                    '&:hover': {
                        background: 'linear-gradient(135deg, #764ba2 0%, #667eea 100%)',
                    },
                }}
                disabled={loading}
            >
                {loading ? <CircularProgress size={24} color="inherit" /> : 'Send Reset Link'}
            </Button>
        </Box>
    );
};

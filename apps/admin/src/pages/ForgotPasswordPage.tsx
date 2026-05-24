import { Box, Container, Paper, Typography, Link } from '@mui/material';
import { Link as RouterLink } from 'react-router-dom';
import { ForgotPasswordForm } from '../components/auth/ForgotPasswordForm';
import { gradients } from '../theme/theme';

const ForgotPasswordPage = () => {
    return (
        <Box
            sx={{
                minHeight: '100vh',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                background: gradients.info,
                position: 'relative',
                overflow: 'hidden',
                '&::before': {
                    content: '""',
                    position: 'absolute',
                    top: '-50%',
                    right: '-10%',
                    width: '600px',
                    height: '600px',
                    background: 'rgba(255, 255, 255, 0.1)',
                    borderRadius: '50%',
                    animation: 'float 6s ease-in-out infinite',
                },
                '&::after': {
                    content: '""',
                    position: 'absolute',
                    bottom: '-30%',
                    left: '-5%',
                    width: '400px',
                    height: '400px',
                    background: 'rgba(255, 255, 255, 0.08)',
                    borderRadius: '50%',
                    animation: 'float 8s ease-in-out infinite',
                },
            }}
        >
            <Container component="main" maxWidth="xs" sx={{ position: 'relative', zIndex: 1 }}>
                <Box
                    className="scale-in"
                    sx={{
                        display: 'flex',
                        flexDirection: 'column',
                        alignItems: 'center',
                    }}
                >
                    <Paper
                        elevation={0}
                        sx={{
                            p: 4,
                            width: '100%',
                            background: 'rgba(255, 255, 255, 0.95)',
                            backdropFilter: 'blur(20px)',
                            borderRadius: 3,
                            boxShadow: '0 20px 60px rgba(0, 0, 0, 0.3)',
                            border: '1px solid rgba(255, 255, 255, 0.3)',
                        }}
                    >
                        {/* Logo/Title Section */}
                        <Box sx={{ textAlign: 'center', mb: 3 }}>
                            <Typography
                                component="h1"
                                variant="h4"
                                sx={{
                                    fontWeight: 700,
                                    background: gradients.info,
                                    backgroundClip: 'text',
                                    WebkitBackgroundClip: 'text',
                                    WebkitTextFillColor: 'transparent',
                                    mb: 1,
                                }}
                            >
                                Reset Password
                            </Typography>
                            <Typography variant="body2" color="text.secondary">
                                Enter your email address and we'll send you a link to reset your password
                            </Typography>
                        </Box>

                        <ForgotPasswordForm />

                        {/* Links Section */}
                        <Box sx={{ mt: 3, textAlign: 'center' }}>
                            <Link
                                component={RouterLink}
                                to="/login"
                                variant="body2"
                                sx={{
                                    color: 'primary.main',
                                    textDecoration: 'none',
                                    fontWeight: 500,
                                    transition: 'all 0.3s',
                                    '&:hover': {
                                        color: 'primary.dark',
                                        textDecoration: 'underline',
                                    },
                                }}
                            >
                                ← Back to Sign In
                            </Link>
                        </Box>
                    </Paper>

                    {/* Footer */}
                    <Typography
                        variant="caption"
                        sx={{
                            mt: 3,
                            color: 'rgba(255, 255, 255, 0.9)',
                            textAlign: 'center',
                        }}
                    >
                        © 2024 ITR Admin Panel. All rights reserved.
                    </Typography>
                </Box>
            </Container>
        </Box>
    );
};

export default ForgotPasswordPage;

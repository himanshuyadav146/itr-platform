import { useState, useMemo } from 'react';
import { Box, Typography, TextField, InputAdornment, Grid, CircularProgress, Alert, AlertTitle } from '@mui/material';
import { Search as SearchIcon } from '@mui/icons-material';
import { DashboardLayout } from '../components/layout/DashboardLayout';
import { ProfessionalCard } from '../components/professionals/ProfessionalCard';
import { useQuery } from '@tanstack/react-query';
import { professionalsApi } from '../api/professionals';
import { useAuth } from '../hooks/useAuth';
import { UserRole } from '../types/enums';


const ProfessionalsPage = () => {
    const [searchQuery, setSearchQuery] = useState('');
    const { role } = useAuth();
    const isAdmin = role === UserRole.ADMIN;

    // Fetch professionals using the dedicated API
    // Fetch professionals (Accountants and CAs)
    const { data: accountants, isLoading: loadingAccountants, error: errorAccountants } = useQuery({
        queryKey: ['professionals', 'ACCOUNTANT', isAdmin],
        queryFn: () => professionalsApi.getProfessionals({ role: 'ACCOUNTANT', limit: 500 }),
    });

    const { data: cas, isLoading: loadingCAs, error: errorCAs } = useQuery({
        queryKey: ['professionals', 'CA', isAdmin],
        queryFn: () => professionalsApi.getProfessionals({ role: 'CA', limit: 500 }),
    });

    const isLoading = loadingAccountants || loadingCAs;
    const error = errorAccountants || errorCAs;

    // Combine data
    const data = useMemo(() => {
        const items = [
            ...(accountants?.items || []),
            ...(cas?.items || [])
        ];
        return { items };
    }, [accountants, cas]);

    // Transform professionals to display format
    const professionals = useMemo(() => {
        if (!data || !data.items) return [];

        return data.items.map((prof: any) => ({
            id: prof.id || prof.UserId,
            name: prof.name || `${prof.FirstName} ${prof.LastName}`.trim(),
            email: prof.email || prof.Email,
            phone: prof.phone || prof.Mobile || 'N/A',
            occupation: prof.occupation || 'Associate',
            role: prof.occupation, // Use occupation as role for display
            assignedITRs: 0, // Not available in current API
            completedITRs: 0, // Not available in current API
        }));
    }, [data]);

    const filteredProfessionals = useMemo(() => {
        if (!searchQuery.trim()) return professionals;

        const query = searchQuery.toLowerCase();
        return professionals.filter(
            (professional: any) =>
                professional.name.toLowerCase().includes(query) ||
                professional.email.toLowerCase().includes(query) ||
                professional.phone.toLowerCase().includes(query) ||
                (professional.occupation || '').toLowerCase().includes(query)
        );
    }, [professionals, searchQuery]);

    // Calculate statistics
    const stats = useMemo(() => {
        const totalProfessionals = professionals.length;
        const totalCAs = professionals.filter((p: any) =>
            (p.occupation || '').toUpperCase().includes('CA') ||
            (p.occupation || '').toUpperCase().includes('CHARTERED')
        ).length;

        // Since we don't have these stats from API yet, we'll show 0
        const totalAssignedITRs = 0;

        return { totalProfessionals, totalCAs, totalAssignedITRs };
    }, [professionals]);

    return (
        <DashboardLayout>
            <Box sx={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
                {/* Page Header */}
                <Box className="fade-in">
                    <Typography
                        variant="h4"
                        sx={{
                            fontWeight: 700,
                            mb: 1,
                            background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
                            backgroundClip: 'text',
                            WebkitBackgroundClip: 'text',
                            WebkitTextFillColor: 'transparent',
                        }}
                    >
                        Associates
                    </Typography>
                    <Typography variant="body1" color="text.secondary">
                        Manage and view all professional associates - CAs, Tax Experts, and Accountants
                    </Typography>
                </Box>

                {/* Search Bar */}
                <Box className="slide-in-left">
                    <TextField
                        fullWidth
                        placeholder="Search by name, email, phone, or position..."
                        value={searchQuery}
                        onChange={(e) => setSearchQuery(e.target.value)}
                        InputProps={{
                            startAdornment: (
                                <InputAdornment position="start">
                                    <SearchIcon />
                                </InputAdornment>
                            ),
                        }}
                        sx={{
                            maxWidth: 600,
                            '& .MuiOutlinedInput-root': {
                                backgroundColor: 'background.paper',
                            },
                        }}
                    />
                </Box>

                {/* Statistics Summary */}
                <Box
                    className="fade-in"
                    sx={{
                        display: 'flex',
                        gap: 3,
                        flexWrap: 'wrap',
                    }}
                >
                    <Box
                        sx={{
                            px: 3,
                            py: 2,
                            borderRadius: 2,
                            background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
                            color: 'white',
                        }}
                    >
                        <Typography variant="h4" sx={{ fontWeight: 700 }}>
                            {isLoading ? '...' : stats.totalProfessionals}
                        </Typography>
                        <Typography variant="body2">Total Professionals</Typography>
                    </Box>
                    <Box
                        sx={{
                            px: 3,
                            py: 2,
                            borderRadius: 2,
                            background: 'linear-gradient(135deg, #4facfe 0%, #00f2fe 100%)',
                            color: 'white',
                        }}
                    >
                        <Typography variant="h4" sx={{ fontWeight: 700 }}>
                            {isLoading ? '...' : stats.totalCAs}
                        </Typography>
                        <Typography variant="body2">Chartered Accountants</Typography>
                    </Box>
                    <Box
                        sx={{
                            px: 3,
                            py: 2,
                            borderRadius: 2,
                            background: 'linear-gradient(135deg, #0ba360 0%, #3cba92 100%)',
                            color: 'white',
                        }}
                    >
                        <Typography variant="h4" sx={{ fontWeight: 700 }}>
                            {isLoading ? '...' : stats.totalAssignedITRs}
                        </Typography>
                        <Typography variant="body2">Total Assigned ITRs</Typography>
                    </Box>
                </Box>

                {/* Loading State */}
                {isLoading && (
                    <Box sx={{ display: 'flex', justifyContent: 'center', py: 8 }}>
                        <CircularProgress />
                    </Box>
                )}

                {/* Error State */}
                {error && (
                    <Alert severity="error" sx={{ mb: 2 }}>
                        <AlertTitle>Error Loading Professionals</AlertTitle>
                        Failed to fetch professionals. Please try again later.
                    </Alert>
                )}

                {/* Professionals Grid */}
                {!isLoading && !error && (
                    <Box className="fade-in">
                        <Typography variant="h5" sx={{ fontWeight: 600, mb: 3 }}>
                            {searchQuery ? `Search Results (${filteredProfessionals.length})` : 'All Professionals'}
                        </Typography>

                        {filteredProfessionals.length === 0 ? (
                            <Box
                                sx={{
                                    textAlign: 'center',
                                    py: 8,
                                    px: 2,
                                }}
                            >
                                <SearchIcon sx={{ fontSize: 80, color: 'text.disabled', mb: 2 }} />
                                <Typography variant="h6" color="text.secondary" gutterBottom>
                                    No Professionals Found
                                </Typography>
                                <Typography variant="body2" color="text.disabled">
                                    {searchQuery ? 'Try adjusting your search criteria' : 'No professionals available'}
                                </Typography>
                            </Box>
                        ) : (
                            <Grid container spacing={3}>
                                {filteredProfessionals.map((professional) => (
                                    <Grid size={{ xs: 12, sm: 6, md: 4 }} key={professional.id}>
                                        <ProfessionalCard professional={professional} />
                                    </Grid>
                                ))}
                            </Grid>
                        )}
                    </Box>
                )}
            </Box>
        </DashboardLayout>
    );
};

export default ProfessionalsPage;

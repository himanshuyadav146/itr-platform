import {
    Box,
    Card,
    CardContent,
    Typography,
    Grid,
    alpha,
} from '@mui/material';
import {
    Description as DescriptionIcon,
    Person as PersonIcon,
    CalendarToday as CalendarIcon,
    CheckCircle as CheckCircleIcon,
} from '@mui/icons-material';
import type { ITRWithDetails } from '../../types/itr';
import { format } from 'date-fns';
import { StatusChip } from '../common/StatusChip';

interface ITRGridProps {
    itrs: ITRWithDetails[];
    onITRClick?: (itr: ITRWithDetails) => void;
}

export const ITRGrid = ({ itrs, onITRClick }: ITRGridProps) => {
    if (itrs.length === 0) {
        return (
            <Box
                sx={{
                    textAlign: 'center',
                    py: 8,
                    px: 2,
                }}
            >
                <DescriptionIcon sx={{ fontSize: 80, color: 'text.disabled', mb: 2 }} />
                <Typography variant="h6" color="text.secondary" gutterBottom>
                    No ITRs Found
                </Typography>
                <Typography variant="body2" color="text.disabled">
                    There are no ITRs matching the selected filter
                </Typography>
            </Box>
        );
    }

    return (
        <Grid container spacing={3}>
            {itrs.map((itr) => (
                <Grid size={{ xs: 12, sm: 6, md: 4 }} key={itr.id}>
                    <Card
                        className="card-hover"
                        onClick={() => onITRClick?.(itr)}
                        sx={{
                            height: '100%',
                            cursor: onITRClick ? 'pointer' : 'default',
                            position: 'relative',
                            overflow: 'hidden',
                            transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
                        }}
                    >
                        <CardContent sx={{ p: 3 }}>
                            {/* Header with Status */}
                            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', mb: 2 }}>
                                <Typography variant="h6" sx={{ fontWeight: 600, fontSize: '1.1rem' }}>
                                    ITR #{itr.id}
                                </Typography>
                                <StatusChip status={itr.status} />
                            </Box>

                            {/* ITR Details */}
                            <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1.5 }}>
                                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                                    <DescriptionIcon sx={{ fontSize: 18, color: 'text.secondary' }} />
                                    <Box>
                                        <Typography variant="caption" color="text.secondary" display="block">
                                            PAN Number
                                        </Typography>
                                        <Typography variant="body2" sx={{ fontWeight: 600 }}>
                                            {itr.panNumber}
                                        </Typography>
                                    </Box>
                                </Box>

                                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                                    <PersonIcon sx={{ fontSize: 18, color: 'text.secondary' }} />
                                    <Box>
                                        <Typography variant="caption" color="text.secondary" display="block">
                                            Client Name
                                        </Typography>
                                        <Typography variant="body2" sx={{ fontWeight: 600 }}>
                                            {itr.clientName || 'N/A'}
                                        </Typography>
                                    </Box>
                                </Box>

                                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                                    <CalendarIcon sx={{ fontSize: 18, color: 'text.secondary' }} />
                                    <Box>
                                        <Typography variant="caption" color="text.secondary" display="block">
                                            Financial Year
                                        </Typography>
                                        <Typography variant="body2" sx={{ fontWeight: 600 }}>
                                            {itr.financialYear}
                                        </Typography>
                                    </Box>
                                </Box>

                                {itr.assignedProfessionalName && (
                                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                                        <CheckCircleIcon sx={{ fontSize: 18, color: 'text.secondary' }} />
                                        <Box>
                                            <Typography variant="caption" color="text.secondary" display="block">
                                                Assigned To
                                            </Typography>
                                            <Typography variant="body2" sx={{ fontWeight: 600 }}>
                                                {itr.assignedProfessionalName}
                                            </Typography>
                                        </Box>
                                    </Box>
                                )}

                                {itr.acknowledgement_number && (
                                    <Box
                                        sx={{
                                            mt: 1,
                                            p: 1.5,
                                            borderRadius: 2,
                                            background: (theme) => alpha(theme.palette.success.main, 0.1),
                                        }}
                                    >
                                        <Typography variant="caption" color="success.main" display="block" sx={{ fontWeight: 600 }}>
                                            Acknowledgement
                                        </Typography>
                                        <Typography variant="body2" sx={{ fontWeight: 600, color: 'success.main' }}>
                                            {itr.acknowledgement_number}
                                        </Typography>
                                    </Box>
                                )}
                            </Box>

                            {/* Footer with Date */}
                            <Box
                                sx={{
                                    mt: 2,
                                    pt: 2,
                                    borderTop: 1,
                                    borderColor: 'divider',
                                }}
                            >
                                <Typography variant="caption" color="text.secondary">
                                    Created: {format(new Date(itr.createdAt), 'MMM dd, yyyy')}
                                </Typography>
                            </Box>
                        </CardContent>
                    </Card>
                </Grid>
            ))}
        </Grid>
    );
};

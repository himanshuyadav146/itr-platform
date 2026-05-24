import {
    Card,
    CardContent,
    Box,
    Typography,
    Avatar,
    Chip,
    alpha,
} from '@mui/material';
import {
    Phone as PhoneIcon,
    Email as EmailIcon,
    Assignment as AssignmentIcon,
    CheckCircle as CheckCircleIcon,
} from '@mui/icons-material';
import type { MockProfessional } from '../../utils/mockData';
import { ProfessionalOccupation, UserRole } from '../../types/enums';

interface ProfessionalCardProps {
    professional: MockProfessional & { role?: string };
    onClick?: () => void;
}

const getOccupationColor = (role?: string, occupation?: ProfessionalOccupation): 'primary' | 'secondary' | 'success' | 'warning' | 'error' => {
    // Normalize role for case-insensitive comparison
    const normalizedRole = role?.toUpperCase().trim();
    
    // Debug logging
    console.log('[ProfessionalCard] Role color determination:', {
        originalRole: role,
        normalizedRole,
        occupation,
        timestamp: new Date().toISOString()
    });
    
    // Use actual role if available, otherwise fall back to occupation (type-safe comparison)
    if (normalizedRole === UserRole.CA || occupation === ProfessionalOccupation.CA) {
        return 'primary';
    } else if (normalizedRole === UserRole.TAX_EXPERT || occupation === ProfessionalOccupation.TAX_EXPERT) {
        return 'secondary';
    } else if (normalizedRole === UserRole.ACCOUNTANT || occupation === ProfessionalOccupation.ACCOUNTANT) {
        return 'success';
    } else if (normalizedRole === UserRole.ADMIN) {
        return 'warning';
    } else if (normalizedRole === UserRole.CLIENT) {
        return 'error';
    }
    
    return 'primary';
};

const getInitials = (name: string): string => {
    return name
        .split(' ')
        .map((n) => n[0])
        .join('')
        .toUpperCase()
        .slice(0, 2);
};

export const ProfessionalCard = ({ professional, onClick }: ProfessionalCardProps) => {
    const occupationColor = getOccupationColor(professional.role, professional.occupation);

    return (
        <Card
            className="card-hover"
            onClick={onClick}
            sx={{
                height: '100%',
                cursor: onClick ? 'pointer' : 'default',
                position: 'relative',
                overflow: 'hidden',
                transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
                '&::before': {
                    content: '""',
                    position: 'absolute',
                    top: 0,
                    left: 0,
                    right: 0,
                    height: '4px',
                    background: (theme) =>
                        `linear-gradient(90deg, ${theme.palette[occupationColor].main}, ${theme.palette[occupationColor].light})`,
                },
            }}
        >
            <CardContent sx={{ p: 3 }}>
                {/* Header with Avatar and Name */}
                <Box sx={{ display: 'flex', alignItems: 'flex-start', gap: 2, mb: 3 }}>
                    <Avatar
                        sx={{
                            width: 60,
                            height: 60,
                            bgcolor: `${occupationColor}.main`,
                            fontSize: '1.5rem',
                            fontWeight: 700,
                            boxShadow: (theme) => `0 4px 12px ${alpha(theme.palette[occupationColor].main, 0.3)}`,
                        }}
                    >
                        {getInitials(professional.name)}
                    </Avatar>
                    <Box sx={{ flex: 1 }}>
                        <Typography variant="h6" sx={{ fontWeight: 600, mb: 0.5 }}>
                            {professional.name}
                        </Typography>
                        <Chip
                            label={professional.role || professional.occupation || 'N/A'}
                            color={occupationColor}
                            size="small"
                            sx={{
                                fontWeight: 600,
                                fontSize: '0.75rem',
                                height: 24,
                            }}
                        />
                    </Box>
                </Box>

                {/* Professional Details */}
                <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
                        <Box
                            sx={{
                                width: 36,
                                height: 36,
                                borderRadius: '8px',
                                display: 'flex',
                                alignItems: 'center',
                                justifyContent: 'center',
                                background: (theme) => alpha(theme.palette.info.main, 0.1),
                                color: 'info.main',
                            }}
                        >
                            <EmailIcon sx={{ fontSize: 18 }} />
                        </Box>
                        <Box sx={{ flex: 1, minWidth: 0 }}>
                            <Typography variant="caption" color="text.secondary" display="block">
                                Email
                            </Typography>
                            <Typography
                                variant="body2"
                                sx={{
                                    fontWeight: 500,
                                    overflow: 'hidden',
                                    textOverflow: 'ellipsis',
                                    whiteSpace: 'nowrap',
                                }}
                            >
                                {professional.email}
                            </Typography>
                        </Box>
                    </Box>

                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
                        <Box
                            sx={{
                                width: 36,
                                height: 36,
                                borderRadius: '8px',
                                display: 'flex',
                                alignItems: 'center',
                                justifyContent: 'center',
                                background: (theme) => alpha(theme.palette.success.main, 0.1),
                                color: 'success.main',
                            }}
                        >
                            <PhoneIcon sx={{ fontSize: 18 }} />
                        </Box>
                        <Box>
                            <Typography variant="caption" color="text.secondary" display="block">
                                Phone
                            </Typography>
                            <Typography variant="body2" sx={{ fontWeight: 500 }}>
                                {professional.phone}
                            </Typography>
                        </Box>
                    </Box>

                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
                        <Box
                            sx={{
                                width: 36,
                                height: 36,
                                borderRadius: '8px',
                                display: 'flex',
                                alignItems: 'center',
                                justifyContent: 'center',
                                background: (theme) => alpha(theme.palette.warning.main, 0.1),
                                color: 'warning.main',
                            }}
                        >
                            <Typography variant="body2" sx={{ fontWeight: 700 }}>
                                ID
                            </Typography>
                        </Box>
                        <Box>
                            <Typography variant="caption" color="text.secondary" display="block">
                                Professional ID
                            </Typography>
                            <Typography variant="body2" sx={{ fontWeight: 500 }}>
                                #{professional.id}
                            </Typography>
                        </Box>
                    </Box>
                </Box>

                {/* Statistics */}
                <Box
                    sx={{
                        mt: 3,
                        pt: 3,
                        borderTop: 1,
                        borderColor: 'divider',
                        display: 'flex',
                        gap: 2,
                    }}
                >
                    <Box
                        sx={{
                            flex: 1,
                            p: 1.5,
                            borderRadius: 2,
                            background: (theme) => alpha(theme.palette.info.main, 0.08),
                            textAlign: 'center',
                        }}
                    >
                        <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 0.5, mb: 0.5 }}>
                            <AssignmentIcon sx={{ fontSize: 16, color: 'info.main' }} />
                            <Typography variant="h6" sx={{ fontWeight: 700, color: 'info.main' }}>
                                {professional.assignedITRs}
                            </Typography>
                        </Box>
                        <Typography variant="caption" color="text.secondary">
                            Assigned
                        </Typography>
                    </Box>

                    <Box
                        sx={{
                            flex: 1,
                            p: 1.5,
                            borderRadius: 2,
                            background: (theme) => alpha(theme.palette.success.main, 0.08),
                            textAlign: 'center',
                        }}
                    >
                        <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 0.5, mb: 0.5 }}>
                            <CheckCircleIcon sx={{ fontSize: 16, color: 'success.main' }} />
                            <Typography variant="h6" sx={{ fontWeight: 700, color: 'success.main' }}>
                                {professional.completedITRs}
                            </Typography>
                        </Box>
                        <Typography variant="caption" color="text.secondary">
                            Completed
                        </Typography>
                    </Box>
                </Box>
            </CardContent>
        </Card>
    );
};

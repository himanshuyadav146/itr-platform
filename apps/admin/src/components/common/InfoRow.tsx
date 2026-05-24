import { Box, Typography } from '@mui/material';
import type { ReactNode } from 'react';

interface InfoRowProps {
    label: string;
    value: ReactNode;
    icon?: ReactNode;
}

export const InfoRow = ({ label, value, icon }: InfoRowProps) => {
    return (
        <Box sx={{ mt: 2 }}>
            <Typography variant="body2" color="text.secondary">
                {label}
            </Typography>
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mt: 0.5 }}>
                {icon}
                <Typography variant="body1" sx={{ fontWeight: value ? 500 : 400 }}>
                    {value || 'N/A'}
                </Typography>
            </Box>
        </Box>
    );
};

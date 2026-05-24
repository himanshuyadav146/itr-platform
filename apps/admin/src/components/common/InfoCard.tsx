import { Box, Paper, Typography } from '@mui/material';
import type { ReactNode } from 'react';

interface InfoCardProps {
    title: string;
    children: ReactNode;
    actions?: ReactNode;
}

export const InfoCard = ({ title, children, actions }: InfoCardProps) => {
    return (
        <Paper sx={{ p: 3, height: '100%' }}>
            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
                <Typography variant="h6">{title}</Typography>
                {actions && <Box sx={{ display: 'flex', gap: 1 }}>{actions}</Box>}
            </Box>
            <Box>{children}</Box>
        </Paper>
    );
};

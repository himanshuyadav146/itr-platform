import { Card, CardContent, Box, Typography, alpha } from '@mui/material';
import type { ReactNode } from 'react';

interface KPICardProps {
  title: string;
  value: string | number;
  icon: ReactNode;
  color: 'primary' | 'secondary' | 'success' | 'warning' | 'error' | 'info';
  onClick?: () => void;
  selected?: boolean;
}

export const KPICard = ({ title, value, icon, color, onClick, selected }: KPICardProps) => {
  const isClickable = !!onClick;

  return (
    <Card
      onClick={onClick}
      sx={{
        height: '100%',
        cursor: isClickable ? 'pointer' : 'default',
        position: 'relative',
        overflow: 'hidden',
        transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
        border: selected ? 2 : 0,
        borderColor: `${color}.main`,
        transform: selected ? 'scale(1.02)' : 'scale(1)',
        boxShadow: selected
          ? `0 8px 32px ${alpha('#000', 0.15)}`
          : `0 4px 20px ${alpha('#000', 0.08)}`,
        '&:hover': isClickable
          ? {
            transform: 'translateY(-8px) scale(1.02)',
            boxShadow: `0 12px 40px ${alpha('#000', 0.2)}`,
          }
          : {},
        '&::before': {
          content: '""',
          position: 'absolute',
          top: 0,
          left: 0,
          right: 0,
          height: '4px',
          background: (theme) =>
            `linear-gradient(90deg, ${theme.palette[color].main}, ${theme.palette[color].light})`,
        },
      }}
    >
      <CardContent sx={{ p: 3 }}>
        <Box sx={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between' }}>
          <Box sx={{ flex: 1 }}>
            <Typography
              variant="body2"
              color="text.secondary"
              sx={{
                fontWeight: 500,
                mb: 1,
                textTransform: 'uppercase',
                letterSpacing: '0.5px',
                fontSize: '0.75rem',
              }}
            >
              {title}
            </Typography>
            <Typography
              variant="h4"
              sx={{
                fontWeight: 700,
                color: 'text.primary',
                mb: 0.5,
                fontSize: { xs: '1.75rem', sm: '2rem' },
              }}
            >
              {value}
            </Typography>
          </Box>
          <Box
            sx={{
              width: 56,
              height: 56,
              borderRadius: '12px',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              background: (theme) => alpha(theme.palette[color].main, 0.1),
              color: `${color}.main`,
              transition: 'all 0.3s',
              ...(isClickable && {
                '&:hover': {
                  background: (theme) => alpha(theme.palette[color].main, 0.2),
                  transform: 'rotate(10deg) scale(1.1)',
                },
              }),
            }}
          >
            {icon}
          </Box>
        </Box>
      </CardContent>
    </Card>
  );
};

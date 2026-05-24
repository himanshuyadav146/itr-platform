import { Chip } from '@mui/material';
import { ITRStatus } from '../../types/enums';
import { ITR_STATUS_COLORS, ITR_STATUS_LABELS } from '../../utils/constants';

interface StatusChipProps {
    status: ITRStatus | string;
    size?: 'small' | 'medium';
    variant?: 'filled' | 'outlined';
}

export const StatusChip = ({ status, size = 'small', variant = 'filled' }: StatusChipProps) => {
    const backgroundColor = ITR_STATUS_COLORS[status] || '#gray';
    const label = ITR_STATUS_LABELS[status] || status;

    return (
        <Chip
            label={label}
            size={size}
            variant={variant}
            sx={{
                backgroundColor: variant === 'filled' ? backgroundColor : 'transparent',
                color: variant === 'filled' ? 'white' : backgroundColor,
                borderColor: variant === 'outlined' ? backgroundColor : undefined,
                fontWeight: 600,
                fontSize: size === 'small' ? '0.75rem' : '0.875rem',
                height: size === 'small' ? 24 : 32,
            }}
        />
    );
};

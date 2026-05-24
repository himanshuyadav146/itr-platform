import { Box, Paper, Typography, Button } from '@mui/material';
import { Edit as EditIcon } from '@mui/icons-material';
import { useNavigate } from 'react-router-dom';
import type { UserDetails } from '../../types';
import { formatCurrency, formatNumber } from '../../utils/formatters';

interface UserDetailsComponentProps {
  user: UserDetails;
  onEdit?: () => void;
}

export const UserDetailsSection = ({ user, onEdit }: UserDetailsComponentProps) => {
  const navigate = useNavigate();

  const handleEdit = () => {
    if (onEdit) {
      onEdit();
    } else {
      navigate(`/users/${user.UserId}?edit=true`);
    }
  };

  return (
    <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 3 }}>
      <Box sx={{ flex: { xs: '1 1 100%', md: '1 1 calc(50% - 12px)' } }}>
        <Paper sx={{ p: 3 }}>
          <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
            <Typography variant="h6">Personal Information</Typography>
            <Button
              size="small"
              variant="outlined"
              startIcon={<EditIcon />}
              onClick={handleEdit}
            >
              Edit
            </Button>
          </Box>
          <Box sx={{ mt: 2 }}>
            <Typography variant="body2" color="text.secondary">
              Name
            </Typography>
            <Typography variant="body1" gutterBottom>
              {`${user.FirstName || ''} ${user.MiddleName || ''} ${user.LastName || ''}`.trim() || 'N/A'}
            </Typography>

            <Typography variant="body2" color="text.secondary" sx={{ mt: 2 }}>
              Email
            </Typography>
            <Typography variant="body1" gutterBottom>
              {user.Email}
            </Typography>

            <Typography variant="body2" color="text.secondary" sx={{ mt: 2 }}>
              Phone
            </Typography>
            <Typography variant="body1" gutterBottom>
              {user.Mobile || 'N/A'}
            </Typography>

            <Typography variant="body2" color="text.secondary" sx={{ mt: 2 }}>
              Role
            </Typography>
            <Typography variant="body1" gutterBottom>
              {user.role || 'CLIENT'}
            </Typography>

            {user.CreatedAt && (
              <>
                <Typography variant="body2" color="text.secondary" sx={{ mt: 2 }}>
                  Created At
                </Typography>
                <Typography variant="body1" gutterBottom>
                  {new Date(user.CreatedAt).toLocaleDateString()}
                </Typography>
              </>
            )}
          </Box>
        </Paper>
      </Box>

      <Box sx={{ flex: { xs: '1 1 100%', md: '1 1 calc(50% - 12px)' } }}>
        <Paper sx={{ p: 3 }}>
          <Typography variant="h6" gutterBottom>
            Statistics
          </Typography>
          <Box sx={{ mt: 2 }}>
            <Typography variant="body2" color="text.secondary">
              Total ITRs Assigned
            </Typography>
            <Typography variant="h5" gutterBottom>
              {formatNumber(user.totalITRsAssigned || 0)}
            </Typography>

            <Typography variant="body2" color="text.secondary" sx={{ mt: 2 }}>
              Total ITRs Filed
            </Typography>
            <Typography variant="h5" gutterBottom>
              {formatNumber(user.totalITRsFiled || 0)}
            </Typography>

            <Typography variant="body2" color="text.secondary" sx={{ mt: 2 }}>
              Revenue Generated
            </Typography>
            <Typography variant="h5" gutterBottom>
              {formatCurrency(user.revenueGenerated || 0)}
            </Typography>
          </Box>
        </Paper>
      </Box>
    </Box>
  );
};

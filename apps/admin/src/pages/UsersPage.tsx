import { Box, Typography } from '@mui/material';
import { DashboardLayout } from '../components/layout/DashboardLayout';
import { UserList } from '../components/users/UserList';

const UsersPage = () => {
  return (
    <DashboardLayout>
      <Box>
        <Typography variant="h4" gutterBottom>
          User Management
        </Typography>
        <UserList />
      </Box>
    </DashboardLayout>
  );
};

export default UsersPage;


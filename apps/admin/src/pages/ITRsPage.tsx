import { Box, Typography } from '@mui/material';
import { DashboardLayout } from '../components/layout/DashboardLayout';
import { ITRList } from '../components/itr/ITRList';

const ITRsPage = () => {
  return (
    <DashboardLayout>
      <Box>
        <Typography variant="h4" gutterBottom>
          ITR Management
        </Typography>
        <ITRList />
      </Box>
    </DashboardLayout>
  );
};

export default ITRsPage;


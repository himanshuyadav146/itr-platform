import { Box, Typography } from '@mui/material';
import { DashboardLayout } from '../components/layout/DashboardLayout';
import { PackageList } from '../components/packages/PackageList';

const PackagesPage = () => {
  return (
    <DashboardLayout>
      <Box>
        <Typography variant="h4" gutterBottom>
          Package Management
        </Typography>
        <PackageList />
      </Box>
    </DashboardLayout>
  );
};

export default PackagesPage;

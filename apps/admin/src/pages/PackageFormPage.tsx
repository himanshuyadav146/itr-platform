import { Box, Typography } from '@mui/material';
import { useParams, useNavigate } from 'react-router-dom';
import { DashboardLayout } from '../components/layout/DashboardLayout';
import { PackageForm } from '../components/packages/PackageForm';
import { LoadingSpinner } from '../components/common/LoadingSpinner';
import { useQuery } from '@tanstack/react-query';
import { packagesApi } from '../api/packages';

const PackageFormPage = () => {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const isNew = id === 'new' || !id;

  const { data: pkg, isLoading } = useQuery({
    queryKey: ['package', id],
    queryFn: async () => {
      if (!id || id === 'new') return null;
      const list = await packagesApi.getPackages();
      return list.find((p) => p.id === Number(id)) ?? null;
    },
    enabled: !isNew,
  });

  if (!isNew && isLoading) {
    return (
      <DashboardLayout>
        <Box>
          <Typography variant="h4" gutterBottom>
            Edit Package
          </Typography>
          <LoadingSpinner />
        </Box>
      </DashboardLayout>
    );
  }

  if (!isNew && !isLoading && !pkg) {
    navigate('/packages', { replace: true });
    return null;
  }

  return (
    <DashboardLayout>
      <Box>
        <Typography variant="h4" gutterBottom>
          {isNew ? 'Add Package' : 'Edit Package'}
        </Typography>
        <PackageForm pkg={pkg ?? null} isEdit={!isNew} />
      </Box>
    </DashboardLayout>
  );
};

export default PackageFormPage;

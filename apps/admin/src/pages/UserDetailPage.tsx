import { useState } from 'react';
import { useParams, useSearchParams } from 'react-router-dom';
import { Box, Typography } from '@mui/material';
import { DashboardLayout } from '../components/layout/DashboardLayout';
import { LoadingSpinner } from '../components/common/LoadingSpinner';
import { useQuery } from '@tanstack/react-query';
import { usersApi } from '../api/users';
import { UserDetailsSection } from '../components/users/UserDetails';
import { UserForm } from '../components/users/UserForm';
import { AssignITRModal } from '../components/users/AssignITRModal';

const UserDetailPage = () => {
  const { id } = useParams<{ id: string }>();
  const [searchParams] = useSearchParams();
  const [assignModalOpen, setAssignModalOpen] = useState(false);
  const userId = id ? parseInt(id, 10) : 0;
  const isEditMode = searchParams.get('edit') === 'true';

  const { data: user, isLoading } = useQuery({
    queryKey: ['user', userId],
    queryFn: () => usersApi.getUserDetails(userId),
    enabled: !!userId,
  });

  if (isLoading) {
    return (
      <DashboardLayout>
        <LoadingSpinner />
      </DashboardLayout>
    );
  }

  if (!user) {
    return (
      <DashboardLayout>
        <Box>User not found</Box>
      </DashboardLayout>
    );
  }

  if (isEditMode) {
    return (
      <DashboardLayout>
        <Box>
          <Typography variant="h4" gutterBottom>
            Edit User
          </Typography>
          <UserForm user={user} />
        </Box>
      </DashboardLayout>
    );
  }

  return (
    <DashboardLayout>
      <Box>
        <Typography variant="h4" gutterBottom>
          User Details
        </Typography>
        <Box sx={{ mt: 2 }}>
          <UserDetailsSection user={user} />
        </Box>

        {assignModalOpen && (
          <AssignITRModal
            open={assignModalOpen}
            onClose={() => setAssignModalOpen(false)}
            user={user}
          />
        )}
      </Box>
    </DashboardLayout>
  );
};

export default UserDetailPage;


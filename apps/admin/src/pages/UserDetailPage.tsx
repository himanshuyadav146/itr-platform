import { useState } from 'react';
import { useParams, useSearchParams } from 'react-router-dom';
import { Box, Typography } from '@mui/material';
import { DashboardLayout } from '../components/layout/DashboardLayout';
import { LoadingSpinner } from '../components/common/LoadingSpinner';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { usersApi } from '../api/users';
import { associatesApi } from '../api/associates';
import { isAssociateRole, UserDetailsSection } from '../components/users/UserDetails';
import { UserForm } from '../components/users/UserForm';
import { AssignITRModal } from '../components/users/AssignITRModal';

const UserDetailPage = () => {
  const { id } = useParams<{ id: string }>();
  const [searchParams] = useSearchParams();
  const queryClient = useQueryClient();
  const [assignModalOpen, setAssignModalOpen] = useState(false);
  const [approvalError, setApprovalError] = useState<string | null>(null);
  const userId = id ? parseInt(id, 10) : 0;
  const isEditMode = searchParams.get('edit') === 'true';

  const { data: user, isLoading } = useQuery({
    queryKey: ['user', userId],
    queryFn: () => usersApi.getUserDetails(userId),
    enabled: !!userId,
  });

  const associateQuery = useQuery({
    queryKey: ['associate-detail', userId],
    queryFn: () => associatesApi.get(userId),
    enabled: !!userId && isAssociateRole(user?.role),
    retry: false,
  });

  const decide = useMutation({
    mutationFn: ({ action, reason }: { action: 'approve' | 'reject'; reason?: string }) =>
      associatesApi.decide(userId, action, reason),
    onSuccess: () => {
      setApprovalError(null);
      queryClient.invalidateQueries({ queryKey: ['associate-detail', userId] });
      queryClient.invalidateQueries({ queryKey: ['associate-approvals'] });
    },
    onError: (err: any) => {
      setApprovalError(err?.response?.data?.data?.message || 'Could not update approval status');
    },
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
          <UserDetailsSection
            user={user}
            approvalStatus={associateQuery.data?.approval_status}
            rejectionReason={associateQuery.data?.rejection_reason}
            approvalLoading={decide.isPending || associateQuery.isLoading}
            approvalError={approvalError}
            onApprove={
              isAssociateRole(user.role)
                ? () => decide.mutate({ action: 'approve' })
                : undefined
            }
            onReject={
              isAssociateRole(user.role)
                ? (reason) => decide.mutate({ action: 'reject', reason })
                : undefined
            }
          />
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


import { Box, Typography } from '@mui/material';
import { useQuery } from '@tanstack/react-query';
import { DashboardLayout } from '../components/layout/DashboardLayout';
import { NotificationSettingsPanel } from '../components/notifications/NotificationSettingsPanel';
import { NotificationTemplateList } from '../components/notifications/NotificationTemplateList';
import { notificationTemplatesApi } from '../api/notificationTemplates';
import { LoadingSpinner } from '../components/common/LoadingSpinner';

const NotificationTemplatesPage = () => {
  const { data, isLoading } = useQuery({
    queryKey: ['notification-templates'],
    queryFn: () => notificationTemplatesApi.getAll(),
  });

  if (isLoading) {
    return (
      <DashboardLayout>
        <Box>
          <Typography variant="h4" gutterBottom>
            Notification Templates
          </Typography>
          <LoadingSpinner />
        </Box>
      </DashboardLayout>
    );
  }

  return (
    <DashboardLayout>
      <Box>
        <Typography variant="h4" gutterBottom>
          Notification Templates
        </Typography>
        <Typography variant="body2" color="text.secondary" sx={{ mb: 3 }}>
          Edit email and push copy for signup, payments, status updates, and concerns. Changes apply immediately without redeploying code.
        </Typography>

        {data?.settings && <NotificationSettingsPanel settings={data.settings} />}

        <Typography variant="h6" sx={{ mb: 2 }}>
          Templates
        </Typography>
        <NotificationTemplateList templates={data?.templates ?? []} isLoading={false} />
      </Box>
    </DashboardLayout>
  );
};

export default NotificationTemplatesPage;

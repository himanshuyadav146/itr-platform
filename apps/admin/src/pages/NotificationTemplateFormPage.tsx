import { Box, Typography } from '@mui/material';
import { useNavigate, useParams } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import { DashboardLayout } from '../components/layout/DashboardLayout';
import { NotificationTemplateForm } from '../components/notifications/NotificationTemplateForm';
import { LoadingSpinner } from '../components/common/LoadingSpinner';
import { notificationTemplatesApi } from '../api/notificationTemplates';

const NotificationTemplateFormPage = () => {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const templateId = Number(id);

  const { data: template, isLoading, isError } = useQuery({
    queryKey: ['notification-template', templateId],
    queryFn: () => notificationTemplatesApi.getById(templateId),
    enabled: Number.isFinite(templateId) && templateId > 0,
  });

  if (!Number.isFinite(templateId) || templateId <= 0) {
    navigate('/notification-templates', { replace: true });
    return null;
  }

  if (isLoading) {
    return (
      <DashboardLayout>
        <Box>
          <Typography variant="h4" gutterBottom>
            Edit Template
          </Typography>
          <LoadingSpinner />
        </Box>
      </DashboardLayout>
    );
  }

  if (isError || !template) {
    navigate('/notification-templates', { replace: true });
    return null;
  }

  return (
    <DashboardLayout>
      <Box>
        <Typography variant="h4" gutterBottom>
          Edit Template
        </Typography>
        <NotificationTemplateForm template={template} />
      </Box>
    </DashboardLayout>
  );
};

export default NotificationTemplateFormPage;

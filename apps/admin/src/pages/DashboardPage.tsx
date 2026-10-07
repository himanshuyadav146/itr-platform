import { useState } from 'react';
import { Box, Typography } from '@mui/material';
import { DashboardLayout } from '../components/layout/DashboardLayout';
import { KPICard } from '../components/dashboard/KPICard';
import { ITRGrid } from '../components/dashboard/ITRGrid';
import { LoadingSpinner } from '../components/common/LoadingSpinner';
import { useQuery } from '@tanstack/react-query';
import { dashboardApi } from '../api/dashboard';
import { itrApi } from '../api/itr';
import { formatNumber } from '../utils/formatters';
import { useAuth } from '../hooks/useAuth';
import { useNavigate } from 'react-router-dom';
import {
  Description as DescriptionIcon,
  CheckCircle as CheckCircleIcon,
  Pending as PendingIcon,
  Paid as PaidIcon,
} from '@mui/icons-material';
import { ITRDisplayStatus } from '../types/enums';
import type { ITRWithDetails } from '../types/itr';

type FilterType = 'all' | 'pending' | 'paid' | 'in_progress' | 'completed';

const DashboardPage = () => {
  const { isAuthenticated } = useAuth();
  const navigate = useNavigate();
  const [selectedFilter, setSelectedFilter] = useState<FilterType>('all');

  const { data: stats, isLoading: statsLoading, error: statsError } = useQuery({
    queryKey: ['dashboard-stats'],
    queryFn: () => dashboardApi.getDashboardStats(),
    enabled: isAuthenticated,
    retry: false,
  });

  const { data: itrsData, isLoading: itrsLoading } = useQuery({
    queryKey: ['itrs'],
    queryFn: () => itrApi.getITRs({ limit: 100 }),
    enabled: isAuthenticated,
  });

  const allITRs = itrsData?.items || [];

  const getFilteredITRs = (): ITRWithDetails[] => {
    switch (selectedFilter) {
      case 'pending':
        return allITRs.filter((itr) => itr.status === ITRDisplayStatus.PENDING);
      case 'paid':
        return allITRs.filter((itr) => itr.status === ITRDisplayStatus.PAID);
      case 'in_progress':
        return allITRs.filter((itr) => itr.status === ITRDisplayStatus.IN_PROGRESS);
      case 'completed':
        return allITRs.filter((itr) => itr.status === ITRDisplayStatus.COMPLETED);
      default:
        return allITRs;
    }
  };

  const filteredITRs = getFilteredITRs();

  const pendingCount = allITRs.filter((itr) => itr.status === ITRDisplayStatus.PENDING).length;
  const paidCount = allITRs.filter((itr) => itr.status === ITRDisplayStatus.PAID).length;
  const inProgressCount = allITRs.filter((itr) => itr.status === ITRDisplayStatus.IN_PROGRESS).length;
  const completedCount = allITRs.filter((itr) => itr.status === ITRDisplayStatus.COMPLETED).length;

  const filterTitles: Record<FilterType, string> = {
    all: 'All ITRs',
    pending: 'Pending ITRs',
    paid: 'Paid ITRs',
    in_progress: 'In Progress ITRs',
    completed: 'Completed ITRs',
  };

  const handleITRClick = (itr: ITRWithDetails) => {
    navigate(`/itrs/${itr.id}`);
  };

  if (statsLoading || itrsLoading) {
    return (
      <DashboardLayout>
        <LoadingSpinner fullScreen />
      </DashboardLayout>
    );
  }

  if (statsError || !stats) {
    return (
      <DashboardLayout>
        <Box>Error loading dashboard data</Box>
      </DashboardLayout>
    );
  }

  return (
    <DashboardLayout>
      <Box sx={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
        <Box className="fade-in">
          <Typography
            variant="h4"
            sx={{
              fontWeight: 700,
              mb: 1,
              background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
              backgroundClip: 'text',
              WebkitBackgroundClip: 'text',
              WebkitTextFillColor: 'transparent',
            }}
          >
            Dashboard
          </Typography>
          <Typography variant="body1" color="text.secondary">
            Welcome back! Here&apos;s an overview of your ITR management.
          </Typography>
        </Box>

        <Box
          className="slide-in-left"
          sx={{
            display: 'grid',
            gridTemplateColumns: {
              xs: '1fr',
              sm: 'repeat(2, 1fr)',
              md: 'repeat(4, 1fr)',
            },
            gap: 3,
          }}
        >
          <KPICard
            title="Pending"
            value={formatNumber(pendingCount)}
            icon={<PendingIcon sx={{ fontSize: 32 }} />}
            color="warning"
            onClick={() => setSelectedFilter('pending')}
            selected={selectedFilter === 'pending'}
          />
          <KPICard
            title="Paid"
            value={formatNumber(paidCount)}
            icon={<PaidIcon sx={{ fontSize: 32 }} />}
            color="info"
            onClick={() => setSelectedFilter('paid')}
            selected={selectedFilter === 'paid'}
          />
          <KPICard
            title="In Progress"
            value={formatNumber(inProgressCount)}
            icon={<DescriptionIcon sx={{ fontSize: 32 }} />}
            color="secondary"
            onClick={() => setSelectedFilter('in_progress')}
            selected={selectedFilter === 'in_progress'}
          />
          <KPICard
            title="Completed"
            value={formatNumber(completedCount)}
            icon={<CheckCircleIcon sx={{ fontSize: 32 }} />}
            color="success"
            onClick={() => setSelectedFilter('completed')}
            selected={selectedFilter === 'completed'}
          />
        </Box>

        <Box className="fade-in">
          <Box sx={{ mb: 3, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <Typography variant="h5" sx={{ fontWeight: 600 }}>
              {filterTitles[selectedFilter]}
            </Typography>
            {selectedFilter !== 'all' && (
              <Typography
                variant="body2"
                sx={{
                  color: 'primary.main',
                  cursor: 'pointer',
                  fontWeight: 600,
                  '&:hover': { textDecoration: 'underline' },
                }}
                onClick={() => setSelectedFilter('all')}
              >
                View All
              </Typography>
            )}
          </Box>
          <ITRGrid itrs={filteredITRs} onITRClick={handleITRClick} />
        </Box>
      </Box>
    </DashboardLayout>
  );
};

export default DashboardPage;

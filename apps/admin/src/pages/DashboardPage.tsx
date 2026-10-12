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
} from '@mui/icons-material';
import { ITRStatus } from '../types/enums';
import type { ITRWithDetails } from '../types/itr';

type FilterType = 'all' | 'assigned' | 'filed' | 'pending';

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

  // Fetch ITRs from API
  const { data: itrsData, isLoading: itrsLoading } = useQuery({
    queryKey: ['itrs'],
    queryFn: () => itrApi.getITRs(),
    enabled: isAuthenticated,
  });

  const allITRs = itrsData?.items || [];

  // Filter ITRs based on selected filter
  const getFilteredITRs = (): ITRWithDetails[] => {
    switch (selectedFilter) {
      case 'assigned':
        return allITRs.filter((itr) => itr.status === ITRStatus.ASSIGNED);
      case 'filed':
        return allITRs.filter((itr) => itr.status === ITRStatus.FILED);
      case 'pending':
        return allITRs.filter((itr) => itr.status === ITRStatus.PENDING);
      default:
        return allITRs;
    }
  };

  const filteredITRs = getFilteredITRs();

  // Count ITRs by status
  const assignedCount = allITRs.filter((itr) => itr.status === ITRStatus.ASSIGNED).length;
  const filedCount = allITRs.filter((itr) => itr.status === ITRStatus.FILED).length;
  const pendingCount = allITRs.filter((itr) => itr.status === ITRStatus.PENDING).length;

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
        {/* Page Header */}
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
            Welcome back! Here's an overview of your ITR management.
          </Typography>
        </Box>

        {/* KPI Cards */}
        <Box
          className="slide-in-left"
          sx={{
            display: 'grid',
            gridTemplateColumns: {
              xs: '1fr',
              sm: 'repeat(2, 1fr)',
              md: 'repeat(3, 1fr)',
            },
            gap: 3,
          }}
        >
          <KPICard
            title="Assigned ITRs"
            value={formatNumber(assignedCount)}
            icon={<DescriptionIcon sx={{ fontSize: 32 }} />}
            color="info"
            onClick={() => setSelectedFilter('assigned')}
            selected={selectedFilter === 'assigned'}
          />
          <KPICard
            title="Filed ITRs"
            value={formatNumber(filedCount)}
            icon={<CheckCircleIcon sx={{ fontSize: 32 }} />}
            color="success"
            onClick={() => setSelectedFilter('filed')}
            selected={selectedFilter === 'filed'}
          />
          <KPICard
            title="Pending ITRs"
            value={formatNumber(pendingCount)}
            icon={<PendingIcon sx={{ fontSize: 32 }} />}
            color="warning"
            onClick={() => setSelectedFilter('pending')}
            selected={selectedFilter === 'pending'}
          />
        </Box>

        {/* ITR Grid Section */}
        <Box className="fade-in">
          <Box sx={{ mb: 3, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <Typography variant="h5" sx={{ fontWeight: 600 }}>
              {selectedFilter === 'all'
                ? 'All ITRs'
                : selectedFilter === 'assigned'
                  ? 'Assigned ITRs'
                  : selectedFilter === 'filed'
                    ? 'Filed ITRs'
                    : 'Pending ITRs'}
            </Typography>
            {selectedFilter !== 'all' && (
              <Typography
                variant="body2"
                sx={{
                  color: 'primary.main',
                  cursor: 'pointer',
                  fontWeight: 600,
                  '&:hover': {
                    textDecoration: 'underline',
                  },
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

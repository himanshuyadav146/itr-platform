import { useState } from 'react';
import {
  Box,
  TextField,
  Button,
  Paper,
  MenuItem,
} from '@mui/material';
import { DataGrid, GridActionsCellItem } from '@mui/x-data-grid';
import type { GridColDef } from '@mui/x-data-grid';
import { Visibility as ViewIcon, Edit as EditIcon, Assignment as AssignmentIcon } from '@mui/icons-material';
import { useQuery } from '@tanstack/react-query';
import { itrApi } from '../../api/itr';
import { formatDate } from '../../utils/formatters';
import { ITR_STATUS_LABELS } from '../../utils/constants';
import { useNavigate } from 'react-router-dom';
import { useAppSelector, useAppDispatch } from '../../store/hooks';
import { setITRFilters } from '../../store/slices/filtersSlice';
import { ITRStatus } from '../../types/enums';
import { AssignProfessionalModal } from './AssignProfessionalModal';
import type { ITRDetail } from '../../types';
import { usePermissions } from '../../hooks/usePermissions';
import { Permission } from '../../types/enums';
import { StatusChip } from '../common/StatusChip';

const columns: GridColDef[] = [
  { field: 'id', headerName: 'ITR ID', width: 100 },
  {
    field: 'clientName',
    headerName: 'Client Name',
    width: 200,
    valueGetter: (value) => value || 'N/A',
  },
  {
    field: 'assignedProfessionalName',
    headerName: 'Assigned To',
    width: 180,
    valueGetter: (value) => value || 'Unassigned',
  },
  {
    field: 'financialYear',
    headerName: 'Financial Year',
    width: 130,
  },
  {
    field: 'status',
    headerName: 'Status',
    width: 130,
    renderCell: (params) => {
      const status = params.value as string;
      return <StatusChip status={status} />;
    },
  },
  {
    field: 'createdAt',
    headerName: 'Created Date',
    width: 150,
    valueGetter: (value) => (value ? formatDate(value) : 'N/A'),
  },
];

export const ITRList = () => {
  const navigate = useNavigate();
  const dispatch = useAppDispatch();
  const { itrFilters } = useAppSelector((state) => state.filters);
  const [statusFilter, setStatusFilter] = useState<string>(itrFilters.status?.toString() || '');
  const [assignModalOpen, setAssignModalOpen] = useState(false);
  const [selectedITR, setSelectedITR] = useState<ITRDetail | null>(null);
  const { hasPermission } = usePermissions();

  const { data, isLoading } = useQuery({
    queryKey: ['itrs', itrFilters],
    queryFn: () => itrApi.getITRs(itrFilters),
  });

  const { data: selectedITRDetails } = useQuery({
    queryKey: ['itr', selectedITR?.id],
    queryFn: () => selectedITR ? itrApi.getITRDetails(selectedITR.id) : null,
    enabled: !!selectedITR && assignModalOpen,
  });

  const handleStatusFilter = (status: string) => {
    setStatusFilter(status);
    dispatch(setITRFilters({ status: (status ? status as ITRStatus : undefined), page: 1 }));
  };

  const handleView = (id: number) => {
    navigate(`/itrs/${id}`);
  };

  const handleEdit = (id: number) => {
    navigate(`/itrs/${id}?edit=true`);
  };

  const handleAssign = (row: ITRDetail) => {
    setSelectedITR(row);
    setAssignModalOpen(true);
  };

  const handleCloseAssignModal = () => {
    setAssignModalOpen(false);
    setSelectedITR(null);
  };

  const columnsWithActions: GridColDef[] = [
    ...columns,
    {
      field: 'actions',
      type: 'actions',
      headerName: 'Actions',
      width: hasPermission(Permission.ASSIGN_ITR) ? 180 : 120,
      getActions: (params) => {
        const row = params.row as ITRDetail;
        const actions = [
          <GridActionsCellItem
            key="view"
            icon={<ViewIcon />}
            label="View"
            onClick={() => handleView(params.id as number)}
          />,
          <GridActionsCellItem
            key="edit"
            icon={<EditIcon />}
            label="Edit"
            onClick={() => handleEdit(params.id as number)}
          />,
        ];

        const hasSuccessfulPayment = row.status === 'PAID' || row.status === 'SUCCESS';
        if (hasPermission(Permission.ASSIGN_ITR) && hasSuccessfulPayment) {
          actions.push(
            <GridActionsCellItem
              key="assign"
              icon={<AssignmentIcon />}
              label="Assign"
              onClick={() => handleAssign(row)}
            />
          );
        }

        return actions;
      },
    },
  ];

  return (
    <Paper sx={{ p: 3 }}>
      <Box sx={{ mb: 3, display: 'flex', gap: 2, flexWrap: 'wrap' }}>
        <TextField
          select
          label="Status Filter"
          value={statusFilter}
          onChange={(e) => handleStatusFilter(e.target.value)}
          sx={{ minWidth: 200 }}
        >
          <MenuItem value="">All</MenuItem>
          {(Object.values(ITRStatus) as string[]).map((status) => (
            <MenuItem key={status} value={status}>
              {ITR_STATUS_LABELS[status]}
            </MenuItem>
          ))}
        </TextField>
        <Button
          variant="outlined"
          onClick={() => {
            setStatusFilter('');
            dispatch(setITRFilters({ status: undefined, page: 1 }));
          }}
        >
          Clear Filters
        </Button>
      </Box>

      <Box sx={{ height: 600, width: '100%' }}>
        <DataGrid
          rows={data?.items || []}
          columns={columnsWithActions}
          loading={isLoading}
          getRowId={(row) => row.id}
          pagination
          paginationMode="server"
          rowCount={data?.total ?? 0}
          pageSizeOptions={[10, 25, 50]}
          paginationModel={{
            page: (itrFilters.page ?? 1) - 1,
            pageSize: itrFilters.limit ?? 10,
          }}
          onPaginationModelChange={(model) => {
            const { page, pageSize } = model;
            dispatch(
              setITRFilters({
                page: page + 1,
                limit: pageSize,
              })
            );
          }}
        />
      </Box>

      {selectedITR && selectedITRDetails && (
        <AssignProfessionalModal
          open={assignModalOpen}
          onClose={handleCloseAssignModal}
          itr={selectedITR}
          currentAssignment={selectedITRDetails.assignment}
        />
      )}
    </Paper>
  );
};


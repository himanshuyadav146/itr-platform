import { Paper } from '@mui/material';
import { DataGrid, GridActionsCellItem } from '@mui/x-data-grid';
import type { GridColDef } from '@mui/x-data-grid';
import { Edit as EditIcon } from '@mui/icons-material';
import { useNavigate } from 'react-router-dom';
import type { NotificationTemplate } from '../../types/notificationTemplate';
import { LoadingSpinner } from '../common/LoadingSpinner';

interface NotificationTemplateListProps {
  templates: NotificationTemplate[];
  isLoading: boolean;
}

export const NotificationTemplateList = ({ templates, isLoading }: NotificationTemplateListProps) => {
  const navigate = useNavigate();

  const columns: GridColDef[] = [
    { field: 'id', headerName: 'ID', width: 70 },
    { field: 'eventKey', headerName: 'Event', minWidth: 180, flex: 1 },
    { field: 'audience', headerName: 'Audience', width: 130 },
    { field: 'channel', headerName: 'Channel', width: 100 },
    {
      field: 'emailSubject',
      headerName: 'Email subject',
      minWidth: 220,
      flex: 1.2,
      valueGetter: (v) => v ?? '—',
    },
    {
      field: 'pushTitle',
      headerName: 'Push title',
      minWidth: 160,
      flex: 1,
      valueGetter: (v) => v ?? '—',
    },
    {
      field: 'isActive',
      headerName: 'Active',
      width: 90,
      renderCell: (params) => (params.value ? 'Yes' : 'No'),
    },
    {
      field: 'actions',
      type: 'actions',
      headerName: 'Actions',
      width: 90,
      getActions: (params) => {
        const row = params.row as NotificationTemplate;
        return [
          <GridActionsCellItem
            key="edit"
            icon={<EditIcon />}
            label="Edit"
            onClick={() => navigate(`/notification-templates/${row.id}`)}
          />,
        ];
      },
    },
  ];

  if (isLoading) {
    return (
      <Paper sx={{ p: 3 }}>
        <LoadingSpinner />
      </Paper>
    );
  }

  return (
    <Paper sx={{ p: 2 }}>
      <DataGrid
        rows={templates}
        columns={columns}
        autoHeight
        disableRowSelectionOnClick
        pageSizeOptions={[10, 25, 50]}
        initialState={{ pagination: { paginationModel: { pageSize: 25 } } }}
        getRowId={(row) => row.id}
      />
    </Paper>
  );
};

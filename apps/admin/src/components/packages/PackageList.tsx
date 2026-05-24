import { useState } from 'react';
import { Box, Button, Paper } from '@mui/material';
import { DataGrid, GridActionsCellItem } from '@mui/x-data-grid';
import type { GridColDef } from '@mui/x-data-grid';
import { Edit as EditIcon, Delete as DeleteIcon } from '@mui/icons-material';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { useNavigate } from 'react-router-dom';
import { packagesApi } from '../../api/packages';
import type { Package } from '../../types/package';
import { useAppDispatch } from '../../store/hooks';
import { addNotification } from '../../store/slices/uiSlice';
import { ConfirmDialog } from '../common/ConfirmDialog';
import { LoadingSpinner } from '../common/LoadingSpinner';

const columns: GridColDef[] = [
  { field: 'id', headerName: 'ID', width: 80 },
  { field: 'packagename', headerName: 'Package Name', width: 220 },
  { field: 'price', headerName: 'Price', width: 120, valueGetter: (v) => (v != null ? `₹${Number(v).toLocaleString()}` : '') },
  { field: 'description1', headerName: 'Description', minWidth: 200, flex: 1 },
  { field: 'turnover', headerName: 'Turnover', width: 140 },
  { field: 'icon', headerName: 'Icon', width: 120 },
  { field: 'color', headerName: 'Color', width: 100 },
  {
    field: 'isActive',
    headerName: 'Active',
    width: 90,
    renderCell: (params) => (params.value ? 'Yes' : 'No'),
  },
];

export const PackageList = () => {
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const dispatch = useAppDispatch();
  const [deleteTarget, setDeleteTarget] = useState<Package | null>(null);

  const { data: packages = [], isLoading } = useQuery({
    queryKey: ['packages'],
    queryFn: () => packagesApi.getPackages(),
  });

  const deleteMutation = useMutation({
    mutationFn: (id: number) => packagesApi.deletePackage(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['packages'] });
      dispatch(addNotification({ message: 'Package deleted', type: 'success' }));
      setDeleteTarget(null);
    },
    onError: (err: unknown) => {
      const msg = err && typeof err === 'object' && 'response' in err
        ? (err as { response?: { data?: { message?: string } } }).response?.data?.message ?? 'Delete failed'
        : 'Delete failed';
      dispatch(addNotification({ message: msg, type: 'error' }));
      setDeleteTarget(null);
    },
  });

  const columnsWithActions: GridColDef[] = [
    ...columns,
    {
      field: 'actions',
      type: 'actions',
      headerName: 'Actions',
      width: 120,
      getActions: (params) => {
        const row = params.row as Package;
        return [
          <GridActionsCellItem
            key="edit"
            icon={<EditIcon />}
            label="Edit"
            onClick={() => navigate(`/packages/${row.id}`)}
          />,
          <GridActionsCellItem
            key="delete"
            icon={<DeleteIcon />}
            label="Delete"
            onClick={() => setDeleteTarget(row)}
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
    <>
      <Paper sx={{ p: 3 }}>
        <Box sx={{ mb: 2, display: 'flex', justifyContent: 'flex-end' }}>
          <Button variant="contained" onClick={() => navigate('/packages/new')}>
            Add Package
          </Button>
        </Box>
        <Box sx={{ height: 600, width: '100%' }}>
          <DataGrid
            rows={packages}
            columns={columnsWithActions}
            getRowId={(row) => row.id}
            pagination
            pageSizeOptions={[10, 25, 50]}
            initialState={{ pagination: { paginationModel: { page: 0, pageSize: 10 } } }}
          />
        </Box>
      </Paper>

      <ConfirmDialog
        open={!!deleteTarget}
        title="Delete Package"
        message={deleteTarget ? `Delete "${deleteTarget.packagename}"?` : ''}
        onConfirm={() => deleteTarget && deleteMutation.mutate(deleteTarget.id)}
        onCancel={() => setDeleteTarget(null)}
        confirmText="Delete"
        confirmColor="error"
      />
    </>
  );
};

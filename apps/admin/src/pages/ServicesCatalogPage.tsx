import { useState } from 'react';
import {
  Alert,
  Box,
  Button,
  Chip,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  Paper,
  TextField,
  Typography,
} from '@mui/material';
import { DataGrid, type GridColDef } from '@mui/x-data-grid';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { DashboardLayout } from '../components/layout/DashboardLayout';
import { associatesApi } from '../api/associates';

const ServicesCatalogPage = () => {
  const queryClient = useQueryClient();
  const [open, setOpen] = useState(false);
  const [name, setName] = useState('');
  const [description, setDescription] = useState('');
  const [error, setError] = useState<string | null>(null);

  const { data, isLoading } = useQuery({
    queryKey: ['admin-services'],
    queryFn: () => associatesApi.listCatalog(),
  });

  const addService = useMutation({
    mutationFn: () => associatesApi.addCatalogService(name.trim(), description.trim()),
    onSuccess: () => {
      setOpen(false);
      setName('');
      setDescription('');
      setError(null);
      queryClient.invalidateQueries({ queryKey: ['admin-services'] });
    },
    onError: (err: any) => {
      setError(err?.response?.data?.data?.message || 'Could not add service');
    },
  });

  const toggle = useMutation({
    mutationFn: ({ id, is_active }: { id: number; is_active: boolean }) =>
      associatesApi.updateCatalogService(id, { is_active }),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['admin-services'] }),
  });

  const columns: GridColDef[] = [
    { field: 'name', headerName: 'Service', flex: 1, minWidth: 180 },
    { field: 'description', headerName: 'Description', flex: 1.4, minWidth: 240 },
    {
      field: 'is_active',
      headerName: 'Active',
      width: 120,
      renderCell: (params) => (
        <Chip size="small" color={params.value ? 'success' : 'default'} label={params.value ? 'Active' : 'Hidden'} />
      ),
    },
    {
      field: 'actions',
      headerName: '',
      width: 140,
      sortable: false,
      renderCell: (params) => (
        <Button size="small" onClick={() => toggle.mutate({ id: params.row.id, is_active: !params.row.is_active })}>
          {params.row.is_active ? 'Hide' : 'Show'}
        </Button>
      ),
    },
  ];

  return (
    <DashboardLayout>
      <Box sx={{ display: 'flex', flexDirection: 'column', gap: 3 }}>
        <Box sx={{ display: 'flex', justifyContent: 'space-between', gap: 2, flexWrap: 'wrap' }}>
          <Box>
            <Typography variant="h4" sx={{ fontWeight: 700, mb: 0.5 }}>
              Platform Services Catalog
            </Typography>
            <Typography variant="body1" color="text.secondary">
              Services associates can list a fee against. Clients pick a service, then a named associate.
            </Typography>
          </Box>
          <Button variant="contained" onClick={() => setOpen(true)}>
            Add service
          </Button>
        </Box>

        <Paper sx={{ p: 2 }}>
          <DataGrid
            autoHeight
            rows={data || []}
            columns={columns}
            loading={isLoading}
            pageSizeOptions={[10, 25]}
            initialState={{ pagination: { paginationModel: { pageSize: 10 } } }}
            disableRowSelectionOnClick
            sx={{ border: 0, '& .MuiDataGrid-columnHeaders': { backgroundColor: '#f8fafc' } }}
          />
        </Paper>
      </Box>

      <Dialog open={open} onClose={() => setOpen(false)} fullWidth maxWidth="sm">
        <DialogTitle>Add catalog service</DialogTitle>
        <DialogContent>
          {error && (
            <Alert severity="error" sx={{ mb: 2 }}>
              {error}
            </Alert>
          )}
          <TextField fullWidth margin="normal" label="Name" value={name} onChange={(e) => setName(e.target.value)} />
          <TextField
            fullWidth
            margin="normal"
            label="Description"
            value={description}
            onChange={(e) => setDescription(e.target.value)}
            multiline
            minRows={3}
          />
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setOpen(false)}>Cancel</Button>
          <Button variant="contained" disabled={!name.trim() || addService.isPending} onClick={() => addService.mutate()}>
            Save
          </Button>
        </DialogActions>
      </Dialog>
    </DashboardLayout>
  );
};

export default ServicesCatalogPage;

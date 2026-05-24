import { useState } from 'react';
import {
  Box,
  TextField,
  Button,
  Paper,
  InputAdornment,
} from '@mui/material';
import { DataGrid, GridActionsCellItem } from '@mui/x-data-grid';
import type { GridColDef } from '@mui/x-data-grid';
import { Search as SearchIcon, Edit as EditIcon, Visibility as ViewIcon } from '@mui/icons-material';
import { useQuery } from '@tanstack/react-query';
import { usersApi } from '../../api/users';
import type { User } from '../../types';
import { formatDate, formatCurrency } from '../../utils/formatters';
import { useNavigate } from 'react-router-dom';
import { useAppSelector, useAppDispatch } from '../../store/hooks';
import { setUserFilters } from '../../store/slices/filtersSlice';

const columns: GridColDef[] = [
  { field: 'UserId', headerName: 'ID', width: 80 },
  {
    field: 'name',
    headerName: 'Name',
    width: 200,
    valueGetter: (_value, row: User) =>
      `${row.FirstName || ''} ${row.MiddleName || ''} ${row.LastName || ''}`.trim() || 'N/A',
  },
  { field: 'Email', headerName: 'Email', width: 250 },
  { field: 'Mobile', headerName: 'Phone', width: 150 },
  {
    field: 'role',
    headerName: 'Role',
    width: 120,
    valueGetter: (value) => value || 'CLIENT',
  },
  {
    field: 'totalITRsAssigned',
    headerName: 'ITRs Assigned',
    width: 130,
    type: 'number',
    valueGetter: (value) => value || 0,
  },
  {
    field: 'totalITRsFiled',
    headerName: 'ITRs Filed',
    width: 120,
    type: 'number',
    valueGetter: (value) => value || 0,
  },
  {
    field: 'revenueGenerated',
    headerName: 'Revenue',
    width: 150,
    type: 'number',
    valueGetter: (value) => formatCurrency(value || 0),
  },
  {
    field: 'CreatedAt',
    headerName: 'Created',
    width: 150,
    valueGetter: (value) => (value ? formatDate(value) : 'N/A'),
  },
];

export const UserList = () => {
  const navigate = useNavigate();
  const dispatch = useAppDispatch();
  const { userFilters } = useAppSelector((state) => state.filters);
  const [search, setSearch] = useState(userFilters.search || '');

  const { data, isLoading } = useQuery({
    queryKey: ['users', userFilters],
    queryFn: () => usersApi.getUsers(userFilters),
  });

  const handleSearch = () => {
    dispatch(setUserFilters({ search, page: 1 }));
  };

  const handleView = (id: number) => {
    navigate(`/users/${id}`);
  };

  const handleEdit = (id: number) => {
    navigate(`/users/${id}?edit=true`);
  };

  const columnsWithActions: GridColDef[] = [
    ...columns,
    {
      field: 'actions',
      type: 'actions',
      headerName: 'Actions',
      width: 120,
      getActions: (params) => [
        <GridActionsCellItem
          icon={<ViewIcon />}
          label="View"
          onClick={() => handleView(params.id as number)}
        />,
        <GridActionsCellItem
          icon={<EditIcon />}
          label="Edit"
          onClick={() => handleEdit(params.id as number)}
        />,
      ],
    },
  ];

  return (
    <Paper sx={{ p: 3 }}>
      <Box sx={{ mb: 3, display: 'flex', gap: 2, flexWrap: 'wrap' }}>
        <TextField
          placeholder="Search by name or email..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          onKeyPress={(e) => e.key === 'Enter' && handleSearch()}
          InputProps={{
            startAdornment: (
              <InputAdornment position="start">
                <SearchIcon />
              </InputAdornment>
            ),
          }}
          sx={{ flexGrow: 1, minWidth: 250 }}
        />
        <Button variant="contained" onClick={handleSearch}>
          Search
        </Button>
      </Box>

      <Box sx={{ height: 600, width: '100%' }}>
        <DataGrid
          rows={data?.items || []}
          columns={columnsWithActions}
          loading={isLoading}
          getRowId={(row) => row.UserId}
          pagination
          pageSizeOptions={[10, 25, 50]}
          initialState={{
            pagination: {
              paginationModel: { page: 0, pageSize: 10 },
            },
          }}
        />
      </Box>
    </Paper>
  );
};


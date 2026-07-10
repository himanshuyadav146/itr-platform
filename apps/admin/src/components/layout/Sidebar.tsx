import {
  Drawer,
  List,
  ListItem,
  ListItemButton,
  ListItemIcon,
  ListItemText,
  Toolbar,
  Box,
} from '@mui/material';
import {
  Dashboard as DashboardIcon,
  People as PeopleIcon,
  Description as DescriptionIcon,
  Group as GroupIcon,
  Inventory2 as PackagesIcon,
  Notifications as NotificationsIcon,
} from '@mui/icons-material';
import { useNavigate, useLocation } from 'react-router-dom';
import { useAppSelector } from '../../store/hooks';
import { usePermissions } from '../../hooks/usePermissions';
import { UserRole, Permission } from '../../types/enums';

const drawerWidth = 240;

interface MenuItem {
  text: string;
  icon: React.ReactNode;
  path: string;
  roles?: UserRole[];
  permission?: Permission;
}

const menuItems: MenuItem[] = [
  {
    text: 'Dashboard',
    icon: <DashboardIcon />,
    path: '/dashboard',
  },
  {
    text: 'Users',
    icon: <PeopleIcon />,
    path: '/users',
    roles: [UserRole.ADMIN],
  },
  {
    text: 'ITRs',
    icon: <DescriptionIcon />,
    path: '/itrs',
  },
  {
    text: 'Associates',
    icon: <GroupIcon />,
    path: '/professionals',
    permission: Permission.ASSIGN_ITR,
  },
  {
    text: 'Packages',
    icon: <PackagesIcon />,
    path: '/packages',
    roles: [UserRole.ADMIN],
  },
  {
    text: 'Notifications',
    icon: <NotificationsIcon />,
    path: '/notification-templates',
    roles: [UserRole.ADMIN],
  },
];

export const Sidebar = () => {
  const navigate = useNavigate();
  const location = useLocation();
  const { sidebarOpen } = useAppSelector((state) => state.ui);
  const { role, hasPermission, isAdmin } = usePermissions();

  const normalizedRole = role?.toString().toUpperCase().trim() ?? null;

  const filteredMenuItems = menuItems.filter((item) => {
    // Check permission-based access (same logic as Assignment button)
    if (item.permission) {
      return hasPermission(item.permission) || isAdmin;
    }
    // Role-based access: compare case-insensitively so "admin" / "ADMIN" both work
    if (!item.roles) return true;
    return normalizedRole != null && item.roles.some((r) => r === normalizedRole);
  });

  return (
    <Drawer
      variant="persistent"
      open={sidebarOpen}
      sx={{
        width: drawerWidth,
        flexShrink: 0,
        '& .MuiDrawer-paper': {
          width: drawerWidth,
          boxSizing: 'border-box',
        },
      }}
    >
      <Toolbar />
      <Box sx={{ overflow: 'auto' }}>
        <List>
          {filteredMenuItems.map((item) => {
            const isActive = location.pathname === item.path || location.pathname.startsWith(item.path + '/');
            return (
              <ListItem key={item.path} disablePadding>
                <ListItemButton
                  selected={isActive}
                  onClick={() => navigate(item.path)}
                  sx={{
                    '&.Mui-selected': {
                      backgroundColor: 'primary.main',
                      color: 'primary.contrastText',
                      '&:hover': {
                        backgroundColor: 'primary.dark',
                      },
                      '& .MuiListItemIcon-root': {
                        color: 'primary.contrastText',
                      },
                    },
                  }}
                >
                  <ListItemIcon
                    sx={{
                      color: isActive ? 'primary.contrastText' : 'inherit',
                    }}
                  >
                    {item.icon}
                  </ListItemIcon>
                  <ListItemText primary={item.text} />
                </ListItemButton>
              </ListItem>
            );
          })}
        </List>
      </Box>
    </Drawer>
  );
};


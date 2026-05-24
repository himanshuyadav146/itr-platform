import { Paper, Typography, List, ListItem, ListItemText, Chip } from '@mui/material';
import { formatDateTime } from '../../utils/formatters';
import { ITR_STATUS_COLORS, ITR_STATUS_LABELS } from '../../utils/constants';

interface ActivityItem {
  id: number;
  type: 'itr_update' | 'assignment' | 'comment';
  message: string;
  timestamp: string;
  status?: string;
}

interface RecentActivityProps {
  activities: ActivityItem[];
}

export const RecentActivity = ({ activities }: RecentActivityProps) => {
  return (
    <Paper sx={{ p: 3 }}>
      <Typography variant="h6" gutterBottom>
        Recent Activity
      </Typography>
      <List>
        {activities.length === 0 ? (
          <ListItem>
            <ListItemText primary="No recent activity" />
          </ListItem>
        ) : (
          activities.map((activity) => (
            <ListItem key={activity.id} divider>
              <ListItemText
                primary={activity.message}
                secondary={formatDateTime(activity.timestamp)}
              />
              {activity.status && (
                <Chip
                  label={ITR_STATUS_LABELS[activity.status] || activity.status}
                  size="small"
                  sx={{
                    backgroundColor: ITR_STATUS_COLORS[activity.status] || '#gray',
                    color: 'white',
                  }}
                />
              )}
            </ListItem>
          ))
        )}
      </List>
    </Paper>
  );
};


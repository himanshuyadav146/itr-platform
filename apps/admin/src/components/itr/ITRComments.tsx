import { Box, Paper, Typography, List, ListItem, ListItemText, Chip, Divider } from '@mui/material';
import type { ITRComment } from '../../types';
import { formatDateTime } from '../../utils/formatters';
import { ITR_STATUS_COLORS, ITR_STATUS_LABELS } from '../../utils/constants';

interface ITRCommentsProps {
  comments: ITRComment[];
}

export const ITRComments = ({ comments }: ITRCommentsProps) => {
  if (comments.length === 0) {
    return (
      <Paper sx={{ p: 3 }}>
        <Typography variant="h6" gutterBottom>
          Comments & Status History
        </Typography>
        <Typography variant="body2" color="text.secondary" sx={{ mt: 2 }}>
          No comments yet
        </Typography>
      </Paper>
    );
  }

  return (
    <Paper sx={{ p: 3 }}>
      <Typography variant="h6" gutterBottom>
        Comments & Status History
      </Typography>
      <List>
        {comments.map((comment, index) => (
          <Box key={comment.id}>
            <ListItem alignItems="flex-start">
              <ListItemText
                primary={
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 1 }}>
                    <Chip
                      label={ITR_STATUS_LABELS[comment.status_enum] || comment.status_enum}
                      size="small"
                      sx={{
                        backgroundColor: ITR_STATUS_COLORS[comment.status_enum] || '#gray',
                        color: 'white',
                      }}
                    />
                    <Typography variant="caption" color="text.secondary">
                      {formatDateTime(comment.created_at)}
                    </Typography>
                  </Box>
                }
                secondary={
                  <Typography variant="body2" sx={{ mt: 1 }}>
                    {comment.comment_text}
                  </Typography>
                }
              />
            </ListItem>
            {index < comments.length - 1 && <Divider component="li" />}
          </Box>
        ))}
      </List>
    </Paper>
  );
};

import { Box, Paper, Typography, List, ListItem, ListItemText, IconButton } from '@mui/material';
import { Download as DownloadIcon, Visibility as ViewIcon } from '@mui/icons-material';
import type { Document } from '../../api/documents';
import {
  documentsApi,
  DOCUMENT_CATEGORIES,
  getDocumentCategory,
} from '../../api/documents';
import { formatDate } from '../../utils/formatters';

interface DocumentListProps {
  documents: Document[];
  /** Client PAN for `/uploads/{PAN}/{fileName}` URLs */
  panNumber?: string;
  onView?: (document: Document) => void;
}

function groupByCategory(documents: Document[]): Map<string, Document[]> {
  const map = new Map<string, Document[]>();
  for (const cat of DOCUMENT_CATEGORIES) {
    map.set(cat, []);
  }
  for (const doc of documents) {
    const cat = getDocumentCategory(doc);
    map.get(cat)!.push(doc);
  }
  return map;
}

export const DocumentList = ({ documents, panNumber, onView }: DocumentListProps) => {
  const handleDownload = (document: Document) => {
    const url = documentsApi.getDocumentDownloadUrl(document, panNumber);
    if (url) window.open(url, '_blank');
  };

  const canDownload = (doc: Document) =>
    !!(panNumber?.trim() && doc.fileName?.trim());

  const byCategory = groupByCategory(documents);

  return (
    <Paper sx={{ p: 3 }}>
      <Typography variant="h6" gutterBottom>
        Documents
      </Typography>
      {DOCUMENT_CATEGORIES.map((category) => {
        const items = byCategory.get(category) || [];
        return (
          <Box key={category} sx={{ mb: 3 }}>
            <Typography variant="subtitle1" color="text.secondary" gutterBottom sx={{ fontWeight: 600 }}>
              {category}
            </Typography>
            {items.length === 0 ? (
              <Typography variant="body2" color="text.secondary" sx={{ pl: 1 }}>
                No documents in this category
              </Typography>
            ) : (
              <List disablePadding>
                {items.map((doc) => (
                  <ListItem
                    key={String(doc.id)}
                    secondaryAction={
                      <Box>
                        {onView && (
                          <IconButton edge="end" onClick={() => onView(doc)} sx={{ mr: 1 }}>
                            <ViewIcon />
                          </IconButton>
                        )}
                        {canDownload(doc) && (
                          <IconButton edge="end" onClick={() => handleDownload(doc)}>
                            <DownloadIcon />
                          </IconButton>
                        )}
                      </Box>
                    }
                  >
                    <ListItemText
                      primary={doc.documentName}
                      secondary={`Uploaded: ${formatDate(doc.createdAt)} | Type: ${doc.fileType || 'N/A'}`}
                    />
                  </ListItem>
                ))}
              </List>
            )}
          </Box>
        );
      })}
    </Paper>
  );
};


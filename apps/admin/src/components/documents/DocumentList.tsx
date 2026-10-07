import {
  Box,
  Paper,
  Typography,
  List,
  ListItem,
  ListItemText,
  IconButton,
  Tooltip,
  Chip,
} from '@mui/material';
import {
  Download as DownloadIcon,
  Visibility as ViewIcon,
  ContentCopy as CopyIcon,
  Lock as LockIcon,
} from '@mui/icons-material';
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

function isForm16Category(category: string): boolean {
  return category === 'Form-16 A' || category === 'Form-16 B';
}

function hasPdfPassword(doc: Document): boolean {
  return !!(doc.filePassword && doc.filePassword.trim().length > 0);
}

async function copyToClipboard(text: string): Promise<void> {
  try {
    await navigator.clipboard.writeText(text);
  } catch {
    // Fallback for older browsers
    const textarea = document.createElement('textarea');
    textarea.value = text;
    document.body.appendChild(textarea);
    textarea.select();
    document.execCommand('copy');
    document.body.removeChild(textarea);
  }
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
                {items.map((doc) => {
                  const showPassword = isForm16Category(category);
                  const passwordSet = hasPdfPassword(doc);

                  return (
                    <ListItem
                      key={String(doc.id)}
                      alignItems="flex-start"
                      secondaryAction={
                        <Box>
                          {onView && (
                            <IconButton edge="end" onClick={() => onView(doc)} sx={{ mr: 0.5 }}>
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
                        primary={doc.documentName || doc.fileName}
                        secondary={
                          <Box component="span" sx={{ display: 'block', mt: 0.5 }}>
                            <Typography variant="body2" color="text.secondary" component="span" display="block">
                              Uploaded: {formatDate(doc.createdAt)} | Type: {doc.fileType || 'N/A'}
                            </Typography>
                            {showPassword && (
                              <Box
                                component="span"
                                sx={{
                                  display: 'inline-flex',
                                  alignItems: 'center',
                                  gap: 0.5,
                                  mt: 1,
                                  flexWrap: 'wrap',
                                }}
                              >
                                <Chip
                                  size="small"
                                  icon={<LockIcon sx={{ fontSize: 16 }} />}
                                  label={
                                    passwordSet
                                      ? `PDF password: ${doc.filePassword}`
                                      : 'No PDF password provided'
                                  }
                                  color={passwordSet ? 'success' : 'default'}
                                  variant={passwordSet ? 'filled' : 'outlined'}
                                  sx={{ maxWidth: '100%', height: 'auto', py: 0.25 }}
                                />
                                {passwordSet && (
                                  <Tooltip title="Copy password">
                                    <IconButton
                                      size="small"
                                      aria-label="Copy PDF password"
                                      onClick={() => void copyToClipboard(doc.filePassword!.trim())}
                                    >
                                      <CopyIcon fontSize="small" />
                                    </IconButton>
                                  </Tooltip>
                                )}
                              </Box>
                            )}
                          </Box>
                        }
                        sx={{ pr: 10 }}
                      />
                    </ListItem>
                  );
                })}
              </List>
            )}
          </Box>
        );
      })}
    </Paper>
  );
};

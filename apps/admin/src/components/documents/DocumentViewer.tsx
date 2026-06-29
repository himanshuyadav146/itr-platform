import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  Box,
  Alert,
  Typography,
  IconButton,
  Tooltip,
} from '@mui/material';
import { ContentCopy as CopyIcon } from '@mui/icons-material';
import type { Document } from '../../api/documents';
import { documentsApi, getDocumentCategory } from '../../api/documents';

interface DocumentViewerProps {
  open: boolean;
  document: Document | null;
  /** Client PAN for `/uploads/{PAN}/{fileName}` URLs */
  panNumber?: string;
  onClose: () => void;
}

async function copyToClipboard(text: string): Promise<void> {
  try {
    await navigator.clipboard.writeText(text);
  } catch {
    const textarea = document.createElement('textarea');
    textarea.value = text;
    document.body.appendChild(textarea);
    textarea.select();
    document.execCommand('copy');
    document.body.removeChild(textarea);
  }
}

export const DocumentViewer = ({ open, document, panNumber, onClose }: DocumentViewerProps) => {
  if (!document) return null;

  const handleDownload = () => {
    const url = documentsApi.getDocumentDownloadUrl(document, panNumber);
    if (url) window.open(url, '_blank');
  };

  const viewUrl = documentsApi.getDocumentViewUrl(document, panNumber);
  const isImage =
    !!document.previewUrl ||
    !!document.image_url ||
    document.fileType?.startsWith('image/') ||
    /^(jpg|jpeg|png|gif|webp)$/i.test(document.fileType || '');
  const isPdf =
    !document.previewUrl &&
    !document.image_url &&
    (document.fileType === 'application/pdf' || /\.pdf$/i.test(document.fileName || ''));
  const imageSrc = isImage ? viewUrl : '';

  const category = getDocumentCategory(document);
  const isForm16 = category === 'Form-16 A' || category === 'Form-16 B';
  const pdfPassword = document.filePassword?.trim() ?? '';
  const hasPassword = pdfPassword.length > 0;

  return (
    <Dialog open={open} onClose={onClose} maxWidth="lg" fullWidth>
      <DialogTitle>{document.documentName}</DialogTitle>
      <DialogContent>
        {isForm16 && (
          <Alert
            severity={hasPassword ? 'info' : 'warning'}
            sx={{ mb: 2 }}
            action={
              hasPassword ? (
                <Tooltip title="Copy password">
                  <IconButton
                    size="small"
                    color="inherit"
                    aria-label="Copy PDF password"
                    onClick={() => void copyToClipboard(pdfPassword)}
                  >
                    <CopyIcon fontSize="small" />
                  </IconButton>
                </Tooltip>
              ) : undefined
            }
          >
            {hasPassword ? (
              <Typography variant="body2">
                This PDF may be password protected. Use this password to open the file:{' '}
                <Box component="span" sx={{ fontWeight: 700, fontFamily: 'monospace' }}>
                  {pdfPassword}
                </Box>
              </Typography>
            ) : (
              <Typography variant="body2">
                No PDF password was provided by the client. If the file is locked, contact the
                client for the password.
              </Typography>
            )}
          </Alert>
        )}
        <Box sx={{ minHeight: 400, display: 'flex', justifyContent: 'center', alignItems: 'center' }}>
          {isImage && imageSrc ? (
            <img
              src={imageSrc}
              alt={document.documentName}
              style={{ maxWidth: '100%', maxHeight: '70vh' }}
            />
          ) : isPdf && viewUrl ? (
            <iframe
              src={viewUrl}
              style={{ width: '100%', height: '70vh', border: 'none' }}
              title={document.documentName}
            />
          ) : (
            <Box sx={{ textAlign: 'center' }}>
              <p>Preview not available for this file type.</p>
              <Button variant="contained" onClick={handleDownload}>
                Download to View
              </Button>
            </Box>
          )}
        </Box>
      </DialogContent>
      <DialogActions>
        {(!!panNumber?.trim() && !!document.fileName?.trim()) && (
          <Button onClick={handleDownload}>Download</Button>
        )}
        <Button onClick={onClose}>Close</Button>
      </DialogActions>
    </Dialog>
  );
};

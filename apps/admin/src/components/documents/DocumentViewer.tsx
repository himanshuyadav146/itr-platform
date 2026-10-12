import { Dialog, DialogTitle, DialogContent, DialogActions, Button, Box } from '@mui/material';
import type { Document } from '../../api/documents';
import { documentsApi } from '../../api/documents';

interface DocumentViewerProps {
  open: boolean;
  document: Document | null;
  /** Client PAN for `/uploads/{PAN}/{fileName}` URLs */
  panNumber?: string;
  onClose: () => void;
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

  return (
    <Dialog open={open} onClose={onClose} maxWidth="lg" fullWidth>
      <DialogTitle>{document.documentName}</DialogTitle>
      <DialogContent>
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


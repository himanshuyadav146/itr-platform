import apiClient from './client';
import { API_ENDPOINTS } from './endpoints';
import { API_BASE_URL } from '../config/api';
import type { ApiResponse } from '../types';

/** Document categories shown in the UI */
export const DOCUMENT_CATEGORIES = ['Form-16 A', 'Form-16 B', 'Other document'] as const;
export type DocumentCategory = (typeof DOCUMENT_CATEGORIES)[number];

/** Join API base + `/uploads/{PAN}/{fileName}` (PAN uppercased). Uses only fileName from API. */
export function buildDocumentUploadUrl(pan: string, fileName: string): string {
  const p = pan.trim().toUpperCase();
  const f = fileName.trim();
  if (!p || !f) return '';
  const base = API_BASE_URL.replace(/\/+$/, '');
  return `${base}/uploads/${encodeURIComponent(p)}/${encodeURIComponent(f)}`;
}

export interface Document {
  id: number | string;
  documentName: string;
  fileType: string;
  filePassword?: string;
  fileName: string;
  createdAt: string;
  /** When set, viewer shows this URL for images instead of download endpoint (e.g. placeholder/dummy) */
  previewUrl?: string;
  /** Full URL for download (e.g. download_document.php?docId=28) */
  downloadUrl?: string;
  /** Full URL for image preview */
  image_url?: string;
  /** Category for grouping; if missing, derived from documentName */
  category?: string;
}

function toDocumentId(value: unknown): number | string {
  if (typeof value === 'number' && !Number.isNaN(value)) return value;
  if (typeof value === 'string') return value;
  const n = Number(value);
  return Number.isNaN(n) ? -1 : n;
}

/** Normalize API document (id may be string, snake_case keys) */
function normalizeDocument(raw: Record<string, unknown>): Document {
  return {
    id: toDocumentId(raw.id ?? raw.Id ?? -1),
    documentName: String(raw.documentName ?? raw.document_name ?? ''),
    fileType: String(raw.fileType ?? raw.file_type ?? ''),
    filePassword: raw.filePassword != null ? String(raw.filePassword) : undefined,
    fileName: String(raw.fileName ?? raw.file_name ?? ''),
    createdAt: String(raw.createdAt ?? raw.created_at ?? ''),
    previewUrl: raw.previewUrl != null ? String(raw.previewUrl) : undefined,
    downloadUrl: raw.downloadUrl != null ? String(raw.downloadUrl) : undefined,
    image_url: raw.image_url != null ? String(raw.image_url) : undefined,
    category: raw.category != null ? String(raw.category) : undefined,
  };
}

/** Derive category from document name for grouping */
export function getDocumentCategory(doc: Document): DocumentCategory {
  if (doc.category) {
    const c = doc.category.trim();
    if (DOCUMENT_CATEGORIES.includes(c as DocumentCategory)) return c as DocumentCategory;
    if (/form\s*[- ]*16\s*a/i.test(c)) return 'Form-16 A';
    if (/form\s*[- ]*16\s*b/i.test(c)) return 'Form-16 B';
    return 'Other document';
  }
  const name = (doc.documentName || '').toLowerCase();
  if (/form\s*[- ]*16\s*a/.test(name) || name.includes('form-16 a')) return 'Form-16 A';
  if (/form\s*[- ]*16\s*b/.test(name) || name.includes('form-16 b')) return 'Form-16 B';
  return 'Other document';
}

/** Placeholder document shown when API returns empty list; replace with real logic later */
export const DUMMY_DOCUMENT_PLACEHOLDER: Document = {
  id: -1,
  documentName: 'No documents uploaded yet',
  fileType: 'image/png',
  fileName: '',
  createdAt: new Date().toISOString(),
  previewUrl: 'https://placehold.co/600x400/e2e8f0/64748b?text=No+Documents',
};

export const documentsApi = {
  getDocuments: async (panNumber: string): Promise<Document[]> => {
    const response = await apiClient.get<ApiResponse<{ documents: unknown[] }>>(
      API_ENDPOINTS.DOCUMENTS(panNumber)
    );
    const raw = response.data.data?.documents || [];
    return Array.isArray(raw) ? raw.map((d) => normalizeDocument(d as Record<string, unknown>)) : [];
  },

  getDocumentsByITR: async (itrId: number): Promise<Document[]> => {
    try {
      const response = await apiClient.get<ApiResponse<{ documents: unknown[] }>>(
        API_ENDPOINTS.DOCUMENTS_BY_ITR(itrId)
      );
      const raw = response.data.data?.documents || [];
      return Array.isArray(raw) ? raw.map((d) => normalizeDocument(d as Record<string, unknown>)) : [];
    } catch (err: unknown) {
      const status = (err as { response?: { status?: number } })?.response?.status;
      if (status === 404) return [];
      throw err;
    }
  },

  downloadDocument: (filename: string): string => {
    return `${API_BASE_URL}${API_ENDPOINTS.DOCUMENT_DOWNLOAD(filename)}`;
  },

  /**
   * Preview URL: only `fileName` from API + client-built `/uploads/{PAN}/{fileName}`.
   * Without `pan`, falls back to `previewUrl` (e.g. placeholder) when `fileName` is empty.
   */
  getDocumentViewUrl: (doc: Document, pan?: string): string => {
    const file = doc.fileName?.trim();
    if (!file) {
      return doc.previewUrl ? String(doc.previewUrl) : '';
    }
    const panNorm = pan?.trim();
    if (panNorm) return buildDocumentUploadUrl(panNorm, file);
    return '';
  },

  /** Same as view: uploads path from `pan` + `fileName` only. */
  getDocumentDownloadUrl: (doc: Document, pan?: string): string => {
    const file = doc.fileName?.trim();
    if (!file) return '';
    const panNorm = pan?.trim();
    if (panNorm) return buildDocumentUploadUrl(panNorm, file);
    return '';
  },
};


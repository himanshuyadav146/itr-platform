import apiClient from './client';
import { API_ENDPOINTS } from './endpoints';
import type {
  NotificationSettings,
  NotificationSettingsPayload,
  NotificationTemplate,
  NotificationTemplateFormPayload,
} from '../types/notificationTemplate';
import type { ApiResponse } from '../types/api';

function normalizeTemplate(raw: Record<string, unknown>): NotificationTemplate {
  return {
    id: Number(raw.id),
    eventKey: String(raw.eventKey ?? raw.event_key ?? ''),
    audience: (raw.audience ?? 'ADMIN') as NotificationTemplate['audience'],
    channel: (raw.channel ?? 'BOTH') as NotificationTemplate['channel'],
    emailSubject: raw.emailSubject != null ? String(raw.emailSubject) : raw.email_subject != null ? String(raw.email_subject) : null,
    emailBodyHtml: raw.emailBodyHtml != null ? String(raw.emailBodyHtml) : raw.email_body_html != null ? String(raw.email_body_html) : null,
    emailBodyText: raw.emailBodyText != null ? String(raw.emailBodyText) : raw.email_body_text != null ? String(raw.email_body_text) : null,
    pushTitle: raw.pushTitle != null ? String(raw.pushTitle) : raw.push_title != null ? String(raw.push_title) : null,
    pushBody: raw.pushBody != null ? String(raw.pushBody) : raw.push_body != null ? String(raw.push_body) : null,
    pushRoute: raw.pushRoute != null ? String(raw.pushRoute) : raw.push_route != null ? String(raw.push_route) : null,
    isActive: raw.isActive !== undefined ? Boolean(raw.isActive) : raw.is_active !== undefined ? Boolean(Number(raw.is_active)) : true,
    createdAt: raw.createdAt != null ? String(raw.createdAt) : raw.created_at != null ? String(raw.created_at) : undefined,
    updatedAt: raw.updatedAt != null ? String(raw.updatedAt) : raw.updated_at != null ? String(raw.updated_at) : undefined,
  };
}

function normalizeSettings(raw: Record<string, unknown>): NotificationSettings {
  return {
    adminEmail: String(raw.adminEmail ?? raw.admin_email ?? ''),
    fromEmail: String(raw.fromEmail ?? raw.from_email ?? ''),
    fromName: String(raw.fromName ?? raw.from_name ?? ''),
    adminPanelUrl: String(raw.adminPanelUrl ?? raw.admin_panel_url ?? ''),
    emailEnabled: raw.emailEnabled !== undefined ? Boolean(raw.emailEnabled) : raw.email_enabled === '1' || raw.email_enabled === 1 || raw.email_enabled === true,
    pushEnabled: raw.pushEnabled !== undefined ? Boolean(raw.pushEnabled) : raw.push_enabled === '1' || raw.push_enabled === 1 || raw.push_enabled === true,
  };
}

export const notificationTemplatesApi = {
  getAll: async (): Promise<{ templates: NotificationTemplate[]; settings: NotificationSettings }> => {
    const response = await apiClient.get<ApiResponse<{ templates: unknown[]; settings: Record<string, unknown> }>>(
      API_ENDPOINTS.NOTIFICATION_TEMPLATES
    );
    const data = response.data?.data ?? { templates: [], settings: {} };
    const templates = Array.isArray(data.templates) ? data.templates : [];
    return {
      templates: templates.map((item) => normalizeTemplate(item as Record<string, unknown>)),
      settings: normalizeSettings((data.settings ?? {}) as Record<string, unknown>),
    };
  },

  getById: async (id: number): Promise<NotificationTemplate> => {
    const response = await apiClient.get<ApiResponse<{ template: Record<string, unknown> }>>(
      `${API_ENDPOINTS.NOTIFICATION_TEMPLATES}?id=${id}`
    );
    const template = response.data?.data?.template;
    if (!template) throw new Error('Template not found');
    return normalizeTemplate(template);
  },

  updateTemplate: async (payload: NotificationTemplateFormPayload): Promise<NotificationTemplate> => {
    const response = await apiClient.put<ApiResponse<{ template: Record<string, unknown> }>>(
      API_ENDPOINTS.NOTIFICATION_TEMPLATES,
      payload
    );
    const template = response.data?.data?.template;
    if (!template) throw new Error('Update failed');
    return normalizeTemplate(template);
  },

  updateSettings: async (payload: NotificationSettingsPayload): Promise<NotificationSettings> => {
    const response = await apiClient.put<ApiResponse<{ settings: Record<string, unknown> }>>(
      `${API_ENDPOINTS.NOTIFICATION_TEMPLATES}?settings=1`,
      payload
    );
    return normalizeSettings((response.data?.data?.settings ?? {}) as Record<string, unknown>);
  },
};

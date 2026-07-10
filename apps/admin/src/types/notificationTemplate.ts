export type NotificationAudience = 'ADMIN' | 'CLIENT' | 'PROFESSIONAL';
export type NotificationChannel = 'EMAIL' | 'PUSH' | 'BOTH';

export interface NotificationTemplate {
  id: number;
  eventKey: string;
  audience: NotificationAudience;
  channel: NotificationChannel;
  emailSubject: string | null;
  emailBodyHtml: string | null;
  emailBodyText: string | null;
  pushTitle: string | null;
  pushBody: string | null;
  pushRoute: string | null;
  isActive: boolean;
  createdAt?: string;
  updatedAt?: string;
}

export interface NotificationSettings {
  adminEmail: string;
  fromEmail: string;
  fromName: string;
  adminPanelUrl: string;
  emailEnabled: boolean;
  pushEnabled: boolean;
}

export interface NotificationTemplateFormPayload {
  id: number;
  channel?: NotificationChannel;
  emailSubject?: string | null;
  emailBodyHtml?: string | null;
  emailBodyText?: string | null;
  pushTitle?: string | null;
  pushBody?: string | null;
  pushRoute?: string | null;
  isActive?: boolean;
}

export interface NotificationSettingsPayload {
  adminEmail?: string;
  fromEmail?: string;
  fromName?: string;
  adminPanelUrl?: string;
  emailEnabled?: boolean;
  pushEnabled?: boolean;
}

export const NOTIFICATION_PLACEHOLDERS = [
  '{{clientName}}',
  '{{email}}',
  '{{mobile}}',
  '{{pan}}',
  '{{financialYear}}',
  '{{packageName}}',
  '{{amount}}',
  '{{orderId}}',
  '{{itrId}}',
  '{{expertName}}',
  '{{expertEmail}}',
  '{{documentCount}}',
  '{{adminPanelUrl}}',
  '{{statusStep}}',
  '{{statusStepTitle}}',
  '{{statusNotes}}',
  '{{statusLabel}}',
  '{{statusComment}}',
  '{{concernText}}',
] as const;

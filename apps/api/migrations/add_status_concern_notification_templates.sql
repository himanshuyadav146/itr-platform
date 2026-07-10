-- Additional notification templates: status updates + concern raised
-- Run after add_transactional_notification_system.sql

USE `itr_services`;

INSERT INTO `notification_templates`
  (`event_key`, `audience`, `channel`, `email_subject`, `email_body_html`, `email_body_text`, `push_title`, `push_body`, `push_route`, `is_active`)
VALUES
  ('status.step_updated', 'CLIENT', 'BOTH',
   'ITR progress update — {{statusStepTitle}}',
   '<p>Hi {{clientName}},</p><p>Your ITR filing step <b>{{statusStepTitle}}</b> has been marked complete.</p><p>{{statusNotes}}</p>',
   'Your ITR step {{statusStepTitle}} was marked complete. {{statusNotes}}',
   'Progress update', '{{statusStepTitle}} is complete.', '/status', 1),

  ('status.step_updated', 'ADMIN', 'EMAIL',
   'Step completed — {{statusStepTitle}} (PAN {{pan}})',
   '<p>Client <b>{{clientName}}</b> — step <b>{{statusStepTitle}}</b> marked complete.</p><ul><li><b>PAN:</b> {{pan}}</li><li><b>Order:</b> {{orderId}}</li><li><b>Notes:</b> {{statusNotes}}</li></ul>',
   'Step {{statusStepTitle}} completed for {{clientName}} (PAN {{pan}})',
   NULL, NULL, NULL, 1),

  ('status.updated', 'CLIENT', 'BOTH',
   'ITR status update — {{statusLabel}}',
   '<p>Hi {{clientName}},</p><p>Your ITR status was updated to <b>{{statusLabel}}</b>.</p><p><b>Message:</b> {{statusComment}}</p>',
   'Your ITR status is now {{statusLabel}}. Message: {{statusComment}}',
   'Status updated', 'Your ITR status is now {{statusLabel}}.', '/status', 1),

  ('status.updated', 'ADMIN', 'EMAIL',
   'ITR status changed — {{statusLabel}} (PAN {{pan}})',
   '<p>ITR <b>{{itrId}}</b> for <b>{{clientName}}</b> updated to <b>{{statusLabel}}</b> by {{expertName}}.</p><p>{{statusComment}}</p>',
   'ITR {{itrId}} status {{statusLabel}} for {{clientName}}',
   NULL, NULL, NULL, 1),

  ('concern.raised', 'ADMIN', 'EMAIL',
   'New concern — {{statusStepTitle}} (PAN {{pan}})',
   '<p>Client <b>{{clientName}}</b> raised a concern on step <b>{{statusStepTitle}}</b>.</p><p><b>Message:</b> {{concernText}}</p><p><a href="{{adminPanelUrl}}">Open admin panel</a></p>',
   'Concern raised by {{clientName}} on {{statusStepTitle}}: {{concernText}}',
   NULL, NULL, NULL, 1),

  ('concern.raised', 'PROFESSIONAL', 'BOTH',
   'Client concern — {{statusStepTitle}}',
   '<p>Hi {{expertName}},</p><p>Client <b>{{clientName}}</b> (PAN <b>{{pan}}</b>) raised a concern on <b>{{statusStepTitle}}</b>:</p><p>{{concernText}}</p>',
   'Client {{clientName}} raised a concern on {{statusStepTitle}}: {{concernText}}',
   'New concern', '{{clientName}} raised a concern on {{statusStepTitle}}.', '/itrs', 1),

  ('concern.raised', 'CLIENT', 'PUSH',
   NULL, NULL, NULL,
   'Concern received', 'We received your concern on {{statusStepTitle}}.', '/status', 1)

ON DUPLICATE KEY UPDATE
  `channel` = VALUES(`channel`),
  `email_subject` = VALUES(`email_subject`),
  `email_body_html` = VALUES(`email_body_html`),
  `email_body_text` = VALUES(`email_body_text`),
  `push_title` = VALUES(`push_title`),
  `push_body` = VALUES(`push_body`),
  `push_route` = VALUES(`push_route`),
  `is_active` = VALUES(`is_active`);

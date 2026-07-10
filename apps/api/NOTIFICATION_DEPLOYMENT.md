# Email & Push Notification — Server Deployment Guide

This guide deploys the **transactional notification system** without breaking existing APIs.

## What was added

- **Email:** SMTP via `include/EmailService.php` (free Gmail/Zoho SMTP)
- **Push:** Existing `FcmHelper.php` (Firebase FCM — free)
- **Orchestrator:** `include/NotificationDispatcher.php` + DB templates
- **Events wired:** signup, personal info, documents, payment, expert assignment

Existing endpoints keep the same request/response format. Notifications run **after** success and **never block** the API if email/push fails.

---

## Step 1 — Backup (required)

```bash
# On server — backup database
mysqldump -u USER -p itr_services > backup_$(date +%Y%m%d).sql

# Backup API folder
cp -r /path/to/public_html/api /path/to/api_backup_$(date +%Y%m%d)
```

---

## Step 2 — Upload new/changed API files

Upload these files to your server (`allindiaitr.in` API root):

```
include/EmailService.php
include/NotificationDispatcher.php
include/notification_config.php.example
migrations/add_transactional_notification_system.sql
tests/test_notification_system.php
auth/signup.php
itrdetails/personal_details.php
itrdetails/save_documents.php
admin/assign_itr.php
payment/verify_payment.php
payment/webhook.php
admin/notification_templates.php
admin/update_status_step.php
itr_status/raise_concern.php
admin/itrs.php
```

Also upload the **admin dashboard** build (see Step 7b below).

---

## Step 3 — Run database migrations

In phpMyAdmin or MySQL CLI:

```sql
SOURCE /path/to/api/migrations/add_transactional_notification_system.sql;
SOURCE /path/to/api/migrations/add_status_concern_notification_templates.sql;
```

Or import `add_transactional_notification_system.sql` via cPanel → phpMyAdmin.

This creates:

- `notification_settings` (admin email, toggles)
- `notification_templates` (editable email/push copy)
- `notification_delivery_log` (audit trail)

---

## Step 4 — Configure SMTP (free: Gmail App Password)

```bash
cd /path/to/api/include
cp notification_config.php.example notification_config.php
nano notification_config.php
```

Example for Gmail:

```php
$notification_email_enabled = true;
$notification_smtp_host = 'smtp.gmail.com';
$notification_smtp_port = 587;
$notification_smtp_secure = 'tls';
$notification_smtp_username = 'finnextgen2026@gmail.com';
$notification_smtp_password = 'YOUR_16_CHAR_APP_PASSWORD';
$notification_from_email = 'finnextgen2026@gmail.com';
$notification_from_name = 'FinApp';
$notification_admin_email = 'finnextgen2026@gmail.com';
```

**Gmail setup:**

1. Google Account → Security → 2-Step Verification ON
2. App passwords → create “Mail” → copy 16-character password
3. Paste into `notification_smtp_password`

---

## Step 5 — Configure Firebase push (if not already done)

```bash
cp include/firebase_config.php.example include/firebase_config.php
# Upload Firebase service account JSON (from Firebase Console)
# Set path in firebase_config.php
```

Verify `user_fcm_tokens` table exists (from earlier push migration).

---

## Step 6 — Test on server

```bash
cd /path/to/api
php tests/test_notification_system.php --check
php tests/test_notification_system.php --send-test-email finnextgen2026@gmail.com
php tests/test_notification_system.php --dry-run client.registered
```

Optional full dispatch test (writes to log; may send real email if SMTP works):

```bash
php tests/test_notification_system.php --dispatch-test client.registered
```

Check delivery log:

```sql
SELECT * FROM notification_delivery_log ORDER BY id DESC LIMIT 20;
```

---

## Step 7 — Deploy mobile app update

The mobile update re-registers FCM on app start and token refresh.

1. Build release: `flutter build appbundle --release`
2. Upload to Play Console (increment versionCode)
3. Users must open app once while logged in to refresh FCM registration

---

## Step 7b — Deploy admin dashboard (Notification Templates UI)

From `apps/admin`:

```bash
npm install
npm run build
```

Upload the `dist/` folder to your server admin path (e.g. `/admin/` on `allindiaitr.in`).

After deploy, log in as **ADMIN** → sidebar **Notifications** to edit templates and global settings.

---

## Step 8 — Verify end-to-end

| Action | Expected |
|--------|----------|
| New client signup | Admin email to `finnextgen2026@gmail.com` + client welcome push |
| Submit personal info | Admin + client notified |
| Submit documents | Admin + client notified |
| Payment success | Admin + client notified |
| Admin assigns expert | Admin + client + professional emails |
| Status step completed | Client + admin notified |
| ITR status updated (admin panel) | Client + admin notified |
| Client raises concern | Admin + professional + client push |

Check failures in:

```sql
SELECT * FROM notification_delivery_log WHERE status = 'failed' ORDER BY id DESC;
```

---

## Editing templates (no code deploy)

**Preferred:** Admin panel → **Notifications** → edit template or global settings.

Or update copy directly in database:

```sql
SELECT id, event_key, audience, email_subject, push_title
FROM notification_templates WHERE is_active = 1;

UPDATE notification_templates
SET email_subject = 'Your new subject {{clientName}}',
    email_body_html = '<p>Hi {{clientName}}, ...</p>',
    push_title = 'New title',
    push_body = 'New body'
WHERE event_key = 'client.registered' AND audience = 'CLIENT';
```

**Placeholders:** `{{clientName}}`, `{{email}}`, `{{mobile}}`, `{{pan}}`, `{{financialYear}}`, `{{packageName}}`, `{{amount}}`, `{{orderId}}`, `{{itrId}}`, `{{expertName}}`, `{{expertEmail}}`, `{{documentCount}}`, `{{adminPanelUrl}}`

**Change admin inbox:**

```sql
UPDATE notification_settings SET setting_value = 'finnextgen2026@gmail.com' WHERE setting_key = 'admin_email';
```

**Disable channel temporarily:**

```sql
UPDATE notification_settings SET setting_value = '0' WHERE setting_key = 'email_enabled';
-- or push_enabled
```

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| No admin email | Check SMTP config; run `--send-test-email` |
| `SMTP not configured` in log | Create `notification_config.php` |
| No push to client | User must login; check `user_fcm_tokens` |
| Duplicate payment emails | Idempotency uses `order_id` — should send once |
| API still works but no mail | Expected — notifications are non-blocking |

---

## Security notes

- **Never commit** `notification_config.php` or Firebase JSON to git
- Add to `.gitignore` if not already
- Use Gmail **App Password**, not your main Google password

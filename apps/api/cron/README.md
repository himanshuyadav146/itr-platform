# Cron jobs – scheduled push notifications

This folder contains scripts to send push notifications on a schedule (e.g. 3 times per day for 14 days).

## Prerequisites

- Push notification tables exist (`notifications`, `user_fcm_tokens`) – run `migrations/add_push_notification_tables.sql` if not.
- Firebase/FCM is configured: `include/firebase_config.php` and service account JSON so that sending works.

## 1. Seed the 14-day campaign (run once)

Inserts 42 rows into `notifications`: **14 days × 3 times per day** with the FinApp testing reminder.  
Body uses **Day X/14** with X counting down (14, 13, …, 1).

**CLI (recommended):**

```bash
cd /path/to/api
php cron/seed_finapp_14day_campaign.php
```

Start from a specific date:

```bash
php cron/seed_finapp_14day_campaign.php 2026-03-10
```

**Browser (e.g. cPanel):**

- Open: `https://yourdomain.com/api/cron/seed_finapp_14day_campaign.php`
- Optional: `?start=2026-03-10` to set start date

Default start date is **tomorrow**. Notifications are scheduled at **09:00**, **14:00**, and **19:00** server time each day.

## 2. Cron job – send due notifications

The script `send_scheduled_notifications.php` finds all notifications where `scheduled_at <= NOW()` and `sent_at IS NULL`, sends them via FCM to all registered devices, then sets `sent_at`.

**Run it 3 times per day** (same times as the campaign: 9:00, 14:00, 19:00).

### Add to crontab

```bash
crontab -e
```

Add this line (replace `/path/to/api` with your actual API path, e.g. `/home/username/public_html/api`):

```
0 9,14,19 * * * php /path/to/api/cron/send_scheduled_notifications.php
```

Example for cPanel (often path is under `public_html`):

```
0 9,14,19 * * * php /home/cpaneluser/public_html/api/cron/send_scheduled_notifications.php
```

### cPanel Cron Jobs

1. In cPanel → **Cron Jobs**.
2. Add **New Cron Job**.
3. **Minute:** 0 | **Hour:** 9,14,19 | **Day:** * | **Month:** * | **Weekday:** *
4. **Command:**  
   `php /home/youruser/public_html/api/cron/send_scheduled_notifications.php`

## Summary

| Step | Action |
|------|--------|
| 1 | Run `seed_finapp_14day_campaign.php` **once** to create the 42 scheduled notifications. |
| 2 | Add the cron entry so `send_scheduled_notifications.php` runs at **9:00, 14:00, 19:00** every day. |
| 3 | Each run sends every due notification and marks it sent. Over 14 days, users get 3 reminders per day with Day 14/14 → Day 1/14. |

## Files

- **send_scheduled_notifications.php** – run by cron; sends due notifications and updates `sent_at`.
- **seed_finapp_14day_campaign.php** – run once; inserts the 14-day FinApp reminder campaign into `notifications`.

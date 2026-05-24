# ITR Status Update API – CURL & Frontend Guide

Tax professionals (ACCOUNTANT, CA) and Admins can update an ITR’s status and add a **mandatory comment**. The comment is stored for audit and can be used later for **user notifications** and **status API** responses.

---

## Endpoint

- **URL:** `PUT /api/admin/itrs.php`
- **Auth:** Bearer token (ADMIN, ACCOUNTANT, or CA)
- **Body:** JSON with `id` (or `itrId`), `status`, and `comment` (comment is **required**).

---

## Allowed status values

| Status     | Use case |
|-----------|----------|
| `PENDING` | Not yet taken up |
| `ASSIGNED`| Assigned to a professional |
| `REQUIRED`| More info/documents needed (e.g. Form 16 required) |
| `INCORRECT`| Details provided are incorrect |
| `FILED`   | ITR has been filed |
| `COMPLETED`| Process completed |

---

## 1. Update status to REQUIRED (e.g. “Form 16 required”)

```bash
curl -X PUT 'https://allindiaitr.in/api/admin/itrs.php' \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer YOUR_JWT_TOKEN' \
  -d '{
    "id": 10,
    "status": "REQUIRED",
    "comment": "Form 16 required"
  }'
```

**Success (200):**
```json
{
  "status": "success",
  "statusCode": 200,
  "data": {
    "message": "ITR status updated successfully",
    "itrId": 10,
    "status": "REQUIRED",
    "comment": "Form 16 required"
  }
}
```

---

## 2. Using `itrId` instead of `id`

Same request; both keys are supported:

```bash
curl -X PUT 'https://allindiaitr.in/api/admin/itrs.php' \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer YOUR_JWT_TOKEN' \
  -d '{
    "itrId": 10,
    "status": "REQUIRED",
    "comment": "Form 16 required"
  }'
```

---

## 3. Other status updates (INCORRECT, FILED, COMPLETED)

**INCORRECT:**
```bash
curl -X PUT 'https://allindiaitr.in/api/admin/itrs.php' \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer YOUR_JWT_TOKEN' \
  -d '{"id": 10, "status": "INCORRECT", "comment": "PAN name mismatch in Form 16"}'
```

**FILED:**
```bash
curl -X PUT 'https://allindiaitr.in/api/admin/itrs.php' \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer YOUR_JWT_TOKEN' \
  -d '{"id": 10, "status": "FILED", "comment": "ITR filed successfully for AY 2023-24"}'
```

**COMPLETED:**
```bash
curl -X PUT 'https://allindiaitr.in/api/admin/itrs.php' \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer YOUR_JWT_TOKEN' \
  -d '{"id": 10, "status": "COMPLETED", "comment": "Acknowledgement shared with client"}'
```

---

## 4. Error responses

**Missing comment (400):**
```bash
curl -X PUT 'https://allindiaitr.in/api/admin/itrs.php' \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer YOUR_JWT_TOKEN' \
  -d '{"id": 10, "status": "REQUIRED"}'
```
```json
{
  "status": "error",
  "statusCode": 400,
  "data": { "message": "comment is required when updating ITR status" }
}
```

**Missing id/itrId (400):**
```json
{ "status": "error", "statusCode": 400, "data": { "message": "id or itrId is required" } }
```

**Invalid status (400):**
```json
{
  "status": "error",
  "statusCode": 400,
  "data": {
    "message": "Invalid status. Allowed: PENDING, ASSIGNED, REQUIRED, INCORRECT, FILED, COMPLETED",
    "allowedStatuses": ["PENDING", "ASSIGNED", "REQUIRED", "INCORRECT", "FILED", "COMPLETED"]
  }
}
```

**ITR not found (404):**
```json
{ "status": "error", "statusCode": 404, "data": { "message": "ITR not found" } }
```

**Not assigned (403) – ACCOUNTANT/CA only:**
```json
{ "status": "error", "statusCode": 403, "data": { "message": "You are not assigned to this ITR" } }
```

**Wrong role (403):**
```json
{ "status": "error", "statusCode": 403, "data": { "message": "Access denied. Professional or Admin role required." } }
```

---

## 5. Frontend implementation (Edit ITR status)

- **Method:** `PUT`
- **URL:** `https://allindiaitr.in/api/admin/itrs.php` (or your base API URL + `/admin/itrs.php`)
- **Headers:** `Content-Type: application/json`, `Authorization: Bearer <token>`
- **Body:** Always send `id` (or `itrId`), `status`, and `comment`. Treat **comment as mandatory** in the UI (e.g. disable “Save” until comment is non-empty for non-COMPLETED status if you enforce that).

Example payload when user selects status “REQUIRED” and types “Form 16 required”:

```json
{
  "id": 10,
  "status": "REQUIRED",
  "comment": "Form 16 required"
}
```

Use the same shape for other statuses (INCORRECT, FILED, COMPLETED, etc.).

---

## 6. Notifications and status API (future use)

- **Status:** Stored in `itr_detail.status` (PENDING, ASSIGNED, REQUIRED, INCORRECT, FILED, COMPLETED). Your **status API** can expose this field as-is.
- **Comment:** Stored in `itr_order_concerns` with:
  - `concern_type = 'status_update'`
  - `concern_text = comment`
  - `itr_id`, `user_id` (client), `resolved_by` (professional who updated), `resolved_at`, `status = 'resolved'`

For **notifications**, you can:
- Query `itr_order_concerns` for `concern_type = 'status_update'` and `itr_id` (and optionally `user_id` for the client) to get the latest status-update comment and timestamp.
- Use `itr_detail.status` to show short status in lists and in a **status API** response.

---

## 7. Quick reference

| Item        | Value |
|------------|--------|
| Method     | `PUT` |
| Endpoint   | `/api/admin/itrs.php` |
| Auth       | Bearer token (ADMIN, ACCOUNTANT, CA) |
| Body       | `id` or `itrId`, `status`, `comment` (all required) |
| Statuses   | PENDING, ASSIGNED, REQUIRED, INCORRECT, FILED, COMPLETED |

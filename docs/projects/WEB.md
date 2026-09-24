# Website Reference — FinApp (itr_web)

Project-specific reference for `apps/itr_web/FINAPP`. For cross-app docs see [../README.md](../README.md).

---

## Overview

| Property | Value |
|----------|-------|
| **Path** | `apps/itr_web/FINAPP` |
| **Stack** | React, Vite 7, Tailwind 4, Redux Toolkit |
| **Production** | `https://allindiaitr.in` |
| **API** | `https://allindiaitr.in/api` (dev Vite proxy `/api`) |

---

## Associate marketplace

Clients pick a **service**, then a **listed associate**, then pay that associate’s fee + GST. Associates register on the website and work in admin.

| Route | Screen | APIs |
|-------|--------|------|
| `/associate-register` | Associate register | `POST /auth/register_associate.php` then redirect to `/admin/login?registered=1` |
| `/services` | Service catalog | `GET /associates/services.php` |
| `/associates` | Associate list | `GET /associates/list.php?serviceId=` |
| `/associates/:id` | Associate detail + Select | `GET /associates/detail.php?id=` |
| `/personal-details` | Personal details | `POST /itrdetails/add_personal_details.php` (`associateId`, `serviceId`) |
| `/documents` | Documents | existing document APIs |
| `/payment` | Pay associate fee | `GET /payment/get_payment_info.php`, `POST /payment/initiate_payment.php`, `verify_payment.php` |

Home “Start Filing” and dashboard “File New ITR” go to `/services`, not `/packages`. `/packages` remains as a legacy route.

Selection is stored in Redux + `localStorage.selectedAssociate` (`id`, `serviceId`, `quotedFee`). Payment uses the server-side listed fee; `quoted_fee` is snapshotted on initiate. Successful verify creates `itr_assignments.assigned_to` for that associate.

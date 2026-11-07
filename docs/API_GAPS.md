# Allo Coursier — Mobile API gaps

Base URL used by the Flutter app:

`https://allo-coursier.vercel.app/api/mobile`

Override locally:

`flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/mobile`

Envelope:

```json
{ "success": true, "data": {} }
{ "success": false, "error": { "code": "unauthorized", "message": "..." } }
```

IDs are numeric strings (`"83678"`). Display `HT${id}`. Page size 25 (max 50). Flutter never talks to Odoo.

Compared against local backend `C:\Users\moham\OneDrive\Desktop\alloCoursier\src\app\api\mobile` (2026-10-20). **Exists** = HTTP 400 / 401 / 403 / 405. **Missing** = 404.

## Implemented and confirmed

| Method | Path | Flutter | Screen |
|--------|------|---------|--------|
| POST | `/auth/login` | `AlloApi.login` (`email` field holds staff email **or** expéditeur name) | Login Identifiant |
| GET | `/auth/me` | `AuthApiService.getCurrentUser` | Startup + profile |
| POST | `/auth/password` | `{ currentPassword, newPassword }` | Profile |
| POST | `/auth/logout` | `AlloApi.logout` | Profile |
| GET | `/commandes?page&pageSize&shipment&search` | `listCommandesPage` `{ rows, total }` | Agent / livreur lists |
| GET | `/commandes/:id` | `getCommande` (403 → forbidden message) | Details |
| POST | `/commandes` | `createCommande` | Add order |
| PATCH | `/commandes/:id` | `{ status: "En dépôt" }` retour dépôt | Admin details |
| DELETE | `/commandes/:id` | `deleteCommande` | Admin details |
| GET | `/users/:id/colis?page&pageSize&search` | `{ rows, total, sum }` | Sender orders |
| GET | `/colis-du-jour` | `listColisDuJour` | Circuit / vehicle |
| POST | `/commandes/:id/confirm-colis` | `{ deliveryDate, vehicleId }` | Agent colis confirm |
| POST | `/commandes/:id/claim` | empty body | Livreur scanner |
| POST | `/commandes/:id/deliver` | `deliver` | Livreur scanner |
| POST | `/commandes/:id/annuler` | `{ reason }` | Livreur scanner |
| POST | `/commandes/:id/relivrer` | livreur `{ reason }` / admin `{ deliveryDate, vehicleId? }` | Scanner + details |
| POST | `/commandes/:id/pay` | admin, Livrer unpaid | Admin details |
| POST | `/scanner/lookup` | `{ id }` → `{ found, order }` | Unified scanner |
| GET | `/dashboard` | counts Tous/En cours/En dépôt/En route/Livré/Payé/Relivrer/Annuler + `totals.expediteurs/livreurs/vehicles` + `insights.weekDeliveries` | Agent dashboard |
| GET | `/users?role=` | `listUsers(role:)` | Users list |
| GET | `/users/:id` | `getUser` | User details |
| POST | `/users` | `createUser` | Create account (admin only) |
| DELETE | `/users/:id` | `deleteUser` | Service ready |
| GET | `/vehicles` | `listVehicles` | Vehicles list |
| GET | `/vehicles/:id` | `getVehicle` | Vehicle details |
| POST | `/vehicles` | `{ matricule, model }` | Vehicles list (admin) |
| POST | `/vehicles/:id/assign` | `{ livreurId }` | Vehicle details (admin) |
| PATCH | `/vehicles/:id` | `updateVehicle` | Fallback |
| DELETE | `/vehicles/:id` | `deleteVehicle` | Service ready |
| POST | `/payments/confirm` | `{ orderIds }` of **visible** rows; show credits/penalties | Payments |
| POST | `/payments/withdraw` | `{ expediteurId }` only (409 shows `error.message`) | User details |
| GET | `/notifications` | `listNotifications` | Notifications |
| POST | `/notifications/:id/read` | `markRead` | Tap |
| DELETE | `/notifications/:id` | swipe | Notifications |
| POST | `/push-tokens` | `{ token, platform }` | After login if token set (no FCM SDK) |
| GET | `/tarifs` | `TarifApiService` | Client dashboard |
| GET | `/transactions` | `{ value: [] }` ok | Client transactions |

## Present on server, not used by Flutter (intentional)

| Method | Path | Why skipped |
|--------|------|-------------|
| POST | `/commandes/:id/confirm` | Web-only fast path **En cours → En route**. Mobile uses `/confirm-colis` (En cours → En dépôt with vehicle + date). Do not call this from Flutter. |

## Missing on server (404) — do not invent

| Method | Path | Notes |
|--------|------|--------|
| GET | `/payments` | No list-payments endpoint |
| POST | `/reclamations` | No public reclamation inbox |
| POST | `/auth/forgot-password` | No self-serve password reset |
| GET | `/commandes/:id/history` | No timeline API |
| POST | `/commandes/:id/return-depot` | Use PATCH `{ "status": "En dépôt" }` |
| POST | `/commandes/:id/return-sender` | Not in this contract |
| GET | `/commandes` livreur-scoped | List is global; app pages 25–50 then filters `livreur_id` |

Forgot password in the app therefore sends an **office reclamation** by email (`mailto:allocoursierzaghouan@gmail.com`).

Print stays on the website; the app keeps local PDF from `CommandeModel.toPdfMap()` only.

## Exists but different from a naive spec

| Spec assumption | Live / app behavior |
|-----------------|---------------------|
| `PATCH /auth/password` | **405** — uses **POST** camelCase |
| `GET /scanner/lookup` | **405** — uses **POST** `{ id }` |
| `PATCH /notifications/:id` | **405** — uses **POST** `/notifications/:id/read` |
| `PATCH /users/:id` | **405** — no user edit |
| Login must be an email | Staff email **or** expéditeur name (`mouna mbarek`) |
| `Livré` / `Payé` shipment | `Livré` = Livrer unpaid; `Payé` = Livrer paid |
| Agent creates users / vehicles | Agent is read-only for those writes |

## Dashboard fallback

If `GET /dashboard` fails, the agent screen composes **only** `GET /users?role=` and `GET /vehicles`. It never loads the full commandes list.

## Auth / errors

- Login 400 without body; 401/`invalid_credentials` for bad password
- Rate limit: `code = rate_limited` (429)
- 409/`conflict` → show `error.message` (transition refusée)
- Withdraw 409 → show `error.message`
- Livreur `GET /commandes/:id` may 403 if not assigned
- Password body keys: `currentPassword`, `newPassword`

## Section 11 (non-blocking)

- Notifications may return an empty list
- Transactions may return an empty list
- Withdraw may return 409 if the feature is inactive
- Push tokens `{ ok: true }` — no-op when no device token
- No server PDF endpoint

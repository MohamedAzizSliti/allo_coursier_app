# Allo Coursier Zaghouan — Web App Full Specification

> **Document for Web Developer** — Every Screen, Every Feature, Every Detail  
> Project: Allo Coursier Zaghouan • Backend: Supabase • Region: Tunisia  
> Generated from 40 Dart source files

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [URL Structure & Access Control](#2-url-structure--access-control)
3. [Landing Page](#3-landing-page)
4. [Design System](#4-design-system)
5. [Expéditeur (Business Client) Portal](#5-expéditeur-business-client-portal)
6. [Admin / Agent Panel](#6-admin--agent-panel)
7. [Livreur (Delivery Person) Panel](#7-livreur-delivery-person-panel)
8. [Shared Components](#8-shared-components)
9. [Order Status Flow](#9-order-status-flow)
10. [Notification System](#10-notification-system)
11. [PDF Generation](#11-pdf-generation)
12. [Database Schema (Supabase PostgreSQL)](#12-database-schema-supabase-postgresql)
13. [Tech Stack & Libraries](#13-tech-stack--libraries)
14. [Supabase Edge Functions](#14-supabase-edge-functions)
15. [Environment Variables & Security](#15-environment-variables--security)
16. [Deployment](#16-deployment)

---

## 1. Project Overview

**Allo Coursier** is a multi-role courier/delivery management platform for Zaghouan, Tunisia. The system manages the full lifecycle of parcel delivery from business clients (expéditeurs) to end customers via delivery persons (livreurs), with admin/agent oversight.

### User Roles

| Role | French Title | Description |
|------|-------------|-------------|
| `admin` | Administrateur | Full access: manage users, orders, vehicles, payments, agents |
| `agent` | Agent | Same as admin but NO sidebar drawer (no agent management, no payments) |
| `business_client` | Expéditeur | Create orders, track own orders, view transactions and tarifs |
| `delivery_person` | Livreur | View daily assigned orders, scan QR to update status, track earnings |

### Core Features

- Multi-role authentication with role-based dashboards
- Order lifecycle management (create → depot → en route → delivered/cancelled)
- QR code scanning for order processing (different behavior per role)
- Real-time data updates via Supabase Realtime
- Push notifications on every status change
- PDF generation (single order with QR + delivery route circuit)
- COD payment collection and balance management
- Vehicle and livreur assignment system
- Transaction tracking and financial reporting

---

## 2. URL Structure & Access Control

### ⚠️ CRITICAL: Secret URLs

**Only the Expéditeur login is publicly accessible from the landing page.**  
Admin/Agent and Livreur portals use **secret URLs** that are **NOT linked anywhere** on the public site. These URLs are shared privately with authorized personnel only.

### Public URLs

| URL | Page | Description |
|-----|------|-------------|
| `/` | Landing Page | Marketing page with logo, services, pricing, and "Espace Client" button |
| `/login` | Expéditeur Login | Email + password login **ONLY** for `business_client` role |

### Secret URLs (NOT linked on public site)

| URL | Page | Allowed Roles | How They Get the URL |
|-----|------|---------------|---------------------|
| `/admin-portal/login` | Admin / Agent Login | `admin`, `agent` | Shared privately by company owner |
| `/livreur-portal/login` | Livreur Login | `delivery_person` | Shared privately by admin |

### Expéditeur Dashboard Routes (`business_client`)

| URL | Page | Bottom Nav Tab |
|-----|------|---------------|
| `/dashboard` | Home (Stats + Rules + Tarifs) | Tab 1: Accueil |
| `/dashboard/orders` | My Orders List | Tab 2: Commandes |
| `/dashboard/add-order` | Create New Order | Tab 3: Ajouter |
| `/dashboard/transactions` | My Transactions | Tab 4: Transactions |
| `/dashboard/notifications` | Notifications | Tab 5: Notifications |
| `/dashboard/orders/:id` | Order Details | Sub-screen |
| `/dashboard/profile` | Profile | AppBar icon |

### Admin/Agent Portal Routes

| URL | Page | Admin Only? |
|-----|------|-------------|
| `/admin-portal/dashboard` | Stats Dashboard | No |
| `/admin-portal/delivery-circuit` | Delivery Circuit Generator | No |
| `/admin-portal/commandes` | All Orders (all dates, stream) | No |
| `/admin-portal/commandes/today` | Today's Orders (deliveryDate ≥ today) | No |
| `/admin-portal/commandes/:id` | Order Details (expandable sections) | No |
| `/admin-portal/commandes/:id/colis` | Colis Confirmation (assign vehicle+date) | No |
| `/admin-portal/notifications` | Notifications | No |
| `/admin-portal/users?role=agent` | Agent List | **YES** (admin drawer) |
| `/admin-portal/users?role=business_client` | Expéditeur List | No (dashboard link) |
| `/admin-portal/users?role=delivery_person` | Livreur List | No (dashboard link) |
| `/admin-portal/users/create?role=X` | Create Account | Depends on role |
| `/admin-portal/users/:id` | User Details + Balance + Withdraw | No |
| `/admin-portal/vehicles` | Vehicle List (CRUD) | No (dashboard link) |
| `/admin-portal/vehicles/:id` | Vehicle Details + Assign Livreur | No |
| `/admin-portal/payments` | Payment Collection | **YES** (admin drawer) |
| `/admin-portal/scan` | QR Scanner | No (floating button) |
| `/admin-portal/profile` | Profile | No |

### Livreur Portal Routes

| URL | Page |
|-----|------|
| `/livreur-portal/dashboard` | Daily Stats + Earnings + Grid Cards |
| `/livreur-portal/orders?status=X` | Filtered Order List (today only) |
| `/livreur-portal/scan` | QR Scanner with Status Dialog |
| `/livreur-portal/profile` | Profile |

### Auth Redirect Rules

1. **Unauthenticated** user on any protected route → redirect to the matching portal login
2. **Authenticated** user on wrong portal (e.g. livreur tries `/admin-portal`) → show "Accès refusé" → redirect to correct dashboard
3. Each login page **checks the role** and **rejects** if role doesn't match that portal

---

## 3. Landing Page

**URL:** `/` — Public, no authentication required

### Section 1 — Navigation Bar

- **Left:** Logo image (`assets/images/logo.png`) + "Allo Coursier" text
- **Right:** Single button "Espace Client" (tan `#D2B48C`) → navigates to `/login`
- **⚠️ NO links to admin or livreur portals anywhere on this page**

### Section 2 — Hero Section

- Large centered logo (300×300, scale for web)
- Company name: **"Allo Coursier Zaghouan"**
- Tagline in French: *"Votre partenaire de livraison de confiance à Zaghouan"*
- Tagline in Arabic: *"شريكك الموثوق في التوصيل بزغوان"*
- CTA Button: **"Commencez à expédier"** → `/login`

### Section 3 — Services (3 cards in a row)

| Card | Icon | Title | Description |
|------|------|-------|-------------|
| 1 | Package | Envoyez vos colis | Créez vos commandes en ligne facilement |
| 2 | Truck | Suivi en temps réel | Suivez vos colis à chaque étape |
| 3 | Shield | Paiement sécurisé | Gérez vos transactions en toute sécurité |

### Section 4 — Delivery Zones & Pricing

| Zone | Gouvernorats | Fee |
|------|-------------|-----|
| Zone 1 (Proche) | Tunis, Nabeul, Bizerte, Sousse, Monastir, Ariana, Ben Arous, Manouba, Zaghouan | **7 DT** |
| Zone 2 (Moyen) | Beja, Le Kef, Siliana, Sfax, Jendouba, Mahdia | **8 DT** |
| Zone 3 (Loin) | Kairouan, Kasserine, Medenine, Tataouine, Kébili, Tozeur, Gafsa, Gabes, Sidi Bouzid | **9 DT** |

> **Note:** If total weight exceeds 10 kg, fee = 1 DT per kg instead.

### Section 5 — Footer

- Company info, phone number, address in Zaghouan
- Social media links
- "Espace Client" link → `/login`
- **NO links to admin or livreur portals**

---

## 4. Design System

| Token | Value |
|-------|-------|
| Background Primary | `#F5F5DC` (Beige) |
| Background Secondary | `#F5F1E7` (Cream) |
| AppBar / Primary Brown | `#6D4C41` |
| CTA / Buttons Tan | `#D2B48C` |
| Input Field Fill | `#EDE0C8` |
| Livreur Brown (darker) | `#8B4513` |
| Text on beige | Brown `#6D4C41` |
| Text on brown | White |
| Border Radius | 12px (buttons, inputs, cards) |
| Card Elevation | 3–6 (subtle shadow) |
| Card Border Radius | 12px standard, 20px for livreur stat cards |
| Font | Roboto / system sans-serif |
| Responsive Breakpoints | 768px (tablet), 1024px (desktop), 1440px (wide) |

### Status Colors

| Status | Color |
|--------|-------|
| En cours | Orange |
| En dépôt | Blue |
| En route | Purple |
| Livrer | Green |
| Relivrer | Red accent |
| Annuler | Deep orange |

---

## 5. Expéditeur (Business Client) Portal

**Access:** Landing Page → "Espace Client" button → `/login`

### 5.1 Login Screen — `/login`

**Layout:**
- Centered card on beige (`#F5F5DC`) background
- Logo at top (300×300)
- Title: "Bienvenue !" (brown, bold, 28px)

**Fields:**
1. **Email** — email icon prefix, beige fill `#EDE0C8`, radius 12px
2. **Password** — lock icon prefix, eye toggle show/hide, same styling

**Button:** "Se connecter" — full width, tan `#D2B48C`, white text, bold 18px, radius 12px, loading spinner when pressed

**Validation:**
- Email: required
- Password: minimum 6 characters

**On Success:**
- Fetch user role from Supabase
- **ONLY allow** `business_client` role
- Any other role → show error: "Accès refusé pour ce portail"

**Errors:** "Email ou mot de passe incorrect" (red toast at bottom)

### 5.2 Dashboard Shell

- **AppBar:** Title changes per tab + Profile icon (top right) → `/dashboard/profile`
- **Bottom Navigation:** 5 tabs (Accueil, Commandes, Ajouter, Transactions, Notifications)

### 5.3 Tab 1: Dashboard Home — `/dashboard`

**AppBar title:** "Tableau de Bord Expéditeur"

#### Section 1 — Rules Card (Arabic, right-aligned)

Title: "القواعد الجديدة" (New Rules)

Items with checkmark icons:
- ✅ يجب أن تكون الطرود مغلفة بشكل جيد (Packages must be well wrapped)
- ✅ يجب تأكيد الدفع قبل الإرسال (Confirm payment before sending)
- ✅ يتم فرض رسوم على المرتجعات حسب حجم الطرد (Returns charged by parcel size)

#### Section 2 — Weekly Plan Widget (Arabic, collapsible)

Title: "📅 خطة الأسبوع" — Click to expand/collapse with animation

| Day | Delivery Zones |
|-----|---------------|
| الاثنين (Monday) | القصرين، سيدي بوزيد، تونس، صفاقس، قيروان، قفصة |
| الثلاثاء (Tuesday) | تونس، الوطن القبلي |
| الأربعاء (Wednesday) | قفصة، توزر، قبلي، تونس، باجة، سليانة |
| الخميس (Thursday) | تونس، سوسة، منستير |
| الجمعة (Friday) | تونس، مهدية، قيروان، قابس، تطاوين، مدنين |
| السبت (Saturday) | تونس، بنزرت |

Each day shows a location pin icon, day name (bold, right-aligned), and zones (right-aligned).

#### Section 3 — Order Statistics (real-time)

**Query:** `commandes` where `expediteur.id = current user`

| Stat Card | Color | Filter |
|-----------|-------|--------|
| Total des Commandes | Brown | count all |
| En Cours | Orange | status = 'En cours' |
| En dépôt | Pink (#FF4081) | status = 'En dépôt' |
| Livré | Green | status = 'Livrer' |
| Relivrer | Blue | status = 'Relivrer' |
| Annulé | Red | status = 'Annuler' |

Each stat card: colored background at 10% opacity, bar chart icon, title, count (bold 20px).

#### Section 4 — Tarifs (from `tarifs` table)

Real-time stream from Supabase. Each tarif card:
- Truck icon (brown)
- Type name (bold)
- "Prix: X DT - Retour: Y DT"

### 5.4 Tab 2: My Orders — `/dashboard/orders`

**AppBar title:** "Mes Commandes"

**Search bar:** Text field "Rechercher par numéro" with search icon, radius 12px  
**Status filter:** Dropdown: Tous, En cours, En dépôt, En route, Livrer, Relivrer, Annuler

**Data:** Real-time stream — `commandes` where `expediteur.id = current user`  
**Client-side filter:** by search query (order ID contains) + selected status

**Each order card** (elevation 3, radius 12):
- **Title:** "Commande #[ID]" (bold)
- **Subtitle:** Client name, Date, Status (colored text)
- **Trailing actions:**
  - View button (blue eye icon) → `/dashboard/orders/:id`
  - Print button (brown printer icon) → PDF generation

**Print action:**
1. Fetch expéditeur full data from `users` table (name, phone)
2. Generate PDF with: logo, QR code of order ID, order details, expéditeur info
3. Open browser print dialog / download PDF

### 5.5 Tab 3: Create Order — `/dashboard/add-order`

**AppBar title:** "Ajouter une Commande"

#### Product Information Section

| Field | Type | Notes |
|-------|------|-------|
| Product name | Text input | Required |
| Fragile | Switch toggle | Default false |
| Peut ouvrir avant de payer | Switch toggle | Default false |
| Colis gratuite pour le client | Switch toggle | If ON → total = 0 |
| Le client paie uniquement les frais de livraison | Switch toggle | If ON → total = delivery fee only |

#### Product Table (dynamic rows)

| Column | Type |
|--------|------|
| Nom du produit | Text |
| Quantité (kg) | Number |
| Prix/Kg | Number |

- Start with 1 empty row
- "Ajouter un produit" button adds new rows
- Total auto-calculated: `sum(quantity × pricePerKilo)` for all rows

#### Pricing Logic (auto-calculated as user types)

```
1. Calculate total_quantity across all products
2. If total_quantity > 10 kg:
     delivery_fee = total_quantity × 1.0 DT
3. Else if gouvernorat in Zone 1 (Tunis, Nabeul, Bizerte, Sousse, Monastir, 
   Ariana, Ben Arous, Manouba, Zaghouan):
     delivery_fee = 7 DT
4. Else if gouvernorat in Zone 2 (Beja, Le Kef, Siliana, Sfax, Jendouba, Mahdia):
     delivery_fee = 8 DT
5. Else (Zone 3):
     delivery_fee = 9 DT
6. If "Colis gratuite" is ON:
     total_price = 0
7. Else if "Client paie livraison seulement" is ON:
     total_price = delivery_fee
8. Else:
     total_price = products_total + delivery_fee
```

Display: "Total Price: X.XX" (bold 18px)

**Delivery fees info link:** "📌 ملاحظة: رسوم التوصيل" (blue, underlined) → opens popup dialog showing zone-based fees in Arabic with 3 fee tiers.

#### Client Information Section

| Field | Type | Notes |
|-------|------|-------|
| Client name | Text | Required |
| Phone number | Phone input | Required |
| Gouvernorat | Dropdown | 24 Tunisian gouvernorats, Required |
| Address | Text | Required |
| City | Text | Required |

**24 Tunisian Gouvernorats (dropdown values):**
Ariana, Beja, Ben Arous, Bizerte, Gabes, Gafsa, Jendouba, Kairouan, Kasserine, Kébili, Le Kef, Mahdia, Manouba, Medenine, Monastir, Nabeul, Sfax, Sidi Bouzid, Siliana, Sousse, Tataouine, Tozeur, Tunis, Zaghouan

#### Submit: "Ajouter la commande"

1. Validate all required fields
2. Fetch current user name from `users` table
3. Create order ID = `Date.now()` (timestamp in milliseconds)
4. Insert into `commandes` with:
   - `status = "En cours"`
   - `paid = false`
   - `date = now()`
   - `livraison = "Pickup"`
5. Send notification to ALL admin + agent users:
   - Title: "Nouvelle Commande"
   - Body: "Une nouvelle commande a été placée!"
6. Show success snackbar: "Commande ajoutée avec succès!"
7. Reset entire form (clear all fields, reset toggles, clear product table)

### 5.6 Order Details — `/dashboard/orders/:id`

**AppBar:** "Détails de la Commande"

**Displays:**
- Commande ID
- Client: nom, adresse, ville, gouvernorat, téléphone
- Product: name, total price, fragile (Oui/Non), open before pay (Oui/Non)
- Product list table: each product with name, price/kg, quantity
- Date, Status

**"Supprimer la commande" button (red):**
- **ONLY visible** when status = `"En cours"` or `"En dépôt"`
- Deletes order from `commandes` table
- Shows success/error snackbar

### 5.7 Tab 4: Transactions — `/dashboard/transactions`

**AppBar title:** "Mes Transactions"

**Data:** Real-time stream — `transactions` where `expediteurId = current user`, ordered by `date DESC`

**Each transaction card** (elevation 3, radius 10):
- **Leading icon:** Red up-arrow for `"retrait"` (withdrawal), Green down-arrow for deposit
- **Title:** "Montant: X.XX DT" (bold)
- **Subtitle:** "Type: retrait" + "Date: dd/MM/yyyy HH:mm"

### 5.8 Tab 5: Notifications — `/dashboard/notifications`

See [Section 8.2 — Notifications Screen](#82-notifications-screen) for full spec.

---

## 6. Admin / Agent Panel

**Secret URL:** `/admin-portal/login` — NOT linked on public site

### ⚠️ admin vs agent Role Difference

Both roles share the same dashboard shell. The key differences:

| Feature | admin | agent |
|---------|-------|-------|
| Sidebar drawer | ✅ Visible | ❌ Hidden |
| Agent management (drawer item) | ✅ | ❌ |
| Payments screen (drawer item) | ✅ | ❌ |
| Create delivery_person accounts | ✅ (FAB visible) | ❌ (FAB hidden) |
| Create expéditeur/agent accounts | ✅ | ✅ |
| All other features | ✅ | ✅ |

### 6.1 Login — `/admin-portal/login`

Same login form design as expéditeur. On success:
- Check role — only allow `admin` or `agent`
- Redirect to `/admin-portal/dashboard`
- If role is NOT admin/agent → show "Accès refusé"

### 6.2 Dashboard Shell

- **AppBar:** Dynamic title per tab + Profile icon → `/admin-portal/profile`
- **Bottom Nav:** 4 tabs (Tableau de Bord, Circuit de livraison, Suivi des Commandes, Notifications)
- **Floating QR Button:** Centered in bottom nav → `/admin-portal/scan`
- **Sidebar Drawer (admin only):** Header "Menu Administrateur" (brown), with menu items:
  1. Tableau de Bord → Tab 1
  2. Gestions des agents → `/admin-portal/users?role=agent`
  3. Paiement → `/admin-portal/payments`

### 6.3 Tab 1: Stats Dashboard — `/admin-portal/dashboard`

**AppBar:** "Tableau de Bord" — Pull-to-refresh supported

#### Section 1 — User Stats (2 clickable cards in a row)

| Card | Count | Icon | Click Action |
|------|-------|------|-------------|
| Expéditeurs | Count of business_client users | group | → `/admin-portal/users?role=business_client` |
| Livreurs | Count of delivery_person users | delivery_dining | → `/admin-portal/users?role=delivery_person` |

#### Section 2 — Resource Stats (2 clickable cards in a row)

| Card | Count | Icon | Click Action |
|------|-------|------|-------------|
| Véhicules | Count of all vehicles | local_shipping | → `/admin-portal/vehicles` |
| Colis | Today's commande count (deliveryDate ≥ today) | inventory | → `/admin-portal/commandes/today` |

#### Section 3 — Order Status Stats (vertical list)

Colored stat cards: Total (brown), En dépôt (orange), Livré (green), Relivrer (blue), Annulé (red)

Each card: colored background at 10% opacity, bar chart icon, title, count (bold 20px).

### 6.4 Tab 2: Delivery Circuit — `/admin-portal/delivery-circuit`

**AppBar:** "Générateur de circuit de livraison"

#### Controls

- **Vehicle dropdown:** Fetched from `vehicles` table, displays `"model - matricule"`, stores vehicle ID
- **Date picker button:** Shows selected date formatted `yyyy-MM-dd` or "Choisissez une date"
- **Total count:** "Commandes totales: X" (bold 18px)

#### Data Query

```sql
SELECT * FROM commandes 
WHERE vehicle_id = :selectedVehicle 
  AND delivery_date >= :startOfDay 
  AND delivery_date < :endOfDay 
ORDER BY client_gouvernorat, client_ville
```

#### Display: Nested Collapsible Groups

- **Level 1:** Gouvernorat name + count → collapsible
  - **Level 2:** Status name + count (colored text) → collapsible inside gouvernorat
    - **Level 3:** Individual orders → click → `/admin-portal/commandes/:id`

Each order shows: "Commande ID: [id]", "Amount: X TND"

#### Bottom Button: "Génération d'un circuit"

Disabled if no orders. On click:

1. Fetch livreur name from `vehicle.livreur` → `users` table
2. Fetch vehicle model + matricule
3. If no livreur assigned → show error: "No livreur found for this vehicle"
4. Generate **landscape** PDF:
   - Logo image
   - Livreur name
   - Vehicle: "model - matricule"
   - Date
   - All orders grouped by gouvernorat/ville
5. Open print preview / download

### 6.5 Tab 3: All Orders — `/admin-portal/commandes`

**AppBar:** "Suivi des Commandes"

**Search bar:** "Rechercher par numéro" (filters by order ID contains)  
**Status dropdown filter:** Tous + all 6 statuses

**Data:** Real-time stream of **ALL** `commandes` (no date filter)

**Each order card** (elevation 3, radius 12):
- **Title:** "Commande #[ID]" (bold)
- **Subtitle:** Client name, Date, Status (colored text)
- **Two action icons:**
  - View (blue eye icon) → `/admin-portal/commandes/:id`
  - Print (brown printer icon) → fetch expéditeur data then generate PDF with QR

### 6.6 Today's Orders — `/admin-portal/commandes/today`

Same as All Orders but with additional filter: `deliveryDate >= startOfToday`

Navigated to from the "Colis" card on the dashboard.

### 6.7 Order Details — `/admin-portal/commandes/:id`

**AppBar:** "Détails de la Commande"

#### 5 Expandable Sections (Card + ExpansionTile)

**1. Client:**
- Nom, Téléphone (**clickable** → `tel:` link on web), Adresse, Ville + Gouvernorat

**2. Livraison:**
- Date de commande (formatted "dd MMMM yyyy, HH:mm")
- Type (Pickup)
- Date de livraison
- Frais de livraison (X TND)

**3. Produit:**
- Nom
- Prix total (X TND)
- Fragile: Oui (red warning icon) / Non (green check icon)
- Ouvrir avant paiement: Oui / Non

**4. Expéditeur (fetched from users table by expediteur.id):**
- Nom, Téléphone (**clickable**), Adresse

**5. Véhicule (only shown if assigned):**
- Vehicle name, Vehicle ID

#### Status Display

Blue bordered box with rounded corners: "Statut: [status]" (bold, blue, 18px)

#### Relivrer Action Button

**ONLY visible when status = "Relivrer"**

Green button: "Relivrer Maintenant"
1. Show date picker for new delivery date
2. Update commande:
   - `deliveryDate = picked date`
   - `status = "En dépôt"`
   - Remove `livreurId` (set to null)
3. Navigate to Colis Confirmation screen (`/admin-portal/commandes/:id/colis`)

### 6.8 Colis Confirmation — `/admin-portal/commandes/:id/colis`

**AppBar:** "Détails du Colis" (brown `#6D4C41`)

**Purpose:** After agent QR scans an "En cours" order, this screen assigns vehicle + delivery date.

#### Displays

- Colis ID
- Client: name, phone, address
- Product: name, price (TND)
- Expéditeur: name

#### Inputs

- **Date picker:** "Sélectionner une date de livraison" (from today to future)
- **Vehicle dropdown:** "Choisissez un véhicule" (shows matricule, stores vehicle ID)

#### "Confirmer" button (green, full width)

1. Validate both fields are filled (show error if not: "Veuillez remplir tous les champs")
2. Update commande:
   - `deliveryDate = selected date`
   - `vehicleId = selected vehicle`
   - `status = "En dépôt"`
3. Send notification to expéditeur:
   - Title: "Livraison Confirmée"
   - Body: "Votre colis a été confirmé et sera livré le dd/MM/yyyy"
4. Show success snackbar: "Colis confirmé avec succès"
5. Navigate back

### 6.9 Agent QR Scanner — `/admin-portal/scan`

**Triggered by:** Floating QR button (center of bottom nav)

**AppBar:** "Scanner le QR Code"

**⚠️ Different behavior from livreur scanner!**

**Scan logic:**
1. Scan QR code → extract order ID
2. Fetch order from `commandes` table
3. Check status:
   - **If "En cours"** → Navigate to Colis Confirmation screen (assign vehicle + date)
   - **If any other status** → Show snackbar: "La commande est actuellement dans l'état : [status]"
   - **If order not found** → "Commande introuvable!"
4. 2-second delay between scans to prevent duplicate processing

**On web:** Use browser camera API with `html5-qrcode` library

### 6.10 User Management — `/admin-portal/users`

**AppBar:** "Liste des [RoleTitle]" (e.g., Expéditeurs, Livreurs, Agents)

**Data:** Real-time stream — `users` filtered by `role` query parameter

**Each user card:**
- Avatar circle (brown background, person icon)
- Name (title), Email (subtitle)
- Arrow icon (trailing)
- Click → `/admin-portal/users/:id`

**FAB (+ icon):**
- For `delivery_person` list: FAB **only visible if current user = admin**
- For other roles: FAB always visible for admin and agent
- Click → `/admin-portal/users/create?role=X`

**Role title mapping:**
- `business_client` → "Expéditeurs"
- `delivery_person` → "Livreurs"
- `agent` → "Agents"

### 6.11 Create Account — `/admin-portal/users/create`

**AppBar:** "Créer un [RoleTitle]" (e.g., Expéditeur, Livreur, Agent)

**Card form** (elevation 5, radius 20, brown theme):

Title: "Inscription" (28px, brown)

| Field | Icon | Type |
|-------|------|------|
| Nom | person | Text |
| Email | email | Email |
| Mot de passe | lock | Password (obscured) |
| Numéro de téléphone | phone | Phone |
| Adresse | location_on | Text |

**Role is pre-set from URL query param** (not shown as a dropdown to the user).

**"Créer le compte" button (brown):**
1. Create Supabase Auth user **via Edge Function** (admin cannot create auth users client-side)
2. Insert `users` row: uid, name, email, phone, address, role, createdAt
3. Show success snackbar: "Compte créé avec succès !"
4. Navigate back

### 6.12 User Details — `/admin-portal/users/:id`

**AppBar:** "Détails de l'utilisateur"

#### Section 1 — User Card

- Person icon (blue), Name (bold 18px), Email, Role badge (green verified icon)
- **"Supprimer le compte" button (red)** — with confirmation dialog:
  - "Êtes-vous sûr de vouloir supprimer ce compte ?"
  - "Annuler" / "Supprimer" buttons
  - On confirm: delete user document, navigate back

#### Section 2 — Financial Stats (business_client only)

- **"Montant Disponible"** (green wallet icon) — from `users.montant_disponible`
- **"Montant Non Disponible"** (red lock icon) — calculated: sum of `prix_total` for orders where `status = "Livrer"` AND (`paid = false` OR `paid = null`)
- **"Retirer Tout" button** — Withdraws full `montant_disponible`:
  1. Create transaction record: `{ agentId, expediteurId, montant, date, type: "retrait" }`
  2. Decrement `users.montant_disponible` by the withdrawn amount
  3. Send notification to user: Title "Processus de retrait", Body "Vous avez retiré X TND de votre compte"
  4. Update UI immediately
  5. Show success snackbar: "Retrait de X.XX TND effectué!"

#### Section 3 — Commandes List

- Header: "Commandes assignées à ce livreur:" (for delivery_person) or "Commandes de ce client:" (for business_client)
- **For delivery_person:** fetched by `vehicleId`
- **For business_client:** fetched by `expediteur.id`
- Each order card: shipping icon, "Commande ID: [id]", "Client: [name]"
- Click → `/admin-portal/commandes/:id`
- Empty state: "Aucune commande trouvée."

### 6.13 Payments — `/admin-portal/payments`

**AppBar:** "Payments" — **Admin only** (sidebar drawer item)

#### Controls

- **Livreur dropdown:** "Select Delivery Man" — users where `role = delivery_person`, shows name
- **Date picker:** "Selected Date: yyyy-MM-dd" + calendar icon button

#### Query

```sql
SELECT * FROM commandes 
WHERE livreur_id = :selectedLivreur 
  AND delivery_date >= :startOfDay 
  AND delivery_date < :endOfDay
```

#### Display

- **"Total Collected: X.XX TND"** (bold 18px) — sum of `prix_total` for orders where `status = "Livrer"`
- **"Total Delivery Fees: X.XX TND"** (bold 18px, **red**) — sum of `frais_livraison` for delivered orders
- **Order list:** Each item shows ID, Amount (TND), Paid status (✅ Paid / ❌ Not Paid)

#### "Confirm Payment" Button

**Batch operation for ALL listed orders:**

1. For each **delivered + unpaid** order:
   - Set `paid = true`
   - Update expéditeur: `montant_disponible += (prix_total - frais_livraison)`
   - Send notification: Title "Paiement reçu 💰", Body "Votre colis a été livré. Vous avez reçu X DT."

2. For each **cancelled** order:
   - Deduct 2 DT from expéditeur: `montant_disponible -= 2`
   - Send notification: Title "Retrait de 2DT", Body "Commande annulée (ID: X)! Un retrait de 2DT a été appliqué à votre compte."

3. Commit all updates in a single batch
4. Send all notifications in parallel
5. Refresh order list
6. Show success: "Paiement confirmé et notifications envoyées!"
7. Reset totalCollected to 0

### 6.14 Vehicle List — `/admin-portal/vehicles`

**AppBar:** "Liste des Véhicules" (brown `#6D4C41`)

**Data:** Real-time stream of all `vehicles`

**Each vehicle card** (radius 12):
- Car icon (brown)
- Text: "matricule - model"
- **Edit icon (blue)** → dialog to update matricule + model
- **Delete icon (red)** → confirmation dialog: "Êtes-vous sûr de vouloir supprimer ce véhicule ?" → delete
- **Click card** → `/admin-portal/vehicles/:id`

**Empty state:** "Aucun véhicule disponible"

**FAB (+):** Opens dialog:
- Matricule text field
- Modèle text field
- "Ajouter" button → insert vehicle with `status = "available"`

### 6.15 Vehicle Details — `/admin-portal/vehicles/:id`

**AppBar:** "Détails du Véhicule"

#### Card 1 — Vehicle Info
- Car icon (blue), Matricule (bold 18px), Model

#### Card 2 — Assigned Livreur
- If assigned: Person icon (green), Livreur name (bold 16px), Phone number
- If not assigned: "Aucun livreur assigné"

#### Button: "Changer le livreur" / "Choisir un livreur"

Opens bottom sheet listing all `delivery_person` users (name, email). On select:

1. **Remove livreur from previous vehicle** (if assigned elsewhere): set that vehicle's `livreur = null`
2. Set this vehicle: `livreur = new livreur ID`, `status = "not available"`
3. Update user: `vehicleId = this vehicle ID`
4. Refresh vehicle details

#### Section: Today's Commandes

- Query: `commandes` where `vehicleId = this vehicle` AND `deliveryDate = today`
- Header: "Commandes de livraison aujourd'hui:"
- Each order card → click → `/admin-portal/commandes/:id`
- Empty: "Aucune commande pour aujourd'hui."

---

## 7. Livreur (Delivery Person) Panel

**Secret URL:** `/livreur-portal/login` — NOT linked on public site

### 7.1 Login — `/livreur-portal/login`

Same login form. Only allows `delivery_person` role. Others get "Accès refusé".

### 7.2 Dashboard — `/livreur-portal/dashboard`

**AppBar:** "Livreur Dashboard" (saddle brown `#8B4513`) + Profile icon  
**FAB:** QR scanner icon (brown `#8B4513`, white icon) → `/livreur-portal/scan`  
**Pull-to-refresh:** Reloads all stats

#### Section 1 — Summary

- "Résumé des Colis" (22px bold)
- "Total des Colis : X" (today's assigned orders count)
- "Colis Livrés : Y"
- **Progress bar:**
  - Value: `(delivered + cancelled + relivrer) / total`
  - Style: brown `#8B4513` on tan `#DEB887` background, rounded corners, 12px height

#### Section 2 — Stats Grid (2×2 clickable cards)

| Card | Icon | Color | Click Action |
|------|------|-------|-------------|
| En Livrer | local_shipping | `#A0522D` | → `/livreur-portal/orders?status=En route` |
| Livrer | check_circle | `#8B4513` | → `/livreur-portal/orders?status=Livrer` |
| Annuler | cancel | `#8B0000` | → `/livreur-portal/orders?status=Annuler` |
| Relivrer | refresh | `#DEB887` | → `/livreur-portal/orders?status=Relivrer` |

Card style: white background, elevation 6, radius 20px, icon 40px, count 22px bold colored.

#### Section 3 — Earnings

- "Revenus Totaux" (22px bold)
- "Montant Gagné : $X.XX" — sum of `prix_total` for delivered orders today

#### Stats Calculation Logic

1. Query **ALL** `commandes` where `livreurId = current user`
2. Filter locally: only orders where `deliveryDate` = today
3. Count by status: En route, Livrer, Annuler, Relivrer
4. Earnings = sum of `prix_total` for "Livrer" status orders today

### 7.3 Order List — `/livreur-portal/orders`

**AppBar:** "Liste des Commandes" (brown `#8B4513`)

**Query:** `commandes` where `livreurId = current user` AND `status = query param`  
**Local filter:** Only orders where `deliveryDate = today`

**Each order card** (elevation 4, radius 12):
- **Leading icon:** status-based (check_circle=Livrer green, local_shipping=En route orange, cancel=Annuler red, refresh=Relivrer blue)
- **Title:** Product name (bold)
- **Subtitle:** "Statut: X", "Prix Total: $X.XX", "Date de Livraison: ..."
- **Click** → order details screen
- **Pull-to-refresh** supported

### 7.4 Livreur QR Scanner — `/livreur-portal/scan`

**AppBar:** "Scanner le QR Code" (brown `#8B4513`)

**⚠️ DIFFERENT behavior from agent scanner!**

#### Scan Logic

1. Scan QR → get order ID
2. Fetch order from `commandes` table
3. Check status:

**If status = "En dépôt":**
- Auto-update status to `"En route"`
- Set `livreurId = current user`
- Show success snackbar: "Statut changé à : En route"

**If status = "En route" OR "Relivrer" OR "Annuler":**
- Show dialog: **"Changer le statut du colis"**
- Text: "Choisissez une action :"
- 3 action buttons:
  - **"Livrer"** — sets status to `"Livrer"` (no reason needed)
  - **"Relivrer"** — shows reason text field (input labeled "Motif (obligatoire)"), required before confirm
  - **"Annuler"** — shows reason text field (required before confirm)
- **"Confirmer"** button — validates reason if needed, then updates order
- **"Cancel"** button — closes dialog without changes

On update:
1. Update commande: `status`, `livreurId`, and `reason` (if provided)
2. Send notification to expéditeur:
   - Title: "Commande [ID]"
   - Body: "Votre commande est maintenant: [status]"
3. Show success snackbar: "Statut changé à : [status]"
4. Navigate back to livreur dashboard (full refresh)

**If any other status:**
- Show snackbar: "Le colis est actuellement dans l'état : [status]"

**If order not found:**
- "Commande introuvable!"

**On web:** Use browser camera API (`navigator.mediaDevices.getUserMedia`) with `html5-qrcode` library.

---

## 8. Shared Components

These screens are identical across all portals, with different base URLs.

### 8.1 Profile Screen

**URLs:**
- `/dashboard/profile` (expéditeur)
- `/admin-portal/profile` (admin/agent)
- `/livreur-portal/profile` (livreur)

**AppBar:** "Profil"

#### Card 1 — Profile Info

- Avatar circle: 50px radius, brown[100] background, person icon 50px
- Name (26px bold)
- Email (16px grey)
- Divider
- Phone row: phone icon + value
- Address row: location_on icon + value

#### Card 2 — Financial Stats (business_client role ONLY)

- Title: "Statistiques financières" (18px bold)
- **"Montant Disponible"** — green wallet icon — value from `users.montant_disponible`
- **"Montant Non Disponible"** — red lock icon — calculated: sum of `prix_total` for commandes where `status = "Livrer"` AND (`paid = false` OR `paid = null`)

#### Card 3 — Password Update

- Title: "Mettre à jour le mot de passe" (18px bold)
- **Current password** field: lock_outline icon, obscured, required
- **New password** field: lock icon, obscured, minimum 6 characters
- **"Mettre à jour"** button: blue, full width, with loading spinner
- On submit:
  1. Re-authenticate user with current password
  2. Update password
  3. Success: "Mot de passe mis à jour avec succès !"
  4. Error: show error message
  5. Clear both fields

#### Logout Button

- Red button with logout icon
- Text: "Déconnexion" (18px white)
- On click:
  1. Sign out from Supabase
  2. Clear all local session data
  3. Redirect to the respective login page for the user's portal

### 8.2 Notifications Screen

**Data:** Real-time stream from `notifications` table  
**Filter:** `receiverId = current user`, ordered by `sentAt DESC`

#### Empty State

- Bell-off icon (80px, grey)
- "Aucune notification disponible" (18px grey)

#### Each Notification Card (elevation 4, radius 12)

- **Leading:** Circle avatar
  - Brown background + bell icon (if **unread**)
  - Grey background + bell icon (if **read**)
- **Title:** Notification title (bold 16px)
  - Black if unread, grey if read
- **Body:** Notification body (14px grey)
- **Timestamp:** "dd MMM yyyy, HH:mm" (12px grey)
- **Trailing indicator:**
  - Small brown dot (12px) if **unread**
  - Green checkmark if **read**

#### Interactions

- **Tap notification** → mark as read (`isRead = true` in database)
- **Swipe left to delete** → red background with delete icon → remove from database → snackbar "Notification supprimée"

---

## 9. Order Status Flow

### State Machine

```
                    ┌──────────────────────────────────┐
                    │                                  │
  [Create] ──► En cours ──► En dépôt ──► En route ──► Livrer (final)
                                              │
                                              ├──► Annuler (final)
                                              │
                                              └──► Relivrer ──► En dépôt (retry loop)
```

### Status Details

| Status | French | Meaning | Set By | How |
|--------|--------|---------|--------|-----|
| En cours | In progress | Order created, waiting for pickup | System | Auto on order creation |
| En dépôt | In depot | Order received at depot, assigned vehicle + date | Agent | QR scan + assign vehicle + date on Colis screen |
| En route | On the way | Out for delivery | Livreur | QR scan auto-changes from "En dépôt" |
| Livrer | Delivered | Successfully delivered to client | Livreur | QR scan + choose "Livrer" in dialog |
| Annuler | Cancelled | Delivery failed/refused | Livreur | QR scan + choose "Annuler" + reason (required) |
| Relivrer | Re-deliver | Need to retry delivery | Livreur | QR scan + choose "Relivrer" + reason (required) |

### QR Scanner Behavior Comparison

| Scenario | Agent Scanner | Livreur Scanner |
|----------|-------------|----------------|
| Status = "En cours" | → Colis Confirmation screen | N/A (not assigned yet) |
| Status = "En dépôt" | Show status snackbar | → Auto-update to "En route" |
| Status = "En route" | Show status snackbar | → Dialog: Livrer / Relivrer / Annuler |
| Status = "Relivrer" | Show status snackbar | → Dialog: Livrer / Relivrer / Annuler |
| Status = "Annuler" | Show status snackbar | → Dialog: Livrer / Relivrer / Annuler |
| Status = "Livrer" | Show status snackbar | Show status snackbar |
| Not found | "Commande introuvable!" | "Commande introuvable!" |

---

## 10. Notification System

### Notification Events

| Trigger | Recipients | Title | Body |
|---------|-----------|-------|------|
| Order created (expéditeur) | All admin + agent users | Nouvelle Commande | Une nouvelle commande a été placée! |
| Colis confirmed (agent assigns vehicle+date) | Expéditeur (order owner) | Livraison Confirmée | Votre colis a été confirmé et sera livré le dd/MM/yyyy |
| Livreur changes status | Expéditeur (order owner) | Commande [ID] | Votre commande est maintenant: [status] |
| Payment confirmed (admin) | Expéditeur (order owner) | Paiement reçu 💰 | Votre colis a été livré. Vous avez reçu X DT. |
| Order cancelled during payment | Expéditeur (order owner) | Retrait de 2DT | Commande annulée (ID: X)! Un retrait de 2DT a été appliqué à votre compte. |
| Admin withdrawal from user | Expéditeur (target user) | Processus de retrait | Vous avez retiré X TND de votre compte. |

### Notification Storage

Each notification is **both:**
1. Sent as push notification (FCM/OneSignal via Edge Function)
2. Saved to `notifications` table for in-app display

### Notification Document Structure

```json
{
  "title": "Nouvelle Commande",
  "body": "Une nouvelle commande a été placée!",
  "orderId": "1234567890",
  "senderId": "uid-of-sender",
  "receiverId": "uid-of-receiver",
  "isRead": false,
  "sentAt": "2026-10-01T22:00:00Z"
}
```

---

## 11. PDF Generation

### Type 1: Single Order PDF

**Used on:** Expéditeur orders screen, Agent commandes screen (print icon button)

**Content:**
- Company logo (top)
- QR code containing the order ID (scannable)
- Order details: ID, client info, product info, pricing
- Expéditeur info: name, phone (fetched fresh from users table)

**Before generating:**
1. Fetch expéditeur full data from `users` table by `expediteur.id`
2. Merge into order data
3. Generate and show print preview / download

### Type 2: Delivery Route PDF

**Used on:** Delivery circuit screen → "Génération d'un circuit" button

**Layout:** Landscape orientation, multi-page

**Content:**
- Company logo
- Livreur name
- Vehicle: "model - matricule"
- Date (formatted yyyy/MM/dd)
- All orders grouped by gouvernorat then by ville
- Each order: client name, phone, address, product, price

**Font:** Roboto (included in assets as `assets/fonts/Roboto-Regular.ttf`)

**On web:** Use `@react-pdf/renderer` or `jsPDF` for client-side PDF generation. Trigger browser download/print dialog.

---

## 12. Database Schema (Supabase PostgreSQL)

### Table: `users`

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | uuid | PK, references auth.users(id) | Supabase Auth user ID |
| `uid` | text | Same as id | Legacy compatibility field |
| `email` | text | NOT NULL, UNIQUE | User email |
| `name` | text | NOT NULL | Display name |
| `role` | text | NOT NULL, CHECK IN (admin, agent, business_client, delivery_person) | User role |
| `phone` | text | NULLABLE | Phone number |
| `address` | text | NULLABLE | Address |
| `fcm_token` | text | NULLABLE | Push notification token |
| `montant_disponible` | numeric | DEFAULT 0 | Available balance (expéditeur) |
| `vehicleId` | text | NULLABLE, FK → vehicles | Assigned vehicle (delivery_person) |
| `created_at` | timestamptz | DEFAULT now() | Account creation date |

**RLS Policies:**
- SELECT: Users read own row. Admin/agent read all.
- UPDATE: Users update own profile fields. Admin can update any.
- INSERT: Via Edge Function only (admin creates accounts).
- DELETE: Admin only.

### Table: `commandes`

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | text | PK | Order ID (timestamp-based) |
| `client_nom` | text | NOT NULL | Recipient name |
| `client_telephone` | text | NOT NULL | Recipient phone |
| `client_gouvernorat` | text | NOT NULL | Recipient gouvernorat |
| `client_adresse` | text | NOT NULL | Recipient address |
| `client_ville` | text | NOT NULL | Recipient city |
| `produit_nom` | text | NOT NULL | Product name |
| `produit_prix_total` | numeric | NOT NULL | Total product price |
| `produit_fragile` | boolean | DEFAULT false | Is fragile |
| `produit_ouvrir_avant_paiement` | boolean | DEFAULT false | Can open before payment |
| `produit_list` | jsonb | NULLABLE | Array of `{name, quantity, pricePerKilo}` |
| `expediteur_id` | uuid | FK → users(id), NOT NULL | Business client who created |
| `expediteur_name` | text | NOT NULL | Cached expéditeur name |
| `livreur_id` | uuid | FK → users(id), NULLABLE | Assigned delivery person |
| `vehicle_id` | text | FK → vehicles(id), NULLABLE | Assigned vehicle |
| `status` | text | NOT NULL, DEFAULT 'En cours' | Order status |
| `paid` | boolean | DEFAULT false | Payment collected |
| `livraison` | text | DEFAULT 'Pickup' | Delivery type |
| `frais_livraison` | numeric | DEFAULT 0 | Delivery fee |
| `reason` | text | NULLABLE | Reason for Annuler/Relivrer |
| `date` | timestamptz | DEFAULT now() | Order creation date |
| `delivery_date` | timestamptz | NULLABLE | Scheduled delivery date |

**RLS Policies:**
- SELECT: Expéditeur sees own (`expediteur_id = auth.uid`). Livreur sees assigned (`livreur_id = auth.uid`). Admin/agent sees all.
- INSERT: `business_client` role only.
- UPDATE: Admin/agent can update all fields. Livreur can update `status`, `reason`, `livreur_id` only.
- DELETE: Expéditeur can delete own if status IN ('En cours', 'En dépôt'). Admin can delete any.

### Table: `vehicles`

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | text | PK (auto-generated) | Vehicle ID |
| `matricule` | text | NOT NULL | License plate number |
| `model` | text | NOT NULL | Vehicle model |
| `livreur` | uuid | FK → users(id), NULLABLE | Assigned delivery person |
| `status` | text | DEFAULT 'available' | 'available' or 'not available' |

**RLS Policies:**
- SELECT: Admin/agent read all. Livreur reads assigned.
- INSERT/UPDATE/DELETE: Admin/agent only.

### Table: `transactions`

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | uuid | PK, DEFAULT gen_random_uuid() | Transaction ID |
| `agentId` | uuid | FK → users(id) | Who performed the withdrawal |
| `expediteurId` | uuid | FK → users(id), NOT NULL | Whose balance changed |
| `montant` | numeric | NOT NULL | Transaction amount |
| `type` | text | NOT NULL | Transaction type (e.g., 'retrait') |
| `date` | timestamptz | DEFAULT now() | Transaction date |

**RLS Policies:**
- SELECT: Expéditeurs see own (`expediteurId = auth.uid`). Admin sees all.
- INSERT: Admin/agent only (via Edge Function or direct).

### Table: `notifications`

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | uuid | PK, DEFAULT gen_random_uuid() | Notification ID |
| `title` | text | NOT NULL | Notification title |
| `body` | text | NOT NULL | Notification body |
| `senderId` | uuid | FK → users(id) | Who triggered the notification |
| `receiverId` | uuid | FK → users(id), NOT NULL | Who receives it |
| `orderId` | text | NULLABLE, FK → commandes(id) | Related order |
| `isRead` | boolean | DEFAULT false | Read status |
| `sentAt` | timestamptz | DEFAULT now() | Sent timestamp |

**RLS Policies:**
- SELECT: Users see own (`receiverId = auth.uid`).
- UPDATE: Users can update `isRead` on own notifications.
- DELETE: Users can delete own notifications.
- INSERT: Admin/agent can insert for any receiverId (via Edge Function).

### Table: `tarifs`

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | uuid | PK, DEFAULT gen_random_uuid() | Tarif ID |
| `type` | text | NOT NULL | Tarif type (e.g., 'Standard', 'Express') |
| `prix` | numeric | NOT NULL | Shipping price |
| `prix_retour` | numeric | NOT NULL | Return price |

**RLS Policies:**
- SELECT: Everyone can read.
- INSERT/UPDATE/DELETE: Admin only.

---

## 13. Tech Stack & Libraries

### Frontend (Recommended: Next.js)

| Category | Choice |
|----------|--------|
| Framework | Next.js 14+ with App Router |
| Language | TypeScript |
| Styling | Tailwind CSS |
| Components | Shadcn/ui |
| Deployment | Vercel |

### Backend

| Category | Choice |
|----------|--------|
| Auth | Supabase Auth (email/password) |
| Database | Supabase PostgreSQL + RLS |
| Realtime | Supabase Realtime subscriptions |
| Serverless | Supabase Edge Functions (Deno) |
| SDK | @supabase/supabase-js |

### Required Libraries

| Purpose | Library | Notes |
|---------|---------|-------|
| Auth | @supabase/auth-helpers-nextjs | SSR-compatible auth with middleware |
| Realtime | @supabase/supabase-js | Built-in `realtime.channel()` subscriptions |
| QR Scanning (web) | html5-qrcode | Browser camera API QR scanning |
| QR Generation | qrcode.react | Generate QR codes for order PDFs |
| PDF Generation | @react-pdf/renderer or jsPDF | Client-side PDF for routes & invoices |
| Data Tables | @tanstack/react-table | Sorting, filtering, pagination |
| Date Handling | date-fns | Date formatting and comparison |
| Forms | react-hook-form + zod | Form state and validation |
| State Management | Zustand or React Query | Client state + server state caching |
| Icons | lucide-react | Clean, consistent icon set |
| Toasts / Notifications | sonner | Toast notifications UI |

---

## 14. Supabase Edge Functions

### Function 1: `create-user`

**Trigger:** Called from admin Create Account form  
**Purpose:** Create Supabase Auth user + insert `users` row

**Why needed:** Admin cannot create auth users from the client-side using the anon key. The `supabase.auth.admin.createUser()` method requires the service_role key, which must only be used server-side.

**Input:**
```json
{
  "email": "user@example.com",
  "password": "securepassword",
  "name": "User Name",
  "phone": "12345678",
  "address": "123 Street",
  "role": "business_client"
}
```

**Logic:**
1. Create auth user with `supabase.auth.admin.createUser()`
2. Insert row into `users` table with all fields + `uid`
3. Return success/error

### Function 2: `send-notification`

**Trigger:** Called from client after order creation, status changes, payments  
**Purpose:** Insert notification into table + optionally send push via FCM/OneSignal

**Input:**
```json
{
  "title": "Nouvelle Commande",
  "body": "Une nouvelle commande a été placée!",
  "senderId": "uid-of-sender",
  "receiverId": "uid-of-receiver",
  "orderId": "order-id"
}
```

**Logic:**
1. Insert into `notifications` table
2. Fetch receiver's `fcm_token` from `users` table
3. If token exists, send push notification via FCM/OneSignal HTTP API
4. Return success

### Function 3: `confirm-payment`

**Trigger:** Called from admin Payments screen "Confirm Payment" button  
**Purpose:** Batch update paid status + balances + transactions + notifications

**Input:**
```json
{
  "livreurId": "uid",
  "date": "2026-10-01",
  "orders": ["order-id-1", "order-id-2"]
}
```

**Logic:**
1. For each delivered + unpaid order: set `paid = true`, credit expéditeur balance
2. For each cancelled order: deduct 2 DT from expéditeur balance
3. Send notifications to all affected expéditeurs
4. Return summary

---

## 15. Environment Variables & Security

### Frontend (.env.local)

```env
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJ...your-anon-key
```

These are **safe to expose** in the frontend — RLS policies protect data.

### Edge Functions (Supabase secrets)

```env
SUPABASE_SERVICE_ROLE_KEY=eyJ...your-service-role-key
FCM_SERVER_KEY=your-fcm-key  # Optional, for push notifications
```

### ⚠️ Security Rules

1. **NEVER expose** `SUPABASE_SERVICE_ROLE_KEY` in frontend code
2. All admin operations (create user, batch payments) go through **Edge Functions**
3. All data access must go through **RLS policies** — no client-side role checks as the only security layer
4. Do **NOT** store plaintext passwords anywhere
5. Do **NOT** embed API secret keys in client code

---

## 16. Deployment

| Component | Recommended Host | Notes |
|-----------|-----------------|-------|
| Next.js Frontend | **Vercel** | Free tier, auto-deploys from Git, edge functions |
| Supabase Backend | **Supabase Cloud** | Free tier: 500MB DB, 1GB storage, 2GB bandwidth |
| Domain | Custom domain | Point `allocoursier.tn` or similar to Vercel |
| Edge Functions | **Supabase Edge** | Deploy via `supabase functions deploy`, runs on Deno Deploy |

### Deployment Checklist

- [ ] Create Supabase project
- [ ] Run SQL migrations to create all 6 tables
- [ ] Enable RLS on all tables and create policies
- [ ] Deploy 3 Edge Functions
- [ ] Set up Supabase Auth (enable email provider)
- [ ] Create admin user manually in Supabase dashboard
- [ ] Deploy Next.js app to Vercel
- [ ] Configure custom domain
- [ ] Test all 4 role flows end-to-end
- [ ] Share secret URLs with admin and livreurs privately

---

*Document generated from complete analysis of 40 Dart source files in the Allo Coursier Flutter app.*

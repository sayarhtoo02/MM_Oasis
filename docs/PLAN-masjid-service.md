# PLAN: Masjid Near Me Service

## Overview
A new service providing mapping, discovery, and detailed information for Masjids near the user. This service will follow the "Halal Shop" architecture but with Masjid-specific features like Prayer Times (Jamat), facilities, and a dedicated manager role for local authorities.

## Success Criteria
- [ ] Users can discover nearby Masjids on a premium map with custom icons.
- [ ] Users can view Jamat times,Facilities, and Announcements for each Masjid.
- [ ] Verified Masjid Managers can update their Masjid's data in real-time.
- [ ] Admins can approve/reject new Masjid registrations.

## Proposed Architecture

### 1. Database Schema (`munajat_app` schema)

#### `masjids`
- `id`: UUID (Primary Key)
- `name`: TEXT
- `address`: TEXT
- `lat`: DOUBLE
- `long`: DOUBLE
- `manager_id`: UUID (References profiles.id)
- `status`: TEXT ('pending', 'approved', 'rejected')
- `description`: TEXT
- `facilities`: JSONB (e.g., {"wudu": true, "ladies_section": true, "parking": true})
- `Bayan languages`: TEXT[]
- `contact_number`: TEXT
- `created_at`: TIMESTAMP

#### `masjid_jamat_times`
- `id`: UUID
- `masjid_id`: UUID (References masjids.id)
- `fajr`, `dhuhr`, `asr`, `maghrib`, `isha`: TEXT (Time strings)
- `jummah`: TEXT
- `updated_at`: TIMESTAMP

#### `masjid_images`
- `id`: UUID
- `masjid_id`: UUID
- `image_url`: TEXT
- `image_type`: TEXT ('logo', 'exterior', 'interior')
- `display_order`: INT

### 2. Service Layer
- **`MasjidService`**: Core CRUD for Masjids, including status filtering (approved only for users, all for managers/admins).
- **`MasjidImageService`**: Handling image uploads to Supabase storage.
- **`MasjidManagerService`**: Logic for managers to update Jamat times and announcements.

### 3. UI Implementation
- **`MasjidListScreen`**: Premium list with "Pro Max" animations and search.
- **`MasjidMapView`**: Integrated Map with custom markers showing Masjid name/logo.
- **`MasjidDetailScreen`**: Detailed view with Jamat times card, facilities chips, and map preview.
- **`MasjidRegistrationScreen`**: Form for users to request adding a new Masjid.
- **`MasjidManagerDashboard`**: Dashboard for managers to update their Masjid's data.

## Task Breakdown

### Phase 1: Database & Backend
- [ ] Create `masjids`, `masjid_jamat_times`, and `masjid_images` tables in Supabase.
- [ ] Set up RLS policies:
    - View: Approved masjids visible to everyone.
    - Edit: Only `manager_id` or `admin` can edit.
    - Create: Authenticated users can create (status = 'pending').

### Phase 2: Service Layer
- [ ] Implement `MasjidService`.
- [ ] Implement `MasjidImageService`.
- [ ] Implement `MasjidManagerService`.

### Phase 3: Core Discovery UI
- [ ] Build `MasjidListScreen` with search and filters.
- [ ] Build `MasjidMapView` with custom markers (similar to Shop markers).
- [ ] Build `MasjidDetailScreen`.

### Phase 4: Management Flow
- [ ] Build `MasjidRegistrationScreen`.
- [ ] Build `MasjidManagerDashboard`.
- [ ] Implement "Edit Jamat Times" quick settings.

### Phase 5: Verification
- [ ] Test registration flow.
- [ ] Verify RLS policies.
- [ ] Verify map marker generation with Masjid logos.

---

### 8. Masjid Near Me Service [PHASED]
A new dedicated service for Masjid discovery and management.

#### Database Schema
- `masjids`: Detailed mosque data, location, and manager assignment.
- `masjid_jamat_times`: Prayer times manageable by mosque admins.
- `masjid_images`: Storage for masjid logos and photos.

#### Core UI Implementation
- **Masjid List Screen**: Premium discovery view with staggered animations.
- **Masjid Map View**: Integrated mapping with custom markers (logos/labels).
- **Masjid Detail Screen**: Comprehensive view including Jamat times and facilities.

#### Management & Flow
- **Masjid Registration**: User-driven request system.
- **Approval Workflow**: Admin validation required before public display.
- **Manager Dashboard**: Update prayer times and announcements in real-time.

## Verification Plan

### Automated Tests
- `dart test test/services/masjid_service_test.dart` (CRUD & RLS verification)

### Manual Verification
1. Register a new Masjid and verify it stays in 'pending' status.
2. Approve via database/admin and verify appearance in the "Nearby Masjids" list.
3. Update Jamat times as a manager and verify instant reflect on the detail screen.

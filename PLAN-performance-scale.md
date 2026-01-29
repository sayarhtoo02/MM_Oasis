# Performance & Scalability Plan

## Overview
This plan addresses the current performance bottlenecks (Splash Screen) and prepares the application for future scalability (Halal Shop, Masjid Finder). The goal is to ensure the app remains responsive as the user base and data volume grow.

**Project Type:** MOBILE (Flutter)

## Success Criteria
1.  **Startup Time:** Reduce splash screen duration by at least 40% (defer non-critical tasks).
2.  **Scalability:** Implement pagination/infinite scroll for Halal Shop and Masjid Finder to handle 1000+ items smoothly.
3.  **Responsiveness:** UI maintains 60fps during list scrolling and map interactions.

## Tech Stack
-   **Flutter:** Mobile Framework.
-   **Supabase:** Backend (Database & Auth).
-   **R2:** Backend (File Storage).
-   **Provider/Riverpod:** State Management (Assumed, need to verify).
-   **Google Maps/Flutter Map:** For Masjid Finder.

## Architecture & Strategy

### 1. Startup Optimization (Splash Screen)
*   **Problem:** Initializing all services at once blocks the main thread or delays navigation.
*   **Solution:**
    *   **Parallel Initialization:** Identify independent services and initialize them concurrently.
    *   **Lazy Loading:** Only initialize services needed immediately (e.g., Auth). Defer others (e.g., Shop, Ads) until their screens are accessed.
    *   **Native Splash:** Ensure the native splash screen transitions smoothly to the Flutter UI to perceive faster loading.

### 2. Data Scalability (Shop & Masjid)
*   **Problem:** Fetching all data at once works now but will crash/lag with thousands of records.
*   **Solution:**
    *   **Server-Side Pagination:** Modify Supabase queries to fetch data in chunks (e.g., 20 items using `.range()`).
    *   **Infinite Scroll:** Implement `ScrollController` listeners to fetch the next page when reaching the bottom.
    *   **Search & Indexing:** Ensure database columns used for filtering (location, category) are indexed in Supabase.
    *   **Map Clustering:** For Masjid Finder, use marker clustering to render thousands of points efficiently.

## Task Breakdown

### Phase 1: Startup Optimization
- [ ] **Analyze Initialization:** Audit `main.dart` and `splash_screen.dart` to list all `await` calls. <!-- INPUT: Source Code -> OUTPUT: List of blockers -> VERIFY: Logs -->
- [ ] **Implement Parallel Init:** Use `Future.wait([])` for non-dependent async tasks. <!-- INPUT: `main.dart` -> OUTPUT: Concurrency code -> VERIFY: Stopwatch logs -->
- [ ] **Defer Non-Critical Logic:** Move heavy logic (e.g., pre-fetching all shop data) out of the splash path. <!-- INPUT: Splash logic -> OUTPUT: Post-splash initialization -> VERIFY: App reaches Home screen faster -->

### Phase 2: Halal Shop Scalability
- [ ] **Backend Pagination:** Update Supabase service to accept `limit` and `offset`/`page` parameters. <!-- INPUT: Shop Service -> OUTPUT: Paginated Query -> VERIFY: Returns strictly N items -->
- [ ] **UI Infinite Scroll:** Update Shop List UI to trigger load-more actions. <!-- INPUT: Shop ListView -> OUTPUT: Infinite Scrolling List -> VERIFY: Scrolling loads new items -->
- [ ] **Optimized Search:** Ensure search queries run on the server side, not local filtering. <!-- INPUT: Search Logic -> OUTPUT: RPC or ILIKE query -> VERIFY: Fast search on large dataset -->

### Phase 3: Masjid Finder Scalability
- [ ] **Geospatial Querying:** Use PostGIS (if available) or bounds-based querying to fetch only visible Masjids. <!-- INPUT: Map Service -> OUTPUT: Bounded Query -> VERIFY: Only loads visible markers -->
- [ ] **Marker Clustering:** Implement Google Maps Clustering to group nearby Masjids. <!-- INPUT: Map Widget -> OUTPUT: Clustered System -> VERIFY: Map remains smooth with simulated 500+ markers -->

### Phase 4: Verification (Phase X)
- [ ] **Startup Benchmark:** Measure time from launch to home screen (Target: < 2s warm start).
- [ ] **Load Testing:** Simulate 1000 records in Supabase (or mock) and scroll through the list.
- [ ] **Memory Profiling:** Ensure no memory leaks during infinite scrolling.

## Risk Assessment
-   **Risk:** Pagination might break existing "sort by distance" logic if handled client-side.
    *   **Mitigation:** Move distance sorting to the database (PostGIS) or edge function.
-   **Risk:** Marker Clustering libraries can be complex to customize.
    *   **Mitigation:** Stick to standard clustering first, custom UI later.

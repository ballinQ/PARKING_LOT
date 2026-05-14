# Phase 2.5 Architecture Review

Status: planned architecture. No implementation is approved until source review passes.

## Current Foundation

Phase 2 already added dormant model types for future public parking work:

- `ParkingSource`
- `PublicParkingLot`
- `GreenPParkingLot`
- rate and availability helper types

These models are not currently connected to Map UI, storage, networking, or production Green P data. That separation is correct and should be preserved.

## Recommended Architecture

Use a static catalog architecture first:

```text
Map UI
  -> PublicParkingCatalogService
  -> PublicParkingCatalogStore
  -> PublicParkingDataProvider
      -> BundledPublicParkingProvider
      -> FutureRemoteDatasetProvider
      -> FutureBackendProvider
      -> FutureOfficialLiveProvider
```

Phase 2.5 should implement only the bundled/static path after source approval. Future provider shapes should remain behind protocols so Map UI does not care whether data comes from a bundled file, official dataset feed, backend, or future official live API.

## Data Boundary

Personal data:

- parking sessions
- saved spot metadata
- personal history markers
- personal notes, tags, rating, favorite status

Public/provider data:

- source manifest
- public parking lot catalog
- import reports
- source URL and source update timestamp

Do not store public lots inside session history or saved spot metadata. Do not infer public parking supply from personal history.

## Map Layer Boundary

The Map should render public lots as a separate marker source/layer from personal history.

Required marker distinctions:

- personal saved spot marker
- active/current session marker
- public Green P/static lot marker
- search result marker, if present

The old History list must not return. Public lot rows, if any, must live inside the Map bottom-sheet workflow.

## Availability Boundary

Static catalog data can show:

- address
- distance
- verified rate text
- facility type
- capacity if verified
- EV charging if verified
- height restriction if verified
- source/update warning

Static catalog data must not show:

- real-time available spaces
- live occupancy
- payment status
- personalized recommendation score

Real-time availability is Phase 4 or later and requires an official live source or partnership.

## Backend Boundary

Phase 2.5 must not implement Supabase, backend ingestion, login, cloud sync, analytics, server push, or community/public user data.

Phase 3+ may revisit backend if there is a clear need for:

- remote catalog update manifest
- multi-provider normalization
- account/cloud sync
- community map concepts

## Main Risks

- No official Green P machine-readable catalog may be available.
- Source/licence may not allow bundled reuse.
- Rates and restrictions may become stale.
- Users may misread static lot data as availability.
- Public markers could visually compete with personal history markers.

Mitigation:

- block visible UI until source approval
- show conservative warning copy
- validate every catalog revision
- keep marker styling distinct
- never use "available spaces" wording


# Toronto Green P / Public Parking Catalog Research Note

Status: research and planning only. Do not implement from this note until the user explicitly asks the development thread to start.

Last updated: 2026-05-08

## Product Decision

The app should eventually support nearby public parking options, starting with Toronto Green P. The first production version should show **nearby parking options**, not **real-time available spaces**.

Recommended phase placement:

- Phase 2: research, architecture design, source validation, and maybe a disabled/static prototype only.
- Phase 3: production static Green P/public parking data layer if official data is reliable and licensed.
- Phase 4: real-time availability, payment, backend ingestion, or deeper provider integration only with an official API or partnership.

Do not add backend, cloud sync, analytics, ML, payment, marketplace, public/community user data, or continuous background location for this feature.

## Current Source Findings

### 1. Toronto Open Data

Toronto Open Data is the preferred source if an active, relevant dataset exists because the licence is clear and reusable.

Relevant findings:

- The `parking-lot-facilities` dataset exists on Toronto Open Data.
- It is not a Green P commercial parking-lot inventory. The CKAN description says it covers parking lots operated by Parks, Forestry & Recreation, such as parks/community-centre/school/pool building grounds.
- Fields described by the dataset include parking lot asset ID, park name, spaces, accessible spaces, GIS coordinates, and access.
- The dataset metadata says the valid data range is 2013-2015 and references validation work from 2016, so it is not suitable as current Green P truth.
- Toronto Open Data licence allows reuse, including commercial use, with attribution and no implied endorsement.

Source URLs:

- `https://open.toronto.ca/dataset/parking-lot-facilities/`
- `https://ckan0.cf.opendata.inter.prod-toronto.ca/dataset/parking-lot-facilities`
- `https://open.toronto.ca/open-data-licence/`
- `https://open.toronto.ca/docs/staff-guidance/step-5-retiring-or-removing-open-data/`

Conclusion:

Use Toronto Open Data as the first place to look for official machine-readable data, but do not treat `parking-lot-facilities` as production Green P data.

### 2. Green P / Toronto Parking Authority Site

Green P has public web surfaces for finding parking, parking information, FAQs, garage/lot parking, on-street parking, rates, app payment, EV notices, and closure notices.

Relevant findings:

- Green P / Toronto Parking Authority operates municipal off-street parking lots and on-street paid parking.
- Green P pages contain useful public context such as lot categories, approximate inventory, on-street rates, max-time notes, EV/closure news, and app/payment guidance.
- The Green P website has a Find Parking UI, but no confirmed official public app API was identified in this research pass.
- Rates can be location-specific and may be shown in the Green P app, on signs/pay stations, or on Green P pages.
- Green P FAQ states TPA operates in Toronto and Vaughan.

Source URLs:

- `https://parking.greenp.com/`
- `https://parking.greenp.com/parking-information/faqs/`
- `https://parking.greenp.com/parking-information/on-street-parking/`
- `https://parking.greenp.com/parking-information/garage-and-lot-parking/`
- `https://parking.greenp.com/about/about-us/`

Conclusion:

Green P web pages are useful for product wording and manual verification, but production app data should not depend on fragile scraping unless the terms and technical stability are confirmed.

### 3. Toronto 311

Toronto 311 has public Green P information pages. These are useful for user-support context and source cross-checking, but they are not a structured parking catalog.

Source URL:

- `https://www.toronto.ca/home/311-toronto-at-your-service/find-service-information/article/?kb=kA06g000001cwOHCAY`

Conclusion:

Use 311 pages as secondary reference only, not as the primary data source.

## Source Trust Ranking

Use this priority order:

1. Official Toronto Parking Authority / Green P documented dataset or API.
2. Official Toronto Open Data dataset that clearly covers Green P/public parking lots.
3. Official Green P website data only if terms allow structured reuse and the endpoint/page shape is stable.
4. Manually curated sample file for hidden prototype only.
5. Scraping as last resort only, and only after licence/terms review.

Never use user personal parking history to infer public parking supply.

## Storage Strategy

Use bundled cache first, but design it as a generic **Public Parking Catalog**, not a one-off Green P file.

Why bundled cache first:

- Works offline.
- Keeps the app local-only.
- Avoids backend cost and operations.
- Allows human review before data ships.
- Avoids runtime scraping and source instability.
- Fits Phase 2/early Phase 3 privacy boundaries.

Future-safe rule:

The Map UI should not know whether the lots came from bundled JSON, a downloaded dataset, a backend feed, or a future official live API.

Recommended architecture:

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

Personal storage must remain separate:

```text
Personal data
  parking_sessions.json
  saved_spot_metadata.json

Public/provider data
  public_parking_manifest.json
  greenp_lots_v1.json
  future_provider_lots_v1.json
```

Do not store Green P lots inside session history or personal spot metadata.

## Proposed Data Models

The current dormant `PublicParkingLot.swift` direction is correct. Development thread should refine it only after confirming real source fields.

Recommended conceptual model:

```swift
enum ParkingSourceKind {
    case greenP
    case torontoOpenData
    case torontoParkingAuthority
    case mapKitSearch
    case staticPrototype
    case unknown
}

struct ParkingSource {
    let id: String
    var name: String
    var organizationName: String?
    var kind: ParkingSourceKind
    var sourceURL: URL?
    var licenseDescription: String?
    var sourceLastUpdated: Date?
    var importedAt: Date?
    var updateFrequencyDescription: String?
    var isOfficial: Bool
    var supportsRealTimeAvailability: Bool
    var notes: String
}

struct PublicParkingLot {
    let id: String
    var source: ParkingSource
    var providerLotID: String?
    var name: String
    var address: String
    var latitude: Double
    var longitude: Double
    var facilityType: PublicParkingFacilityType
    var capacity: Int?
    var rateInfo: PublicParkingRateInfo
    var availabilityInfo: PublicParkingAvailabilityInfo
    var hasEVCharging: Bool?
    var heightRestrictionDescription: String?
    var sourceURL: URL?
    var sourceLastUpdated: Date?
    var importedAt: Date?
}

struct GreenPParkingLot {
    var lot: PublicParkingLot
    var carParkNumber: String?
    var greenPFacilityTypeDescription: String?
}
```

Stable IDs:

```text
<sourceID>:<providerLotID>
greenp:36
city-toronto:lot-123
partner-x:garage-abc
```

Availability rule:

```swift
canClaimRealTimeAvailability =
    source.supportsRealTimeAvailability
    && availabilityInfo.kind == .realTimeOfficial
```

If that is false, UI must say live availability is not provided.

## Bundled Cache File Design

Recommended future app resources:

```text
Resources/PublicParking/
  public_parking_manifest.json
  greenp_lots_v1.json
  greenp_import_report_v1.json
```

Manifest should include:

- schema version
- catalog version
- generated date
- source list
- source URL
- licence description
- source last updated date
- imported date
- whether the source is official
- whether the source supports real-time availability
- file list
- record counts
- checksums

Lot records should include:

- global lot ID
- source ID
- provider lot ID / car park number
- name
- address
- latitude / longitude
- facility type
- capacity
- rate summary fields
- EV charging
- height restriction
- source URL
- source last updated
- imported date
- availability kind

Use JSON first. Move to SQLite only if provider count or query performance actually requires it.

## Data Acquisition Pipeline

Do not fetch or scrape provider data in app runtime.

Future offline import flow:

```text
Find official source
  -> download raw source snapshot
  -> store raw source under data_sources/raw/<provider>/<date>/
  -> normalize into PublicParkingLot records
  -> validate records
  -> generate public_parking_manifest.json
  -> generate provider_lots_vN.json
  -> generate import report
  -> human review
  -> bundle approved output into app
```

Recommended folders outside app target:

```text
data_sources/raw/greenp/<date>/
data_sources/normalized/greenp/<date>/
data_sources/reports/greenp/<date>/
```

Import report must include:

- source URLs
- download timestamp
- source licence
- record count
- accepted count
- rejected count
- warning count
- field coverage table
- checksum
- known limitations
- reviewer name/date

## Validation Rules

Reject or flag:

- missing provider lot ID
- duplicate provider lot ID
- duplicate global lot ID
- missing latitude/longitude
- coordinate outside Toronto/Vaughan expected bounds
- missing source URL
- unknown or unapproved licence for production
- negative capacity
- impossible rate values
- missing source last updated for production candidate
- any non-official source marked `realTimeOfficial`
- any lot that claims availability without official live source support

Suggested Toronto/Vaughan rough coordinate gate:

```text
latitude: 43.50...44.00
longitude: -79.80...-79.00
```

This is a validation aid, not a legal/geographic boundary.

## Map Behavior For Future Implementation

After address search:

```text
User searches address
  -> map recenters to selected address
  -> personal history markers remain visible
  -> public parking catalog filters nearby public lots
  -> Green P/public markers appear as a separate marker layer
```

Marker rules:

- Personal History markers keep current style.
- Green P/public markers use a distinct provider style.
- Tapping a public marker opens the same bottom-sheet pattern, but with public-lot detail content.
- Public-lot detail shows address, distance, facility type, rates, max-time/price if available, EV, height, directions, source, and update warning.

Required copy:

```text
Green P data may not reflect live availability. Check official signs/app before parking.
```

Forbidden copy unless official live source exists:

```text
Available now
Spaces available
Guaranteed parking
```

## Future Roadmap

### Phase 2

Keep this research-only unless the user explicitly approves a disabled/static prototype.

Allowed:

- research notebook
- source/licence review
- import-tool design
- architecture planning
- dormant model review

Not allowed:

- visible Green P markers
- production public parking layer
- runtime scraping
- backend
- payment
- real-time availability claims

### Phase 3

Earliest phase for user-visible static Green P options.

Requirements before implementation:

- official/current source identified
- licence/terms approved
- import report created
- 10+ manually sampled lots verified
- stale-data warning approved
- source attribution copy approved

Initial production feature:

- show nearby Green P/public parking options after address search
- keep personal history markers visible
- open public-lot detail sheet on marker tap
- show directions
- show conservative source/update warning

### Phase 4

Only if there is official support or partnership:

- real-time availability
- payment integration
- Green P app deep-link/payment handoff
- remote update manifest
- backend normalization for multiple providers
- partner/private garage providers

## Development Thread Instructions

When the user asks development thread to implement:

1. Do not start with UI.
2. First confirm source and licence.
3. Create or refine import schema.
4. Create validation/import report tooling.
5. Add bundled catalog only after human review.
6. Add service layer behind protocol.
7. Only then add Map marker layer.
8. Keep public parking data separate from personal history.
9. Never claim real-time availability unless the source is official live.

## Test Strategy For Future Implementation

Unit tests:

- decode manifest
- decode provider lot file
- reject duplicate provider IDs
- reject bad coordinates
- reject missing source URL
- reject unofficial real-time claim
- nearby search returns distance-sorted lots
- filters by source/facility/EV
- public lots do not mix with personal history groups

UI tests after visible feature:

- search Toronto address
- personal markers remain visible
- Green P markers appear separately
- tapping Green P marker opens public detail sheet
- detail sheet shows source/update warning
- no "available spaces" claim appears
- directions handoff uses lot coordinate

Manual QA:

- compare at least 10 sampled lots against official Green P site/app/signage
- check rates/max times where available
- check facility type
- check EV/height restriction when available
- verify stale/unknown data warning is visible


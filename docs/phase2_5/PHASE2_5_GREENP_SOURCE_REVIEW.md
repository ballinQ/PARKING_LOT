# Phase 2.5 Green P Source Review

Status: required before visible Green P/public parking UI.

## Decision Gate

Visible Green P/public parking markers are blocked until this document records an approved source decision.

Current decision: **not approved yet**.

## Source Trust Ranking

Use this priority order:

1. Official Toronto Parking Authority / Green P documented dataset or API.
2. Official Toronto Open Data dataset that clearly covers current Green P/public parking lots.
3. Official Green P website data only if terms allow structured reuse and the endpoint/page shape is stable.
4. Manually curated sample file for hidden prototype only.
5. Scraping only as a last resort, and only after licence/terms review.

Do not use personal parking history to infer public parking supply.

## Required Source Fields

Record whether each field is available:

- provider/source name
- lot ID or car park number
- lot name
- address
- latitude
- longitude
- facility type
- capacity
- hourly rate
- day max
- night max
- weekend rate
- maximum time
- EV charging
- height restriction
- source URL
- source last updated date
- licence/terms URL

## Approval Checklist

- [ ] Source is official or clearly reliable.
- [ ] Licence/terms allow in-app display.
- [ ] Licence/terms allow bundled or cached static data.
- [ ] Source update date is known or stale-data risk is accepted.
- [ ] Coordinates are present and usable.
- [ ] At least 10 sampled lots are manually compared against official Green P site/app/signage.
- [ ] Rate fields are either verified or intentionally omitted.
- [ ] Source attribution wording is approved.
- [ ] Stale-data warning wording is approved.
- [ ] No real-time availability claim is present.

## Rejected / Not Production-Ready Findings

From Phase 2 research:

- Toronto Open Data `parking-lot-facilities` is not a current Green P commercial parking inventory. It appears to cover Parks, Forestry & Recreation lots and has older metadata, so it must not be treated as production Green P truth.
- Green P web pages are useful for context and manual verification, but no official public app API was confirmed in the prior research pass.
- Toronto 311 Green P pages are useful secondary references, not a structured parking catalog.

## Source Decision Template

Use this section when a candidate source is reviewed.

```text
Source name:
Source URL:
Licence/terms URL:
Reviewed date:
Reviewer:
Approval status: approved / rejected / hidden prototype only
Reason:
Available fields:
Missing fields:
Manual sample result:
Allowed app usage:
Required attribution:
Required warning:
Notes:
```


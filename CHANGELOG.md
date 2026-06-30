# Changelog

## [0.3.6] - 2026-06-30

### Changed

- Updated `fair_champion_harvester` dependency to `~> 0.1.14`, which fixes a critical cache collision bug: `Cache.checkRDFCache` was matching on byte-count instead of MD5 hash, causing wrong RDF graphs to be returned for unrelated resources after days of accumulated cache files. Symptom was completely incorrect metadata (from a different dataset) being returned, disappearing on service restart. Fixed by keying the cache lookup directly on `MD5(body)`, consistent with the write path.

## [0.3.5] - 2026-06-30

### Changed

- Updated `fair_champion_harvester` dependency to `~> 0.1.13`, which fixes JSON-LD context expansion: remote `@context` URLs (e.g. `http://schema.org`) are now resolved during parsing so that `@type: @id` coercions are applied correctly. Properties like `schema:license` now produce IRI resources rather than string literals, allowing FAIR license assessment tests to pass for datasets such as ESRF DOIs.

## [0.3.4] - 2026-05-27

- Previous release.

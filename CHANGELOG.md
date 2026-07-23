# Changelog

## [0.4.0] - 2026-07-23

### Changed

- `fc_searchable` and `test_FM_F4_M_MetaIndexed` now query a self-hosted SearXNG metasearch instance instead of the paid Microsoft Bing Web Search API, removing per-query billing and the `BING_API` key requirement. `docker-compose.yml` now runs a `searxng` service alongside `tests`.
- Both tests now build the list of candidate resource URIs (`target_uris`) once from the harvested metadata plus the tested GUID, fixing a latent bug where an unassigned `finalURI` local variable would raise `NoMethodError` as soon as a search engine returned results.
- SearXNG request failures (unreachable service, non-2xx response, unparseable JSON) are now raised as `SearxngError` and caught around the whole search flow, so a backend outage now yields an `indeterminate` result instead of an unhandled 500.

### Removed

- The `BING_API` environment variable and the Bing-calling code paths (`callBing`/`callBing2`) are gone; `BING_API` is no longer read anywhere.

## [0.3.6] - 2026-06-30

### Changed

- Updated `fair_champion_harvester` dependency to `~> 0.1.14`, which fixes a critical cache collision bug: `Cache.checkRDFCache` was matching on byte-count instead of MD5 hash, causing wrong RDF graphs to be returned for unrelated resources after days of accumulated cache files. Symptom was completely incorrect metadata (from a different dataset) being returned, disappearing on service restart. Fixed by keying the cache lookup directly on `MD5(body)`, consistent with the write path.

## [0.3.5] - 2026-06-30

### Changed

- Updated `fair_champion_harvester` dependency to `~> 0.1.13`, which fixes JSON-LD context expansion: remote `@context` URLs (e.g. `http://schema.org`) are now resolved during parsing so that `@type: @id` coercions are applied correctly. Properties like `schema:license` now produce IRI resources rather than string literals, allowing FAIR license assessment tests to pass for datasets such as ESRF DOIs.

## [0.3.4] - 2026-05-27

- Previous release.

# Changelog

The noteworthy changes for each Apartmentex version are included here. For a
complete changelog, see the git history for each version via the version links.

**To see the dates a version was published see the [hex package page].**

[hex package page]: https://hex.pm/packages/apartmentex

## [Since 0.2.0]

### Changed

- `Apartmentex.migrate_tenant` function added to migrate a single tenant up or down.

[Since 0.2.0]: https://github.com/Dania02525/apartmentex/compare/v0.2.0...master

## [0.2.0]

### Changed

- `Apartmentex.Migration` removed - should `use Ecto.Migration` in tenant
  migrations now
- Now supports (and requires) Ecto 2.0.x

[0.2.0]: https://github.com/Dania02525/apartmentex/compare/v0.1.0...v0.2.0

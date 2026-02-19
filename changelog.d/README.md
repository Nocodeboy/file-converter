# Changelog Fragments

To reduce merge conflicts in `CHANGELOG.md`, contributors should add release notes as small fragment files instead of editing `CHANGELOG.md` directly in feature branches.

## How to add a note

Create a new file in this folder using this naming convention:

`YYYYMMDD-<short-topic>.md`

Example:

`20260219-zip-download-reliability.md`

Use sections similar to:

```md
### Fixed
- Improved ZIP reliability for large batches in the web app.
```

At release time, maintainers can merge/curate these fragments into `CHANGELOG.md`.

# ClickHouse BYOC Onboarding Terraform Modules

This repository contains Terraform module to bootstrap a BYOC environment for ClickHouse Cloud.

See terraform modules for supported cloud:

- [AWS](./modules/aws/)
- [GCP](./modules/gcp/)
- [Azure](./modules/azure/)

## Releases

Every push to `main` that changes `modules/**` is released automatically as a
single repository-wide `vMAJOR.MINOR.PATCH` tag covering all modules. The bump is
derived from the conventional-commit subjects merged since the last release:
`feat!` or a `BREAKING CHANGE` footer gives a major, `feat` a minor, anything
else a patch. Changes limited to module `README.md` files do not trigger a
release.

Label a PR to override that decision:

| Label | Effect |
| --- | --- |
| `release:major` / `release:minor` / `release:patch` | Force that bump instead of the one inferred from commits |
| `release:patch` | Also releases a docs-only change |
| `release:skip` | Do not release this change; it ships with the next release |

Tagging a commit by hand still works — the automation skips any commit that
already has a `v*` tag, so cut a release manually when it needs curated notes.


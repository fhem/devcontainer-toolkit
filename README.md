# FHEM Devcontainer Toolkit

This toolkit centralizes the reusable parts of a FHEM module development
environment:

- base container image and compose wiring
- runtime bootstrap and overlay logic
- optional add-ons such as SVN support
- scaffold and sync helpers for consuming repositories

Module-specific reverse proxies are intentionally out of scope for the toolkit
core. If a consumer needs `Caddy` or a similar proxy for a module-specific
workflow, keep that proxy config in the consumer repository instead of the
shared scaffold.

The toolkit is meant to be maintained centrally and consumed by module
repositories through the sync script in `sync/`.

## Public Interface

The generated consumer layer uses these environment variables:

- `MODULE_REPO_ROOT`: absolute path to the consumer repository
- `MODULE_OVERLAY_ROOT`: optional root containing `FHEM/`, `lib/`, `t/`, etc.
- `FHEM_TOOLKIT_ROOT`: absolute path to this toolkit checkout
- `FHEM_SOURCE_ROOT`: full FHEM source tree used as the runtime base
- `FHEM_TOOLKIT_FEATURES`: optional comma-separated add-ons
- `FHEM_SVN_ROOT`: optional SVN working copy root for the SVN add-on
- `LOCAL_USER` / `LOCAL_UID` / `LOCAL_GID`: optional local overrides for the
  generic container user (defaults: `dev`, `1000`, `1000`)

`FHEM_SOURCE_ROOT` defaults to `${MODULE_REPO_ROOT}/fhem` so full-tree
repositories continue to work. Module-only repositories should set it to an
external FHEM checkout.

## Layout

- `base/`: generic Dockerfile, compose wiring, bootstrap, helper scripts
- `addons/svn/`: optional SVN checkout and sync helpers
- `scaffold/templates/`: managed file templates for consumer repositories
- `sync/`: repo sync entrypoint

The toolkit installs generic Perl dependencies from its own `cpanfile`. The
scaffolded consumer Dockerfile also installs an additional root-level `cpanfile`
when the repository provides one, so repo-specific Perl dependencies can stay
with the consumer code.

## Recommended Flow

1. Clone the toolkit next to the consumer repository.
2. Create or clone the consumer repository.
3. Run `sync/sync-into-repo.sh <target-repo>`.
4. Add the repo-specific layer such as profiles, config, SVN manifest, and any
   host-specific mounts like `.gitconfig`.

## Consumption Model

Run `sync/sync-into-repo.sh <target-repo>` to initialize or update a consumer
repository. Generated files are intentionally thin and resolve the toolkit from
the consumer's sibling checkout `../fhem-devcontainer-toolkit` unless
`FHEM_TOOLKIT_ROOT` overrides that location.

Sync preserves existing `.gitignore` entries and appends the toolkit defaults
instead of overwriting repo-local ignore rules.

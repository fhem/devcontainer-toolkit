# FHEM Devcontainer Toolkit

This toolkit centralizes the reusable parts of a FHEM module development
environment:

- base container image and compose wiring
- runtime bootstrap and overlay logic
- optional add-ons such as SVN support
- scaffold and sync helpers for consuming repositories

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

`FHEM_SOURCE_ROOT` defaults to `${MODULE_REPO_ROOT}/fhem` so full-tree
repositories continue to work. Module-only repositories should set it to an
external FHEM checkout.

## Layout

- `base/`: generic Dockerfile, compose wiring, bootstrap, helper scripts
- `addons/svn/`: optional SVN checkout and sync helpers
- `scaffold/templates/`: managed file templates for consumer repositories
- `sync/`: repo sync entrypoint

## Consumption Model

Run `sync/sync-into-repo.sh <target-repo>` to initialize or update a consumer
repository. Generated files are intentionally thin and resolve the toolkit from
the consumer's sibling checkout `../fhem-devcontainer-toolkit` unless
`FHEM_TOOLKIT_ROOT` overrides that location.

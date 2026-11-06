# pohunek-plugin-index

The list of plugins that install by id with `pohunek plugin install <id>`.

- `official/<package_id>/<version>.toml` holds one admitted version. A pull
  request adds a file or deletes one (de-admission); it never modifies or
  renames an admitted file.
- `CORE_TAG` pins the Pohunek core release whose `xtask` runs the admission
  checks and whose daemon archive proves each entry.
- `scripts/admit` and `.github/workflows/admission.yml` prove every added entry.
  The `admission / verdict` check is required on `main`.
- `keys/official.record.json` and `revocations/revocations.json` hold the
  public key material of the index signing key; they change only through a
  reviewed pull request that the `material` job verifies.

An entry file lists the signed fields (`package_id`, `runtime_id`, `version`,
`digest`, `url`, `platforms`, `core`) and a `[source]` table (`repo`, `repo_id`,
`tag`, `commit`, `built_with`). The format and the admission steps are described
in the Pohunek guide "Plugin repositories".

Admission never builds the pull request's own code before the checks that
involve only the pinned core have passed, and the workflow has no secrets.
Changes to `scripts/` and `.github/` run from the pull request itself, so a
reviewer reads them before approving.

Required repository settings (ruleset on `main`): the `admission / verdict`
check, a pull request with a CODEOWNERS review, stale approvals dismissed,
approval of the most recent push, and branches up to date before merging. The
check is only as strong as that review, because a pull request runs its own
copy of the workflow and of `scripts/admit`.

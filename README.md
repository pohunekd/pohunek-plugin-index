# pohunek-plugin-index

The list of plugins that install by id with `pohunek plugin install <id>`.

- `official/<package_id>/<version>.toml` holds one admitted version. A pull
  request adds a file or deletes one (de-admission); it never modifies or
  renames an admitted file.
- `CORE_TAG` pins the Pohunek core release whose `xtask` runs the admission
  checks and whose daemon archive proves each entry.
- `scripts/admit` and `.github/workflows/admission.yml` prove every added entry.
  The `admission / verdict` check is required on `main`.
- `scripts/sign-build` and `.github/workflows/sign.yml` sign and publish the
  official index every day: schema 1 (`official-index-v1.json`, runtime
  entries only) beside schema 2 (`official-index-v2.json`, runtime and
  context entries), under the same key and sequence. The key reaches only
  the runner's `openssl` in the `sign` job; every other job is keyless.
  Publishing stays off until the owner sets the repository variable
  `INDEX_PUBLISH_ENABLED` to `true` (after the key ceremony). Until then
  the schedule and pushes stay green and publish nothing.
- `keys/official.record.json` and `revocations/revocations.json` hold the
  public key material of the index signing key; they change only through a
  reviewed pull request that the `material` job verifies.

An entry file lists the signed fields (`package_id`, `runtime_id`, `version`,
`digest`, `url`, `platforms`, `core`) and a `[source]` table (`repo`, `repo_id`,
`tag`, `commit`, `built_with`). A `context` entry names `kind = "context"` and
no `runtime_id`; the v1 document then omits it while the v2 document lists it.
The format and the admission steps are described
in the Pohunek guide "Plugin repositories".

A package submitted to the official index must live in `package/`: index
admission rebuilds the archive from the `package` directory and refuses any
other layout (`scripts/admit`, the "5 package-dir" check).

Admission never builds the pull request's own code before the checks that
involve only the pinned core have passed, and the workflow has no secrets.
Changes to `scripts/` and `.github/` run from the pull request itself, so a
reviewer reads them before approving.

Required repository settings (ruleset on `main`): the `admission / verdict`
check, a pull request with a CODEOWNERS review, stale approvals dismissed,
approval of the most recent push, and branches up to date before merging. The
check is only as strong as that review, because a pull request runs its own
copy of the workflow and of `scripts/admit`.

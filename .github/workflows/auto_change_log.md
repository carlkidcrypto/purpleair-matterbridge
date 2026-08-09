---
name: Update Changelog
concurrency:
  group: ${{ github.workflow }}
  cancel-in-progress: false
on:
  release:
    types: [published]
  workflow_dispatch:
    inputs:
      tag:
        description: Optional release tag to document
        required: false
        type: string
  skip-if-match:
    query: 'is:pr is:open head:automation/update-changelog label:documentation label:automated-pr'
permissions:
  copilot-requests: write
  actions: read
  contents: read
safe-outputs:
  create-pull-request:
    title-prefix: "[changelog] "
    labels: [documentation, automated-pr]
    draft: false
    preserve-branch-name: true
    if-no-changes: "ignore"
    base-branch: main
    protected-files: allowed
timeout-minutes: 30
engine:
  id: copilot
model: claude-sonnet-5
network:
  allowed: [defaults, github]
tools:
  bash: true
---

# Smart Changelog Update

Generate and open a changelog update PR only when substantive changelog content
has changed.

## Goals

- Keep `CHANGELOG.md` synchronized with git tags and commits using `git-chglog`.
- Avoid noise PRs when only the generated timestamp or header differs.
- Use one long-lived `automation/update-changelog` branch for easy updates.
- Produce useful summaries from local commit titles and release metadata.
- Remain functional when external commit APIs are unavailable by using local git
  history.

## Steps

1. Prepare tooling and history.

   - Ensure the checkout contains full git history and tags. Use local git data
     for commit analysis. Do not call GitHub commit-reading APIs or tools.
   - If `git-chglog` is missing, install v0.15.4 using its pre-built binary:

     ```bash
     curl -sSfL https://github.com/git-chglog/git-chglog/releases/download/v0.15.4/git-chglog_0.15.4_linux_amd64.tar.gz \
       | tar xz -C /usr/local/bin git-chglog
     ```

   - If that download fails, fall back to:

     ```bash
     go install github.com/git-chglog/git-chglog/cmd/git-chglog@latest
     ```

   - Verify the installation with `git-chglog --version`. If neither install
     method works, stop with a clear error. Do not reimplement `git-chglog` in
     another language or script.

2. Generate candidate content:

   ```bash
   git-chglog --config .chglog/config.yml -o CHANGELOG.tmp
   ```

3. Determine the comparison range.

   - For a published release, use its tag and prerelease state from the release
     payload. For `workflow_dispatch`, use the supplied `tag`, then the current
     tag or `HEAD` when no input is supplied.
   - Select the base in this order:
     1. A release-body marker `<!-- BASE_TAG: <tag> -->`, when present.
     2. The most recent earlier stable release for a stable release.
     3. The most recent earlier release, stable or prerelease, for a prerelease.
     4. The nearest lower semantic-version tag available locally.
     5. The repository root commit from `git rev-list --max-parents=0 HEAD`.
   - Never select a prerelease as the base for a stable release when an earlier
     stable release exists. If base and current are equal, walk backward to the
     next available release/tag.
   - Extract commit titles with one local command:

     ```bash
     git log <base>..<current> --pretty=format:"%s"
     ```

   - Log the selected range as `Changelog range: <base>...<current>`. Use those
     commit titles to summarize meaningful changes and mention referenced PR or
     issue numbers when available.

4. Detect substantive changes.

   - If the existing `CHANGELOG.md` begins with `Last Updated:`, compare the
     generated content after removing the first two lines from the old file.
   - Otherwise compare against the complete existing file.
   - If there is no substantive difference, stop without creating or updating a
     PR.

5. Build the updated `CHANGELOG.md`.

   - Add `Last Updated: <UTC timestamp>` as the first line.
   - Add one blank line.
   - Append the generated body from `CHANGELOG.tmp`.
   - Only modify `CHANGELOG.md`; do not commit `CHANGELOG.tmp`.

6. Create or update the pull request.

   - Branch: `automation/update-changelog`
   - Base: `main`
   - Title: `Update CHANGELOG.md`
   - Commit message: `chore(docs): update changelog`
   - The PR body must include the trigger source, whether a release tag was
     involved, the explicit comparison range, notable top-level changelog
     sections, a concise summary derived from the single `git log` result,
     notable PR/issue references when available, and a note that timestamp-only
     changes are filtered out.

## Constraints

- Only modify `CHANGELOG.md`.
- Do not make unrelated code, documentation, or workflow edits.
- If required tags or history are unavailable, report the problem and stop.
- Prefer user-impacting changes over dependency and CI churn when both exist.
- Do not fail solely because external commit APIs are blocked; use local git
  history instead.
- Never reimplement `git-chglog`. If it cannot be installed, stop clearly.

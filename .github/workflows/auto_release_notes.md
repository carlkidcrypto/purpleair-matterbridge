---
name: Auto Update Release Notes
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: false
on:
  release:
    types: [published]
  workflow_dispatch:
    inputs:
      backfill_all:
        description: Backfill release notes for ALL existing releases
        required: false
        default: 'false'
        type: boolean
      additional_context:
        description: Optional extra context to incorporate into every release note
        required: false
        default: ''
        type: string
permissions:
  actions: read
  contents: read
  copilot-requests: write
safe-outputs:
  update-release: {}
timeout-minutes: 60
engine:
  id: copilot
model: claude-sonnet-5
network:
  allowed: [defaults, github, node]
tools:
  bash: true
---

# Auto Update Release Notes

When a new release is published, generate and update its GitHub release notes
from local git history, commit paths, and available PR or issue references.

## Goals

- Produce high-signal, human-readable notes for every tagged release.
- Group changes into themes relevant to this TypeScript Matter plugin and its
  combined Docker runtime.
- Include npm installation and Docker image guidance for the released version.
- Fully overwrite the release body unless it contains `<!-- PROTECTED -->`.
- Support serial backfilling of existing releases while respecting protected
  releases.

## Steps

0. Determine the run mode.

   - For `release: published`, process only the triggering release tag.
   - For `workflow_dispatch` with `backfill_all: true`, fetch all releases using
     the GitHub API and process them oldest first.
   - For `workflow_dispatch` with `backfill_all: false`, process only the most
     recently published release.
   - If `additional_context` is non-empty, apply it as supplemental context to
     every release without echoing it verbatim.

1. Identify release context.

   - Determine the tag and prerelease state from the GitHub release object.
   - Derive the npm version by stripping a leading `v` from the tag. If there is
     no leading `v`, use the tag as-is.
   - Construct these release links:
     - npm: `https://www.npmjs.com/package/purpleair-matterbridge/v/<version>`
     - Docker Hub: `https://hub.docker.com/r/carlkidcrypto/purpleair-matterbridge-images/tags`
     - GHCR: `https://github.com/carlkidcrypto/purpleair-matterbridge/pkgs/container/purpleair-matterbridge`
   - Select the base tag in this order:
     1. A release-body marker `<!-- BASE_TAG: <tag> -->`, when present.
     2. The most recent earlier stable release for a stable release.
     3. The most recent earlier release, stable or prerelease, for a prerelease.
     4. The nearest lower semantic-version tag available from local git tags.
     5. The repository root commit from `git rev-list --max-parents=0 HEAD`.
   - Never choose a prerelease as the base for a stable release when an earlier
     stable release exists. If base and current are equal, walk backward once
     more and log the selected value as:
     `Selected base for <current_tag>: <base_tag_or_root_commit>`.

2. Extract the release range from local history.

   - Use full local history and tags. Do not use GitHub commit-reading APIs for
     changelog intelligence.
   - Run:

     ```bash
     git log <base_tag_or_root>..<current_tag> --pretty=format:"%H %s"
     ```

   - For each commit, retrieve its body with `git log -1 --pretty=format:"%b" <hash>`
     and changed paths with `git show --name-only --pretty="" <hash>`.
   - Collect PR and issue references such as `(#123)`, `#123`, `Closes #123`,
     `Fixes #123`, and `Resolves #123`.
   - If history is unavailable or the range is empty, continue with a minimal
     release note containing the computed comparison context and release links.

3. Group commits into themes.

   Use these categories, omitting empty sections:

   - **Features / Enhancements**: new Matter endpoints, logger modes, controls,
     or meaningful user-facing improvements.
   - **Bug Fixes**: corrections to plugin behavior, commissioning, networking,
     logging, or update behavior.
   - **Runtime / Plugin**: PurpleAir client, endpoint, Matterbridge module, and
     TypeScript runtime changes.
   - **Containers / Packaging**: Docker images, persistent volumes, image tags,
     npm packaging, and release artifacts.
   - **Tests**: unit tests and validation coverage.
   - **CI / Workflows**: GitHub Actions and build or publishing automation.
   - **Documentation**: README, Sphinx, troubleshooting, platform, and release
     documentation.
   - **Dependencies**: package, lockfile, Node, Python, Matterbridge, or logger
     version changes.
   - **Chores / Misc**: refactoring, formatting, and remaining maintenance.

   Infer categories from both commit metadata and changed paths. Prefer the
   user-impacting category when signals disagree and mention secondary impact
   in the bullet text. Keep CI and dependency churn concise.

4. Build the release body.

   Start with a one- or two-sentence summary emphasizing user-facing changes,
   followed by `Compared to: <base_tag_or_root_commit>`. Include this install
   and image section immediately afterward:

    ````markdown
   ## Install / Upgrade

   ```bash
   npm install purpleair-matterbridge@<npm_version>
  ```

   npm package: https://www.npmjs.com/package/purpleair-matterbridge/v/<npm_version>

   ## Container Images

   ```bash
   docker pull carlkidcrypto/purpleair-matterbridge-images:<immutable_tag>
   ```

   Docker Hub: https://hub.docker.com/r/carlkidcrypto/purpleair-matterbridge-images/tags
   GHCR: https://github.com/carlkidcrypto/purpleair-matterbridge/pkgs/container/purpleair-matterbridge
  ````

   Then add each non-empty theme as `## <Theme>` with bullets. Rewrite terse
   commit titles into natural language and include PR links as `(#NNN)` when
   available. End with:

   ```markdown
   ---
   **Full Changelog**:
   https://github.com/carlkidcrypto/purpleair-matterbridge/compare/<base_tag>...<current_tag>
  ```

   For the Docker command, use the immutable release tag produced by
   `build_and_publish_docker_images.yml` when it is available. Do not invent a
   `latest` tag because this repository publishes immutable image tags only.

5. Update the GitHub release.

   - Fetch the current release body before writing.
   - If it contains the exact string `<!-- PROTECTED -->`, skip it and log:
     `Skipping <tag>: marked <!-- PROTECTED -->`.
   - Otherwise fully overwrite the release body through the GitHub release API;
     do not preserve or merge previous body content.
   - In published-release mode, update only the triggering release.
   - In backfill mode, process releases serially and add a short delay if API
     throttling is detected.

## Release Notes Body Format

````markdown
<One or two sentence summary.>

Compared to: <base_tag_or_root_commit>

## Install / Upgrade

```bash
npm install purpleair-matterbridge@<npm_version>
```

npm package: https://www.npmjs.com/package/purpleair-matterbridge/v/<npm_version>

## Container Images

```bash
docker pull carlkidcrypto/purpleair-matterbridge-images:<immutable_tag>
```

Docker Hub: https://hub.docker.com/r/carlkidcrypto/purpleair-matterbridge-images/tags
GHCR: https://github.com/carlkidcrypto/purpleair-matterbridge/pkgs/container/purpleair-matterbridge

## Features / Enhancements
- <human-readable change summary> (#PR or short hash)

## Bug Fixes
- <human-readable change summary> (#PR or short hash)

## Runtime / Plugin
- <human-readable change summary> (#PR or short hash)

## Containers / Packaging
- <human-readable change summary> (#PR or short hash)

## Tests
- <human-readable change summary> (#PR or short hash)

## CI / Workflows
- <human-readable change summary> (#PR or short hash)

## Documentation
- <human-readable change summary> (#PR or short hash)

## Dependencies
- <human-readable change summary> (#PR or short hash)

## Chores / Misc
- <human-readable change summary> (#PR or short hash)

---
**Full Changelog**:
https://github.com/carlkidcrypto/purpleair-matterbridge/compare/<base_tag>...<current_tag>
````

## Constraints

- Always fully overwrite the release body unless it contains
  `<!-- PROTECTED -->`.
- Never modify a protected release.
- Do not push commits, open PRs, or modify repository files.
- In published-release mode, update only the triggering release.
- In backfill mode, update all releases returned by the API except protected
  releases.
- Omit empty theme sections.
- Never choose a prerelease base for a stable release when an earlier stable
  release exists.
- If the npm version cannot be derived from the tag, omit the install section
  and explain the omission in the job log.
- Use repository-aware language: mention Matterbridge, PurpleAir logger modes,
  Matter air-quality endpoints, commissioning persistence, mDNS/networking,
  Docker host networking, and controller compatibility when those areas change.

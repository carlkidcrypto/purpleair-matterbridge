---
name: Docs Continuous Improvement Every 3 Days
on:
  workflow_dispatch:
  schedule: every 3 days
  skip-if-match:
    query: 'is:pr is:open head:automation/docs-continuous-improvement label:documentation label:automated-pr'
permissions:
  copilot-requests: write
  actions: read
  contents: read
safe-outputs:
  create-pull-request:
    title-prefix: "[docs-improvement] "
    labels: [documentation, automated-pr]
    draft: true
    preserve-branch-name: true
    if-no-changes: "ignore"
    base-branch: main
    protected-files: allowed
timeout-minutes: 45
engine:
  id: copilot
model: claude-sonnet-5
network:
  allowed: [defaults, github]
tools:
  bash: true
---

# Documentation Continuous Improvement

Review and improve this repository's documentation gradually over time. Keep
individual runs small, focused, and easy to review.

## Scope

Audit and improve, when a meaningful issue is found:

- `README.md`
- `CHANGELOG.md`, without rewriting historical release entries
- `Requirements.rst`
- `PLATFORMS-TESTED.md`
- `TROUBLESHOOTING-WINDOWS-WSL.md`
- `TROUBLESHOOTING-LINUX.md`
- Source documentation under `sphinx_docs_build/source/`, including `.rst`,
  configuration, and landing-page content
- Public TypeScript docstrings and comments in `src/`, when they are incorrect,
  incomplete, or materially unclear
- Documentation-specific workflow or release instructions only when they are
  inaccurate; do not broaden the change into workflow redesign

Do not audit or edit generated output such as `docs/html/`, `docs/html_*`, build
artifacts, `dist/`, `node_modules/`, or package-lock files unless the change is
strictly required by a documentation-only correction. Do not edit source code,
Dockerfiles, runtime configuration, or tests as part of this workflow.

## Goals

- Fix typos, grammar, broken links, and unclear wording.
- Correct inaccurate instructions, commands, paths, version references, and
  platform assumptions.
- Keep npm, Docker, Matterbridge, PurpleAir logger, Matter commissioning,
  mDNS/networking, firewall, IPv6, controller-sharing, and cron guidance aligned
  with the current implementation.
- Improve clarity where a reader could make an unsafe or destructive mistake,
  especially around `--fdr`, persistent volumes, commissioning state, firewall
  rules, and Docker image tags.
- Keep examples privacy-safe by retaining placeholders such as
  `FULL_PATH_TO_SCRIPT`, `FULL_PATH_TO_SETTINGS_FILE`, and
  `YOUR_LAN_INTERFACE`.
- Keep edits small and focused. Prefer correcting existing text over adding
  broad new sections.

## Review Method

1. Read the relevant source and nearby implementation before changing wording.
2. Check commands, filenames, options, package versions, image names, and links
   against the current repository. Do not claim behavior that the code does not
   implement.
3. Prefer repository-local evidence. Inspect `src/`, `package.json`, Docker
   files, workflow files, and Sphinx configuration as needed.
4. For Sphinx changes, preserve the existing structure and avoid generated
   output. When practical, run the same strict build used by the documentation
   workflow:

   ```bash
   cd sphinx_docs_build
   make clean
   make html SPHINXOPTS="-W"
   ```

5. Make only documentation edits. If no meaningful improvement is found, do not
   edit files and do not open a PR.

## Constraints

- Do not change API behavior, runtime logic, build behavior, or test behavior.
- Do not perform broad rewrites, style-only churn, or speculative documentation.
- Do not change generated artifacts or versioned documentation snapshots.
- Do not expose personal paths, IP addresses, hostnames, interfaces, tokens, or
  other environment-specific values.
- Preserve public commands and links unless the existing documentation is wrong;
  update them to match the actual repository when necessary.
- Only modify documentation files relevant to the selected improvement.
- Do not modify this workflow or other automation as part of its normal run.

## Pull Request

If changes are made, create or update one draft PR:

- Branch: `automation/docs-continuous-improvement`
- Base: `main`
- Title style: `[docs-improvement] <short summary>`
- Commit message: `docs: improve documentation`

The PR body must include:

- Files updated
- The types of improvements made, such as typos, corrections, clarifications,
  link fixes, command validation, or docstring improvements
- Any follow-up documentation gaps discovered
- Confirmation that no runtime or generated-artifact changes were made

If a meaningful documentation issue cannot be corrected confidently from local
repository evidence, leave it unchanged and describe it as a follow-up gap in
the PR body only when another documentation change is being proposed.

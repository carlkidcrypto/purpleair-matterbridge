# Bash Scripts

This folder contains repository maintenance scripts that are not part of the
runtime package.

## Release Preparation

Use `release.sh` to prepare a new project release:

```bash
bash bash_scripts/release.sh VERSION
```

Example:

```bash
bash bash_scripts/release.sh 1.0.7
```

The script:

1. Updates the version in `package.json` and `package-lock.json`.
2. Updates the current Sphinx release and documentation link.
3. Runs formatting and the formatting check.
4. Runs the JavaScript/TypeScript linter.
5. Runs the TypeScript typecheck.
6. Runs the test suite.
7. Builds the package.

The version must use semantic-version format, such as `1.0.7` or
`1.0.7-rc.1`.

The script does not update `CHANGELOG.md`, commit changes, create tags, push to
the remote, or publish to npm. Review the resulting diff and complete those
release steps separately.

# Bash Scripts

This folder contains repository maintenance scripts that are not part of the
runtime package.

## Release Preparation

Use `release.sh` to prepare a new project release:

```bash
bash bash_scripts/release.sh VERSION [LOGGER_VERSION]
```

Examples:

```bash
# Bump project package version only
bash bash_scripts/release.sh 1.1.0-alpha.1

# Bump project package version and update purpleair-data-logger dependency together
bash bash_scripts/release.sh 1.1.0-alpha.1 1.6.0a0
```

The script:

1. Optionally invokes `bump_purpleair_data_logger.sh` if `LOGGER_VERSION` is specified.
2. Updates the version in `package.json` and `package-lock.json`.
3. Updates the version in `purpleair-matterbridge.config.json`.
4. Updates the Sphinx release version in `sphinx_docs_build/source/conf.py`.
5. Runs formatting and the formatting check.
6. Runs the JavaScript/TypeScript linter.
7. Runs the TypeScript typecheck.
8. Runs the test suite.
9. Builds the package.

The version must use semantic-version format, such as `1.0.7`, `1.1.0-alpha.1`, or
`1.0.7-rc.1`.

The script does not update `CHANGELOG.md`, commit changes, create tags, push to
the remote, or publish to npm. Review the resulting diff, create a pull request,
and complete release steps separately.

## PurpleAir Data Logger Dependency Bump

Use `bump_purpleair_data_logger.sh` to update the pinned `purpleair-data-logger`
dependency independently:

```bash
bash bash_scripts/bump_purpleair_data_logger.sh LOGGER_VERSION
```

Example:

```bash
bash bash_scripts/bump_purpleair_data_logger.sh 1.6.0a0
```

The script:

1. Updates `purpleair-data-logger==<VERSION>` in `docker/requirements.txt`.
2. Updates Docker container tag examples and expected version output in `README.md`.
3. Updates Docker container tag examples and expected version text in `TROUBLESHOOTING-WINDOWS-WSL.md`.
4. Runs code and markdown formatting checks (`npm run format`).

The script does not commit changes or push to the remote. Review the git diff and
submit changes via a pull request.

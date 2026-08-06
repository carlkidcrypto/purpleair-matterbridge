Publishing to npm
==================

This project publishes the public npm package ``purpleair-matterbridge``.
Matterbridge is intentionally not included as a package dependency because the
plugin must use the host Matterbridge installation and its Matter.js instance.

Prerequisites
-------------

Before publishing, make sure:

* Node.js 20.19, 22.13, 24, or 26 is installed.
* npm is current enough for the selected Node.js release.
* You have publish access to the ``purpleair-matterbridge`` npm package.
* You are working from a clean checkout on the branch intended for release.
* The package version in ``package.json`` has not already been published.

Authenticate with npm using the interactive login flow:

.. code-block:: bash

   npm login
   npm whoami

Do not put an npm access token directly into a committed file or command line.
For CI, store the token in the repository or organization secret used by the
publishing workflow rather than printing it in logs.

Validate locally
----------------

Install the locked development dependencies and run the same checks used by
publication:

.. code-block:: bash

   npm ci
   npm run typecheck
   npm test
   npm run build
   npm run lint
   npm run format:check

The package ``prepublishOnly`` hook automatically runs ``clean``, ``typecheck``,
``test``, and ``build`` during ``npm publish``. Running the checks explicitly
first gives faster feedback and also runs lint and formatting checks, which are
not part of the publish hook.

Inspect the package before publishing:

.. code-block:: bash

   npm pack --dry-run
   npm publish --dry-run

Confirm that the output contains the intended ``dist`` files, README, license,
configuration examples, schema files, and platform/troubleshooting documents.
Do not expect Matterbridge or Matter.js to appear in the package dependencies.

Choose the version
------------------

npm versions are immutable: once a version is published, it cannot be reused
for different contents. Update the version before publishing a new release.
For a normal release, use npm's version command, which updates ``package.json``
and ``package-lock.json`` and creates a Git commit and tag when run in a Git
repository:

.. code-block:: bash

   npm version patch
   # or: npm version minor
   # or: npm version major

For a prerelease, use an explicit prerelease identifier:

.. code-block:: bash

   npm version prerelease --preid=alpha

Review the generated version change and tag before pushing it. If the version
was changed manually instead, run ``npm install --package-lock-only`` and verify
that both package files contain the same version.

Publish the package
-------------------

From the release commit, publish the public package:

.. code-block:: bash

   npm publish --access public

The ``publishConfig.access`` setting already declares public access, but the
explicit flag makes the intent clear. npm will run ``prepublishOnly`` before
uploading the tarball. If any typecheck, test, or build command fails, npm will
stop without publishing.

Verify the registry result:

.. code-block:: bash

   npm view purpleair-matterbridge version
   npm view purpleair-matterbridge@<version> dist.tarball
   npm install --prefix /tmp/matterbridge-package-test \
     purpleair-matterbridge@<version>

Use a fresh temporary install when checking the package contents. Do not test
only from the repository checkout, because local ``src`` files and development
dependencies can hide packaging mistakes.

Release sequence
----------------

A recommended release sequence is:

#. Update code, tests, and documentation.
#. Run the local validation and ``npm pack --dry-run`` checks.
#. Run ``npm version`` to create the new package version, commit, and tag.
#. Push the release commit and tag to GitHub.
#. Publish the npm package with ``npm publish --access public``.
#. Create the matching GitHub release from the pushed tag.
#. Allow the documentation workflow to create the locked versioned docs pull
   request.
#. Merge the documentation pull request after reviewing the generated snapshot.

If a GitHub release is created before npm publication, the source tag and npm
registry can temporarily describe different release states. Publish the npm
package first, then create the GitHub release for the same version.

Troubleshooting
---------------

``You must be logged in to publish packages``
   Run ``npm login`` and verify the account with ``npm whoami``. Confirm that
   the account has publish access to the package name.

``403 Forbidden`` or ``cannot publish over previously published version``
   The version is already registered or the account lacks permission. Increase
   the package version; never overwrite a published version.

``npm publish`` fails during ``prepublishOnly``
   Run the failing command directly, such as ``npm run typecheck``, ``npm test``,
   or ``npm run build``. Fix the source or test failure and retry the same
   version only if npm did not publish it.

The package is not visible after a successful publish
   Check ``npm view purpleair-matterbridge@<version>`` against the public npm
   registry and verify that the install command uses the exact version.

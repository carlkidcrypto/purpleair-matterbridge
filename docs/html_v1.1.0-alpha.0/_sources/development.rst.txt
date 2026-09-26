Development Guide
=================

Local Sphinx build
------------------

Install the documentation dependencies and build the HTML output from the
repository root:

.. code-block:: bash

   cd sphinx_docs_build
   python3 -m pip install -r requirements.txt
   make clean
   make html SPHINXOPTS="-W"

The generated site is written to ``docs/html/``. Build warnings are treated as
errors in the command above, which catches broken references and malformed
reStructuredText before a change reaches GitHub Actions.

Versioned documentation
-----------------------

The GitHub Pages landing page is built from
``sphinx_docs_build/landing/source/index.rst``. It always links to the latest
site at ``docs/html/`` and lists locked release snapshots at
``docs/html_<release-tag>/``.

Publishing a GitHub release starts a workflow that builds the documentation
from the release tag, updates the landing-page version list between its
``VERSION_LIST_START`` and ``VERSION_LIST_END`` markers, and opens a pull
request containing the snapshot. Merge that pull request to preserve the
release documentation as the project evolves.

Code checks
-----------

Run the project checks from the repository root:

.. code-block:: bash

   npm run typecheck
   npm test
   npm run build
   npm run lint
   npm run format:check

Publishing
----------

The package's ``prepublishOnly`` hook runs type checking, tests, and the
production build before ``npm publish``. Matterbridge is intentionally not a
package dependency; local development links the host Matterbridge package so
the plugin and host share one Matter.js instance.
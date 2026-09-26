Requirements
============

The normative plugin requirements are maintained in the repository's
``Software-Requirements.rst`` file.

The plugin must:

* implement a Matterbridge ``DynamicPlatform``;
* preserve stable sensor identities across polling updates;
* isolate malformed sensors and preserve last-known-good values;
* expose the required air-quality and environmental Matter clusters; and
* pass type checking, builds, tests, linting, and formatting checks before
  release.

See the repository requirements file for the complete MBPA requirement set.
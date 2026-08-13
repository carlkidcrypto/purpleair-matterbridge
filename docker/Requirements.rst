purpleair-matterbridge Docker requirements
===========================================

Scope
-----

These requirements define the behavior of the combined Docker image and its
Compose-based runtime. ``SHALL`` and ``SHALL NOT`` are normative.

Image contents
--------------

PAMB-001
   The image SHALL be based on Ubuntu 26.04 or a compatible Linux base that
   provides the required Node.js and Python runtimes.

PAMB-002
   The image SHALL provide Node.js 26 and SHALL provide the latest npm and
   npx versions available when the image is built.

PAMB-003
   The image SHALL provide Python 3.14 for the PurpleAir data logger virtual
   environment.

PAMB-004
   The image SHALL install the pinned ``purpleair-data-logger`` release
   specified by ``docker/requirements.txt``.

PAMB-005
   The image SHALL install the pinned Matterbridge release specified by
   ``MATTERBRIDGE_VERSION``.

PAMB-006
   The image SHALL include the compiled ``purpleair-matterbridge`` plugin and
   SHALL register it with the Matterbridge installation at runtime.

PAMB-007
   The image SHALL define ``/usr/local/bin/docker-entrypoint`` as its
   container entrypoint.

Configuration
-------------

PAMB-010
   The image SHALL support local and remote PurpleAir logger modes. Local mode
   SHALL use ``-paa_local_sensor_request_json_file`` and remote mode SHALL use
   ``-paa_multiple_sensor_request_json_file``.

PAMB-011
   The runtime SHALL make the supplied host settings file available inside
   the container at ``/config/purpleair-settings.json``.

PAMB-012
   The settings file SHALL be mounted read-only.

PAMB-013
   The spin-up script SHALL require exactly one of the named ``--local`` or
   ``--remote`` options, SHALL require the host PurpleAir settings JSON file
   through ``--settings-file``, SHALL support the presence option ``--fdr``,
   and SHALL support ``--help``.

PAMB-014
   The spin-up script SHALL reject a missing, non-regular, or nonexistent
   settings file before starting Docker Compose.

PAMB-015
   The logger SHALL serve its Matter JSON feed on ``127.0.0.1:9855`` inside
   the container.

PAMB-016
   The registry update script SHALL require exactly one of the named
   ``--local`` or ``--remote`` options, SHALL require the host PurpleAir
   settings JSON file through ``--settings-file``, and SHALL support named
   ``--image-tag``, ``--image-repository``, the presence option ``--fdr``, and
   ``--help``.

PAMB-017
   The registry update script SHALL pull a complete immutable image tag before
   replacing the running container and SHALL NOT build the image locally.

PAMB-018
   The registry update script SHALL support GHCR by default and SHALL support
   Docker Hub when ``--image-repository`` is explicitly provided.

Networking and persistence
--------------------------

PAMB-020
   The runtime SHALL use host networking so Matter mDNS, IPv6, multicast, and
   UDP commissioning traffic can reach the local network.

PAMB-020A
   The Docker lifecycle scripts SHALL support an optional
   ``--mdns-interface`` value and SHALL pass it to Matterbridge as
   ``--mdnsinterface`` when provided.

PAMB-021
   The runtime SHALL expose Matter UDP ports 5540 and 5353 as declared by the
   image configuration.

PAMB-022
   The runtime SHALL persist the Matterbridge home directory, including
   commissioning state, in the ``matterbridge-data`` volume mounted at
   ``/data``. The logger data volume MAY be mounted below that path at
   ``/data/logger``.

PAMB-023
   The runtime SHALL persist logger data in the ``logger-data`` volume mounted
   at ``/data/logger``.

PAMB-024
   The container SHALL restart automatically unless explicitly stopped by the
   operator.

Security and lifecycle
----------------------

PAMB-030
   The main container processes SHALL run as the non-root ``matterbridge``
   user.

PAMB-031
   The image SHALL create and assign ownership of its writable application and
   data directories to the ``matterbridge`` user.

PAMB-032
   The runtime SHALL stop the PurpleAir logger when the container receives a
   termination signal.

PAMB-033
   The entrypoint SHALL start the logger before Matterbridge so the local feed
   is available when the bridge begins operation. It SHALL register the plugin
   before starting the long-running Matterbridge process and SHALL NOT pass the
   shutdown-only ``--add`` command to that process.

PAMB-034
   The entrypoint SHALL terminate with a non-zero status when the required
   logger configuration is unavailable.

PAMB-035
   On first startup, the entrypoint SHALL preserve Matterbridge console output
   containing the pairing QR URL and numerical manual pairing code in the
   container logs. The bridge SHALL remain running after plugin registration so
   those codes can be emitted.

PAMB-036
   The runtime SHALL NOT reset Matterbridge commissioning state during an
   ordinary restart, image pull, or container replacement.

PAMB-037
   The Docker lifecycle scripts SHALL perform a Matterbridge factory reset
   only when the operator explicitly passes ``--fdr``. The reset SHALL complete
   before the normal Matterbridge process starts and SHALL use the supported
   ``matterbridge --factoryreset`` command.

Build and verification
----------------------

PAMB-040
   The image SHALL be buildable from the repository root using
   ``docker/Dockerfile`` and the Compose build definition.

PAMB-041
   The Docker build SHALL compile the TypeScript plugin before the image is
   considered ready.

PAMB-042
   The image SHALL contain the exact ``purpleair-data-logger`` version pinned
   in ``docker/requirements.txt``.

PAMB-043
   The Compose configuration SHALL render successfully when supplied with a
   valid ``PURPLEAIR_SETTINGS_FILE`` path.

PAMB-044
   A production image verification SHALL inspect the image metadata and SHALL
   verify the installed logger package version from the logger virtual
   environment.

PAMB-045
   Published images SHALL use immutable tags containing the package version,
   source commit, workflow run ID, and run attempt.
Configuration
=============

The example configuration is in
``purpleair-matterbridge.config.json`` and its schema is in
``purpleair-matterbridge.schema.json``.

The supported settings are:

``feedUrl``
    HTTP or HTTPS URL for the Matter-shaped PurpleAir feed.
``pollIntervalSeconds``
    Positive integer interval between feed requests. The default is 60.
``requestTimeoutSeconds``
    Positive integer HTTP timeout. The default is 10.
``whiteList`` and ``blackList``
    Matterbridge device selection settings.
``unregisterOnShutdown``
    Whether registered endpoints should be removed during shutdown.

Docker
------

The combined container definition is in ``docker/``. It runs the logger and
Matterbridge together with host networking so Matter mDNS and UDP traffic can
reach the local network. Start it with exactly one of ``--local`` or
``--remote`` and provide ``--settings-file``. The scripts select the logger
arguments; do not set ``LOGGER_ARGS`` manually. See the repository README for
pairing, update, volume, and factory-reset procedures.
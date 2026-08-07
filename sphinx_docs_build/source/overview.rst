Overview
========

The project is a Matterbridge dynamic platform plugin. It polls the JSON feed
served by ``purpleair_data_logger`` and creates one stable Matter air-quality
endpoint for each accepted PurpleAir sensor.

The plugin does not implement Matter transport, discovery, commissioning, or
fabrics itself. Matterbridge remains the host runtime and owns those concerns.

Runtime requirements
--------------------

* Node.js 20.19, 22.13, 24, or 26
* Matterbridge 3.10.0 or newer
* A running PurpleAir Matter JSON feed
* IPv6 and mDNS connectivity for Matter commissioning

The default feed URL is ``http://127.0.0.1:9855/matter/sensors``.

Combined Docker runtime
-----------------------

The combined Docker image runs ``purpleair_data_logger`` and Matterbridge in
one container. Start it with exactly one logger mode:

.. code-block:: console

	./docker/spinup.sh --local --settings-file /absolute/path/to/local.json
	./docker/spinup.sh --remote --settings-file /absolute/path/to/remote.json

``--local`` selects ``-paa_local_sensor_request_json_file``. ``--remote``
selects ``-paa_multiple_sensor_request_json_file`` for API-backed settings.
The settings file is mounted read-only, the logger feed remains on
``127.0.0.1:9855``, and Matterbridge uses host networking for mDNS and UDP
commissioning. See the repository README and the Windows/WSL troubleshooting
guide for pairing, persistent volumes, updates, and factory reset.
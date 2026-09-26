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
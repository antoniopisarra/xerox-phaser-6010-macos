# Sharing

The utility opens macOS Sharing settings; it does not enable sharing, change firewall rules or install a server. Use macOS Printer Sharing if suitable for your other computers. The host Mac must stay on and reachable, and client driver requirements still apply. This has not been physically validated as part of this release.

A shared macOS queue is not sufficient evidence of iPhone/iPad AirPrint compatibility. Version 1.0.0 does not provide or advertise AirPrint. An AirPrint bridge would need an IPP service, truthful supported document/media/color capabilities, Bonjour records and end-to-end iOS testing. That work is outside this release.

Development has started on a separate [AirPrint bridge prototype](../airprint/README.md). Version 1.1.0 does not enable or install a sharing service; the prototype is source-only until iPhone/iPad acceptance tests and lifecycle controls are complete.

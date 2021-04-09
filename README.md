goplot
=========

goplot is a manager for chia farms written in bash!

Requirements
------------

- Linux (developed on Ubuntu 20.04)
- Prometheus for metrics datastore
- Grafana for metrics visualization
- Prometheus node_exporter with textfile collector for:
   - OS metrics
   - custom metrics

Uses
------------

You can use goplot to:

  1. Pace your parallel plotting
  2. Monitor eligible plots passing the plot filter
  3. Monitor your farm space
  4. Assess your XCH wins!

Scripts
------------

The goplot package consistes of the following shell scripts:

- goplot.sh is the main script and runs continuously in the background; calls tractor.sh to start new parallel plots according to your configuration
- tractor.sh is called by goplot.sh to start a new plot; logs details and sends annotations to Grafana
- diskhand.sh is run by cron every two minutes; keeps an eye on disk space and provides disks for tractor; takes disks out of rotation when filled
- farmerlog.sh runs continuously in the background; monitors the Chia log for eligible plots passing the plot filter, sends the data to prometheus
- goplot_collector.sh is run by cron every minute; sends custom goplot stats to prometheus
- getfarm_collector.sh is run by cron every minute; sends custom chia farm stats to prometheus

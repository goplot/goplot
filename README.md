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

- goplot.sh is the main script and runs continuously in the background and calls tractor.sh to start new parallel plots according to your configuration
- tractor.sh is called by goplot.sh to start a new plot and to log details and send annotations to Grafana
- diskhand.sh is run by cron every two minutes, its job is to keep an eye on disk space and provide disks for tractor, or take disks out of rotation when filled
- farmerlog.sh runs continuously in the background and monitors the Chia log for eligible plots passing the plot filter and send the data to prometheus
- goplot_collector.sh is run by cron every minute and sends custom goplot stats to prometheus
- getfarm_collector.sh is run by cron every minute and sends custom chia farm stats to prometheus

goplot
=========

goplot is a manager for chia farms written in bash!

Development of goplot was based on these principles:

  1. The core of Chia farming is basically file management operations, and Linux is the best general OS for filesystem management.
  2. Core bash tools already integrated into the Linux OS support most functions needed in a Chia farm.
  3. Bash and bash scripts are highly accessible for tool comprehension and modification by both beginners and seasoned Linux experts.
  4. Monitoring needs are best met using open source tools, supplemented with custom scripts to get the data into the data store.


Uses
------------

You can use goplot to:

  1. Automatically start and pace plots on your plotter.
  2. Monitor the performance of your parallel plotting.
  3. Monitor eligible plots passing the plot filter.
  4. Monitor your farm space.
  5. Assess your XCH wins!
  6. Inspire your own project.


Requirements
------------

- Linux
  - goplot was developed on Ubuntu 20.04
- Prometheus 
  - used for the metrics data store
- Grafana
  - used for metrics visualization
- Prometheus node_exporter with textfile collector for:
  - operating system and hardware metrics
  - custom metrics
- sponge (part of moreutils)
  - assists with custom metrics collection


Scripts Overview
------------

The goplot package consists of the following shell scripts:

- goplot.sh is the main script and runs continuously in the background; calls tractor.sh to start new parallel plots according to your configuration
- tractor.sh is called by goplot.sh to start a new plot; logs details and sends annotations to Grafana
- diskhand.sh is run by cron every two minutes; keeps an eye on disk space and provides disks for tractor; takes disks out of rotation when filled
- farmerlog.sh runs continuously in the background; monitors the Chia log for eligible plots passing the plot filter, sends the data to prometheus
- goplot_collector.sh is run by cron every minute; sends custom goplot stats to prometheus
- getfarm_collector.sh is run by cron every minute; sends custom chia farm stats to prometheus


Concepts
------------

Farms

goplot uses the concept of "farms" to distribute IO to different IO busses for the destination drives and for the temp drives. As goplot starts new plots it will rotate through each farm to distribute the IO load. Each farm is assigned a number in sequence starting at "1". This value is communicated to goplot by a drive's mount point under the root directory of that mount point. 

The expected mount point for temp drives is under /plot_temp and for destination drives is under /farm.

A common farm configuration is to have external USB destination drives attached to a combined plotter/farmer. If the system has both front and back USB 3.0 ports then they are likely on different IO busses to the mainboard, meaning plots can be copied over both at the same time without USB contention. If both busses are to be used for plot destinations then the plotter is configured with two destination farms. For example, two farms are reflected in the file system as:

  /farm/1
  /farm/2

Similarly, a common plotter configuration is to have multiple temp drives, each of which has dedicated PCIe lanes, and these are separate busses that can be used at the same time without IO contention. Some people may combine these in a mkadm RAID 0, others may want to use the individual drives. Either is supported by goplot, and if individual drives are used then each is designated as a different farm number in the file system as:

  /plot_temp/1
  /plot_temp/2

If the temp drives are combined into the same RAID0 then there is only one temp farm designated in the file system as:

  /plot_temp/1

Disks

Plot destination farms are made up of "disks" which are named at the time the drive is mounted to the farm directory. It is recommended that you adopt a simple naming standard such as "disk1, disk2, disk3" etc. Each disk should be mounted to the farm directory that designates the physical bus the drive is attached to. In the above example, let's say the farmer/plotter has two USB 3.0 busses, each connecting to a four-port USB hub, and each hub has three external drives attached. In this example odd-numbered disks are attached to farm 1 (hub 1) and even-numbered disks are attached to farm 2 (hub 2). This configuration would be represented in the file system as:

  /farm/1/disk1
  /farm/1/disk3
  /farm/1/disk5
  /farm/2/disk2
  /farm/2/disk4
  /farm/2/disk6

Plots Directory

Plots are contained in a plots directory for both temp and destination farms. This allows for easier deletion of tmp files that may be left over after a plot gets "stuck" and has to be killed at the process level. All disks need a plots directory and all temp farms need a plots directory. For example, a simple farmer/plotter with only one temp drive and only one destination drive would be represented in the filesystem as:

  /farm/1/disk1/plots
  /plot_temp/1/plots

Plot Logs Directory

The log output from each run of "chia plots create" is output to a logs directory on the destination drive. You may never need them, but who knows! This logs directory needs to be on each destination drive, such as:

  /farm/1/disk1/logs
  /farm/2/disk2/logs

Goplot Logs Directory

All logs for goplot scripts are located in the "logs" directory under the goplot root.

Goplot Config Directory

Configuration parameters and state files for goplot are kept in the "config" directory under the goplot root.

Goplot Load

goplot uses system load as one of the condition checks to determine if it should start a new plot. "Goplot load" is derived from the load statistics seen in the Linux "uptime" command, however is determined by this formula:

  (5min load average + 15min load average) / 2

The best goplot load setting for any one plotter can only be determined through benchmarking different scenarios, however a value of 26 is a good starting point that should prevent a system from getting overwhelmed.

goplot.sh

goplot.sh is the main script that runs continuously in the background. The job of goplot.sh is to intermittently check the plotting and environmental conditions on the plotter to see if it should start a new plot. 

goplot.sh can be started in the background from the goplot root directory with this command:

  ./goplot &

goplot.sh has a few configuration variables that are kept in files in the "config" directory under the goplot root. The config directory also holds some state files that are accessed on occasion. Keeping tunable configuration parameters and state information in files allows them to be easily changed while the script is running; the new parameter can be echoed to the config file and the script will pick up the changes on the next loop. For instance, to configure goplot to start no more than 16 parallel plots this command can be used:

  echo "16" > /etc/chia/goplot/config/max_plots.goplot

Here is a list of the config and state files and a short description of their purpose:

  - on_toggle.goplot; must be set to "run" or goplot will stop on the next loop, used for graceful shutdown of goplot.sh
  - plot_gap.goplot; the minimum length of time in seconds between new plots
  - plot_poll.goplot; the minimum length of time in seconds between condition polls
  - load_max.goplot; the goplot load value over which new plots will not be created
  - max_plots; the maximum number of parallel plots that can be running at the same time
  - index.goplot; the plot index number for this plotter, used in log files and to name the output plot log file
  - farm_dest.goplot; the last destination farm number used by goplot.sh/tractor.sh
  - farm_temp.goplot; the last temp farm number used by goplot.sh/tractor.sh

goplot.log

Both goplot.sh and tractor.sh write log entries to goplot.log, which is located in the logs directory under the goplot root. When you are setting up your plotting you will want to watch this log file to see what is happening, and this is best done with tail, like:

  tail -f /etc/chia/goplot/logs/goplot.log

Diskhand

Much as a real farmer needs field hands to scale their farming operations, goplot needs diskhand.sh to manage disks. This is especially valuable when one wants to be gone from the farm for a time without tending to it. Automatic disk management must take into account the fact that disk space is committed many hours before it is actually used. The job of diskhand is to find the disks listed under each farm, query them for available space, query running jobs to estimate committed space, determine if the disk has space left for plotting, then write the space used to the disk's file under the goplot disks directory. If there is not enough space available for plotting then diskhand will write a large value of "9999999999999" so tractor.sh will know it is not available.

This behavior results in goplot filling up disks from the bottom up. If you want to remove a disk from the rotation before it is filled you can echo a very large size to the disk file and that disk will be removed from rotation the next time diskhand runs, like this:

  echo "9999999999999" > /etc/chia/goplot/disks/disk9.goplot

diskhand.sh should be configured as a cron job to run every two minutes, as with this example crontab entry:

*/2 * * * * /etc/chia/goplot/diskhand.sh

diskhand.sh overwrites a new log file with every run in logs/diskhand.log.

Tractor

tractor.sh is the script called by goplot.sh to start a new plot. By keeping tractor.sh a separate script it allows the parameters for "chia plots start" to be tuned between plots. Also you can use tractor.sh to manually start a plot outside of the usual goplot.sh polling cycle while still retaining the other goplot functions such as distributed farm loading and Grafana annotations. A new plot is easily started with the parameters defined in tractor.sh by running the script from the goplot root and sending it to the background like this:

  ./tractor.sh &


Installation
------------


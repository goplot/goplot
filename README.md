# goplot


Goplot is a manager for chia farms written in bash!

Development of Goplot was based on a few guiding principles:

  1. The heart of Chia farming is basically file management operations, and Linux is the best general OS for filesystem management.
  2. Core bash tools already integrated into the Linux OS support most functions needed in a Chia farm.
  3. Bash and bash scripts are highly accessible for both beginners and seasoned Linux experts.
  4. Monitoring and visualization needs are best met using open source tools, supplemented with custom scripts to get the data.

**Note:** Goplot is not for the faint of heart or novices without tenacity! It is not a simple executable that you just install, but rather an integration of open source tools glued together with bash scripts. 

[There is an xkcd for this...](https://xkcd.com/1742/)


Uses
------------

You can use Goplot to:

  1. Automatically start and pace parallel Chia plots on your plotter.
  2. Monitor the performance of your parallel plotting.
  3. Monitor eligible plots passing the plot filter.
  4. Monitor your Chia farm space, including space on remote harvesters.
  5. Assess your XCH wins!
  6. Inspire your own project!

(Please have fun stealing whatever you can from this project and make it your own, or if you want to contribute to Goplot submit a PR.)


Other Options
------------

Goplot is not for everyone. It was developed mainly with concern for management and monitoring of massive parallel plotting. It assumes knowledge of Linux and willingness to tinker with bash scripts. You will need to learn a little something about doing custom dashboards in Grafana. You may have to do a lot of things you have no idea how to do and only searches to help.

There are a few other options worth looking at that may either do what you want better than goplot or may supplement goplot:

  1. Chia default graphical interface; https://github.com/Chia-Network/chia-blockchain/wiki/INSTALL
    - Probably the best choice for a simple farm, likely to get more features added over time and perhaps eventually make goplot obsolete
  2. Plotman; https://github.com/ericaltendorf/plotman
    - Probably a better choice if you want to use and play around with Python
  3. Chiadog; https://github.com/martomi/chiadog
    - For monitoring more than plotting management?


Required Software
------------

*If you don't know how to figure out how to install these then turn back now.*

- Linux
  - goplot was developed on Ubuntu 20.04
- Chia blockchain
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
- diskhand.sh is run by cron every five minutes; keeps an eye on disk space and provides disks for plotting; takes disks out of rotation when filled
- harvesterlog.sh runs continuously in the background; monitors the Chia log for eligible plots passing the plot filter, writes the data to prometheus prom directory
- goplot_collector.sh is run by cron on the plotter every minute; writes custom goplot stats to prometheus prom directory
- getfarm_collector.sh is run by cron on the farmer every minute; writes custom chia farm stats to prometheus prom directory 
- getharvester_collector.sh is run on the remote harvester by cron every minute; sends custom chia farm stats to prometheus, writes harvester process status to prometheus prom directory
- getgoplot.sh is basically the CLI output version of goplot_collector.sh; used to quickly check your goplot configuration from the CLI
- getfarm.sh is basically the CLI output version of getfarm_collector.sh; used to quickly check your farm status from the CLI


Concepts
------------

**Farms**

Goplot uses the concept of **"farms"** to distribute IO to different IO busses for the destination drives and for the temp drives. As goplot starts new plots it will rotate through each farm to distribute the IO load. Each farm is assigned a number in sequence starting at "1". The farm configuration is communicated to goplot by a drive's mount point. 

The expected mount point for temp drives is under `/plot_temp/x` and for destination drives is under `/farm/x/disk` where *x* is the farm number and *disk* is the disk name.

A common farm configuration is to have external USB destination drives attached to a combined plotter/farmer. If the system has both front and back USB 3.0 ports then they are likely on different IO busses to the mainboard, meaning plots can be copied over both at the same time without USB bus contention. If both busses are to be used for plot destinations then the plotter is configured with two destination farms using the file system structure. For example, two destination farms are reflected in the file system as:

```
  /farm/1
  /farm/2
```

Similarly, a common plotter configuration is to have multiple temp drives, each of which has dedicated PCIe lanes, and these are separate busses that can be used at the same time without IO contention. Some people may combine these in a mkadm RAID 0, others may want to use the individual drives. Either is supported by goplot, and if individual temp drives are used then each is designated as a different farm number in the file system as:

```
  /plot_temp/1
  /plot_temp/2
```

If the temp drives are combined into the same RAID0 then there is only one temp farm designated in the file system as:

```
  /plot_temp/1
```

**Disks**

Plot destination farms are made up of **"disks"** which are named at the time the drive is mounted to the farm directory. It is recommended that you adopt a simple naming standard such as "disk1, disk2, disk3" etc. Each disk should be mounted to the farm directory that designates the physical bus the drive is attached to. Using the above example, let's say the farmer/plotter has two USB 3.0 busses, each connecting to a four-port USB hub, and each hub has three external drives attached. In this example odd-numbered disks are attached to farm 1 (hub 1) and even-numbered disks are attached to farm 2 (hub 2). This configuration would be represented in the file system as:

```
  /farm/1/disk1
  /farm/1/disk3
  /farm/1/disk5
  /farm/2/disk2
  /farm/2/disk4
  /farm/2/disk6 
```

Each of these is the mount point for a physical destination drive.


**Plots Directory**

Completed plots are contained in a plots directory on the destination farms. All disks need a plots directory to hold plots. Temp drives do not use a plots directory. For example, a simple farmer/plotter setup with only one temp drive and only one destination drive would be fully represented in the filesystem as:

```
  /farm/1/disk1/plots
  /plot_temp/1
```

**Plot Logs Directory**

The log output from each run of `chia plots create` is output to a logs directory on the destination drive. You may never need them, but who knows what data you may want later! The logs directory needs to be on each destination drive, such as:

```
  /farm/1/disk1/logs
  /farm/2/disk2/logs
```

**Goplot Logs Directory**

Application logs output by the goplot scripts are located in the `logs/` directory under the goplot root.

  
### Goplot Config Directory**

Configuration parameters and state files for goplot are kept in the `config/` directory under the goplot root. See more about this below.


### Goplot Collectors Directory

Collector scripts that are used to collect metrics for Prometheus are located in the `collectors/` directory under the goplot root. See the installation instructions for how to use these.


**Goplot Dashboard Directory**

The JSON configuration for the example Grafana dashboad for Goplot is located in the `dashboard/` directory under the goplot root. See the installation instructions for how to use this in Grafana.


**Goplot Plot Pacing Parameters**

Goplot uses three parameters to keep plotting within the system sweet spot of "not too busy" but still cranking out plots as fast as the system can handle:

- *plot_gap*: The minimum time between each plot start
- *max_plots*: The maximum number of parallel plots to run on the system
- *load_max*: The maximum system load threshold for starting new plots, uses the *goplot_load* metric

Of these parameters plot_gap and max_plots are the ones to focus on to get your plotter into the sweet spot. Once you have it there you can use load_max to fine tune new plot starts so they do not push your plotter too far out of the sweet spot. Note that if your plotter is limited by memory or temp SSD space then you are unlikely to ever need load_max; max_plots is the right way to prevent the plotter from using too much temp space or RAM.

load_max uses "Goplot load", which is derived from the load statistics seen in the Linux "uptime" command, however is determined by this formula:

  (5min load average + 15min load average) / 2

The best load_max setting for any plotter can only be determined through benchmarking different scenarios.


**goplot.sh**

goplot.sh is the main script that runs continuously in the background. The job of goplot.sh is to intermittently check the plotting and environmental conditions on the plotter to see if it should start a new plot. 

goplot.sh can be started in the background from the goplot root directory with this command:

  `./goplot &`

You can ensure the script continues to run after you logoout with `disown -h`


**goplot.sh Configuration Files**

goplot.sh has a few configuration variables that are kept in files in the "config" directory under the goplot root. This simple configuration uses one variable entry per file. The config directory also holds state files that are accessed on occasion, again one variable entry per file. Keeping goplot's tunable configuration parameters and state information in files allows them to be easily changed while the script is running; the new parameter can be echoed to the parameter-specific config file and the script will pick up the changes on the next loop. For instance, to configure goplot to start no more than 16 parallel plots this command can be used:

  `echo "16" > /etc/chia/goplot/config/max_plots.goplot`

Here is a list of the config and state files and a short description of their purpose:

  - *on_toggle.goplot*; must be set to "run" or goplot will stop on the next loop, used for graceful shutdown of goplot.sh
  - *plot_gap.goplot*; the minimum length of time in seconds between new plots
  - *plot_poll.goplot*; the minimum length of time in seconds between condition polls
  - *load_max.goplot*; the goplot load value over which new plots will not be created
  - *max_plots*; the maximum number of parallel plots that can be running at the same time
  - *index.goplot*; the plot index number for this plotter, used in log files and to name the output plot log file
  - *farm_dest.goplot*; the last destination farm number used by goplot.sh/tractor.sh
  - *farm_temp.goplot*; the last temp farm number used by goplot.sh/tractor.sh


**goplot.log**

Both goplot.sh and tractor.sh write their log entries to goplot.log, which is located in the logs directory under the goplot root. When you are setting up your plotting you will want to watch this log file to see what is happening, and this is best done with tail, like:

  `tail -f /etc/chia/goplot/logs/goplot.log`


**diskhand.sh**

Much as a real farmer needs field hands to help work their fields, goplot needs diskhand.sh to automate working with disks. This is especially valuable when one wants to be gone from the plotter for a time without tending to it. Automatic disk management on plotters must take into account the fact that disk space is committed many hours before it is actually used. The job of diskhand.sh is to find the disks listed under each farm, query them for available space, query running jobs to estimate committed space, determine if the disk has space left for plotting, then write the space used to the disk's file under the goplot disks directory. If there is not enough space available for plotting then diskhand will write a large value of "9999999999999" so tractor.sh will know it is not available.

Tractor.sh will always use the disk with the lowest amount of used space for the farm it has selected. This algorithm results in goplot reliably filling disks from the bottom up. If you want to remove a disk from the rotation before it is filled you can echo a very large size to the disk file and that disk will be removed from rotation the next time diskhand runs, like this:

  `echo "9999999999999" > /etc/chia/goplot/disks/disk9.goplot`

Any plots committed to that disk must complete before the disk is unmounted. Committed space is logged in `diskhand.log`. Once a disk has been removed from the rotation it can be added back by deleting the disk file in the `disks/` directory and re-running diskhand.sh.

diskhand.sh should be configured as a cron job to run every five minutes, as with this example crontab entry:

  `*/5 * * * * /etc/chia/goplot/diskhand.sh`

diskhand.sh overwrites a new log file with every run in logs/diskhand.log, unless the file has been set to a very large value as shown above.


**tractor.sh**

tractor.sh is the script called by goplot.sh to start a new plot. By keeping tractor.sh as a separate script it allows the parameters for "chia plots start" to be tuned between plots. Also you can use tractor.sh to manually start a plot outside of the usual goplot.sh polling cycle while still retaining the other goplot functions such as distributed farm loading and Grafana annotations. A new plot is easily started with the parameters defined in tractor.sh by running the script from the goplot root and sending it to the background like this:

  `./tractor.sh &`

tractor.sh sends `plot_start` and `plot_stop` tagged annotations to Grafana. These are invaluable visualizations for understanding your plotter pacing.


Installation
------------

**Note:** Goplot assumes it is located in /etc/chia/goplot. If you change this location then you will either need to change the $working_dir variable in the scripts or create a symlink to your actual location.

**Note:** Goplot assumes the Chia blockchain directory is /etc/chia/chia-blockchain. If you change this location then you will either need to change the $chia_venv_dir variable in the scripts or create a symlink to your actual location.

**Note:** Permissions between application setups can cause all sorts of problems; when in doubt run something as root/sudo to see if that solves the problem.


**Install the required software**

Before running goplot you need to install the required software listed above and ensure it is working. If you are reading this then you probably have the Chia software already! But the rest of the setup is much more challenging...

**WARNING**: You should either have intermediate experience in systems and application integration on Linux to continue, **or** be prepared for a very steep learning curve with little assistance other than lots of web searches.

There are many excellent guides out there for installing Prometheus and Grafana, just be sure you can login to the Grafana admin page and pull up the public node_exporter dashboard before you continue. The node_exporter itself is easy to setup; be sure to put the textfile directory in the launch command as a startup option, for instance this entry in the .service file:

  `ExecStart=/usr/local/bin/node_exporter --collector.textfile.directory='/etc/prometheus/collectors'`


**Setup destination and temp directories**

Remember that the directory structure tells goplot how to distribute load across IO busses. Create farm and temp directories with their mount points as described above. Mount your destination drives and create their *plots* and *logs* directories. As an example, say you have a plotter with two USB busses, each with two destination drives attached (four total external disks) and a single SSD temp drive. Your directory structure for plotting should look something like this:

```
/farm/1/disk1/plots
/farm/1/disk1/logs
/farm/1/disk2/plots
/farm/1/disk2/logs
/farm/2/disk3/plots
/farm/2/disk3/logs
/farm/2/disk4/plots
/farm/2/disk4/logs
/plot_temp/1
```

**Git clone goplot**

To get goplot just clone this repository from the system you want to install it on, ideally from the /etc/chia directory:

  `git clone https://github.com/goplot/goplot.git`

Now change to the goplot directory and run the getgoplot.sh script to see the default goplot configuration:

  `./getgoplot.sh`

You should also be able to run diskhand.sh and look at its log to see that it properly discovers your destination farm disks. The tail command in the script will report errors the first time it tries to read a new disk file, this is normal.

```
./diskhand.sh
cat logs/diskhand.log
```

**Set configuration parameters**

You can set each tunable goplot configuration parameter by echoing the value you want to set to that parameter's config file. For instance, to set the minimum time between plots you would enter this from the goplot root directory:

  `echo "1400" > config/plot_gap.goplot`

Provided you are not already limited by RAM or SSD temp drive space it can be hard to know exactly how to set your parallel plotting parameters to start. The best thing to do is run a single plot as a benchmark and make estimations based on that. You can also get ideas from the chia Keybase channels, or consider the values given below, assuming k=32 size plots and 2 threads per plot, and no significant bottlenecks on memory or SSD temp drive space/performance:

  1. Set max_plots.goplot to 1 parallel plot per physical CPU core
  2. Assume 36000 second plot time (10 hours)
  3. Set plot_gap.goplot to: plot_time / max_plots.

  For example, with a 8 core system you can start with max_plots=8 and plot_gap=4500 for what should be a relatively safe run, and you can modify your configuration over time to find your plotter's sweet spot.


**Configure cron jobs**

Cron jobs are required for diskhand.sh and for getfarm_collector.sh and goplot_collector.sh. The `sponge` tool is used to soak up the output of the collector scripts and output it all at once to the collector .prom file; this prevents problems with the file being written to at the same time Prometheus is trying to scrape it. The system crontab can be edited with the command:

  `sudo crontab -e`

Create three entries that look something like this:

```
*/5 * * * * /etc/chia/goplot/diskhand.sh
*/1 * * * * /etc/chia/goplot/collectors/goplot_collector.sh | sponge > /etc/prometheus/collectors/goplotstats.prom
*/1 * * * * /etc/chia/goplot/collectors/getfarm_collector.sh | sponge > /etc/prometheus/collectors/farmstats.prom
```

If you don't see files created in the destination folders then you will need to troubleshoot. Remember that you can always run these scripts directly from the command line as a troubleshooting step and work your way up to a line that will work in cron.


**Set Grafana API key variable in tractor.sh**

Edit tractor.sh and set the value for the `$grafana_api_key` variable to your Grafana API key inside single quotes. 


**Start harvesterlog.sh**

Start harvesterlog.sh so that it runs in the background by running this command from the goplot root:

  `./harvesterlog.sh &`

Then use `disown -h` to keep the script running when you logout.


**Import the Grafana dashboard and set Goplot host variables**

Open Grafana and import the example dashboard from the JSON file in the dashboard directory. You will need to set  these three variables: `farmer1`, `$plotter1`, `$remote_harvester1` to the actual location of your hosts. Single machine setups will not need to change anything as both plotter1 and farmer1 already point to `localhost:9100`.

If Prometheus is receiving the custom metrics and Grafana can see the metrics then the Goplot specific parts of the dashboard should be working. The other parts may requires some tinkering to work on your system. The panels inside the Misc row are mostly straight from the node_exporter dashboard.

Later consider installing `nvmetools` and using the [nvme stats collector](https://github.com/prometheus-community/node-exporter-textfile-collector-scripts/blob/master/nvme_metrics.sh) or some modified version for your situation.


**Start goplot.sh**

Before you start goplot you need to set on_toggle.goplot to "run":

  `echo "run" > config/on_toggle.goplot`

If you ever want to stop goplot gracefully you can set this file to any other value and the script will stop after it reads the parameter at the start of the next polling action. (Plots already started will continue to run.)

Now start goplot.sh to run in the background by running this command from the goplot root:

  `./goplot.sh &`

If everything is setup right you will probably see some console messages about plot creation and Grafana annotations. Regardless, tail the goplot log file to see what is happening:

  `tail -f logs/goplot.log`

If a plot has not started then you will need to troubleshoot your configuration. If goplot.sh starts and runs but there is a problem running tractor.sh then you can leave goplot running while you work on tractor and goplot will try to use your modified tractor on the next scheduled run. When you are first getting set up it is common to have a few false starts and you may decide you need to kill the goplot.sh process manually, especially if your plot_gap is very long and you want to see a plot start soon.

After goplot.sh is started use `disown -h` to keep the script running when you logout.


Remote Harvesters
------------

Remote harvesters have farm plots and farm space metrics that need to be in Prometheus for a full picture of the farm to be possible. This is accomplished by running a modifed version of getfarm_collector.sh on the harvester called getharvester_collector.sh. 

Here are the high level steps you must go through to enable remote harvester metric collection:

  1. Install Prometheus node_exporter on the remote harvester with the textfile collector setup much as you did for your main farmer. You do not need to install the prometheus data store or Grafana on the harvester.
  2. Verify that the farmer is able to access the remote harvester node_exporter data on port 9100.
  3. Add the remote harvester node_exporter URL to the main farmer's Prometheus configuration.
  4. Verify that the standard remote harvester node_exporter metrics are viewable in Grafana.

Once the basic setup is complete you can add the custom metrics. From the remote harvester setup a cron job like this:

  `*/1 * * * * /etc/chia/goplot/collectors/getharvester_collector.sh`

Note that this version does not use `sponge` and by default will write to the directory `etc/prometheus/collectors` as configured in the script.

You will also want to see the remote harvester's eligible plots in your dashboard, so run harvesterlog.sh in the background as you did on the main farmer:

  `./harvesterlog.sh &`

You should now see farm space, farm plots, eligible plots metrics, and status for the remote harvester in your Grafana dashboard. Remember to use `disown -h` to keep the script running when you logout.


Remote Plotters
------------

The setup for a remote plotter is a combination of the main farmer and the remote harvester. This is an advanced topic so if you are that far along then you can probably figure out the details for yourself with a little guidance; setup goplot as on the main farmer, setup the remote harvester configuration, and then if you want Grafana plot_start and plot_end annotations then you will also need to be sure the remote plotter can communicate with Grafana port 3000. Change the $grafana_url variable in tractor.sh to point to the Grafana host and (if desired) modify the annotation tags.


Running and Tuning Tips
------------

- The goplot configuration parameters to focus on to begin with are max_plots and plot_gap. load_max is for fine tuning once you are in the sweet spot.
- When figuring out your plot pacing you will find that every system has its own sweet spot where it will perform best, and subtle attempts to push the system to produce more will result in less consistent pacing but about the same yield. 
- You know you have exceeded the sweet spot for your system if plot pacing suddenly gets much less consistent and the processor is pegged at the same high level for long periods of time and your yield is less.
- You will find that once you get your plotter spun up to its full number of parallel plots you can plot continuously and you will not need to spin it down to make modifications to your pacing, plot settings, chia software, or destination drives.
- Diskhand.sh can be run at any time to see the current state of disk space availability.
- After you mount a new disk and create the *plots* and *logs* directories run `./diskhand.sh` and `cat logs/diskhand.log` to be sure your disk was recognized and is ready for plotting.
- If cron runs diskhand.sh while you are in the process of creating and mounting a new disk it may create a disk file for that disk with size 99999999999999. If this happens just delete that disk file and let diskhand.sh run again.
- You can easily start with a new set of disk files if you think something wrong with some of them, just `rm disks/*` and run diskhand.sh again.
- To change `chia plots start` command line parameters edit their variables in tractor.sh.
- You can manually experiment with plot pacing or insert plots out of schedule by setting the plot_gap to a high number and then running `./tractor.sh &` as desired.
- Changes to Chia software plotting capabilities are likely to cause changes in your plotter pacing, and you may need to adjust your configuration to get the best from your plotter.
- Older versions of chia software can still be used for plotting; just install that version in a different directory from your main chia farmer/harvester directory and change the `$chia_venv_dir` variable in tractor.sh to that directory.
- Pacing plots using load_max is only required when you have really dialed in your pacing, to prevent exceeding the sweet spot. It is still not known for sure that goplot_load is the best system metric to use for the load threshold on all systems, though it works well on the development system.

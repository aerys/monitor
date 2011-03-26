Aerys Monitor
=============

![Capture 1](http://blogs.aerys.in/jeanmarc-leroux/wp-content/uploads/2010/11/aerys_monitor_2.png) ![Capture 2](http://blogs.aerys.in/jeanmarc-leroux/wp-content/uploads/2010/11/aerys_monitor_1.png)

Lightweight customizable ActionScript 3.0 property monitor:

* watch **any property** of **any class**
* customizable update rate
* customizable per-property color
* **chat rendering** for numeric values
* watch framerate, memory and Flash Player version
* ready to use framerate property


Usage
-----

	// get a singleton Monitor object
	var monitor : Monitor = Monitor.monitor;

	// set the update (refresh) rate to 15 updates per second
	monitor.updateRate = 15.;

	// add the monitor to the display list
	stage.addChild(monitor);

	// watch the rotationX property of the camera object with a scale value of 1 / (PI / 2)
	monitor.watch(camera, "rotationX", 0x55ff00, 1. / (Math.PI / 2.), true);
	// watch the rotationY property of the camera object with a scale value of 1 / (2 * PI)
	monitor.watch(camera, "rotationY", 0xff5500, 1. / (2. * Math.PI), true);
	// watch the rotationZ property of the camera object with no scale value (=> no chart rendering)
	monitor.watch(camera, "rotationZ", 0x5599ff);

	// watch multiple properties
	monitor.watchProperties(physics,
	                        ["processingTime", "speed"],
	                        [0x00ff00, 0xff0000],
	                        [1. / 40., 1. / 10.]);

	// change the background color (0xAARRGGBB)
	monitor.backgroundColor = 0x7f000000;


Contribute
----------

`aerys-monitor` is GPL-licensed.  Make sure you tell us everything that's wrong!

* [Source code](https://github.com/aerys/monitor)
* [Issue tracker](https://github.com/aerys/monitor/issues)

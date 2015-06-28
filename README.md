# gazesdk #

Python language bindings implemented in Cython for Tobii GazeSDK C API. 

This is a work in progress. Backwards incompatible changes are possible in the near future. Currently only basic tracking functionality is supported, See TODO below for planned changes.

Note that use of this software is not officially supported by Tobii.

## Example ##

The following example prints normalized screen coordinates for first 10 events.

```python

from gazesdk import *
import threading

t = Tracker()
t.create(get_connected_eye_tracker())

def eventloop(tracker):
    tracker.run_event_loop()

el = threading.Thread(target=eventloop, args=(t,))
el.start()

print "Connecting..."
t.connect()

print "Starting..."
t.start_tracking()

for _ in range(20):
    data = t.event_queue.get()
    print data.left.gaze_point_on_display_normalized, data.left.gaze_point_on_display_normalized
    t.event_queue.task_done()

print "Stopping..."
t.stop_tracking()

print "Disconnecting..."
t.disconnect()

print "Breaking event loop"
t.break_event_loop()
el.join()
t.destroy()

```

## TODO ##

- [ ] Calibration functions
- [ ] Raising exceptions on error codes
- [ ] Internal thread running
- [ ] API docs

## Licence ##

The MIT License (MIT)

Copyright (c) 2015 balancana

Please note that this software relies on proprietary library. Check Tobii's website for more details. 
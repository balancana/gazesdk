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


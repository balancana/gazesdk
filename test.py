from gazesdk import *

url = get_connected_eye_tracker()
t = Tracker(url)
t.run_event_loop()

t.connect()
t.start_tracking()

for _ in range(20):
    data = t.event_queue.get()
    print (data.left.gaze_point_on_display_normalized, 
    	   data.right.gaze_point_on_display_normalized)
    t.event_queue.task_done()

t.stop_tracking()
t.disconnect()

t.break_event_loop()


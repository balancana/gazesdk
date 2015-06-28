cimport cgazesdk
import  Queue

def get_version():
    return cgazesdk.tobiigaze_get_version()

def get_connected_eye_tracker():
    cdef cgazesdk.uint32_t url_size = 256
    cdef char url[256]
    cdef cgazesdk.tobiigaze_error_code error_code
    cgazesdk.tobiigaze_get_connected_eye_tracker(url, url_size, &error_code)
    return url

cdef class GazeDataEye:

    cdef readonly eye_position_from_eye_tracker_mm
    cdef readonly eye_position_in_track_box_normalized
    cdef readonly gaze_point_from_eye_tracker_mm
    cdef readonly gaze_point_on_display_normalized

    cdef public void init(self, cgazesdk.tobiigaze_gaze_data_eye _gaze_data_eye):

        self.eye_position_from_eye_tracker_mm = _gaze_data_eye.eye_position_from_eye_tracker_mm.x, _gaze_data_eye.eye_position_from_eye_tracker_mm.y, _gaze_data_eye.eye_position_from_eye_tracker_mm.z
        self.eye_position_in_track_box_normalized = _gaze_data_eye.eye_position_in_track_box_normalized.x, _gaze_data_eye.eye_position_in_track_box_normalized.y, _gaze_data_eye.eye_position_in_track_box_normalized.z
        self.gaze_point_from_eye_tracker_mm = _gaze_data_eye.gaze_point_from_eye_tracker_mm.x, _gaze_data_eye.gaze_point_from_eye_tracker_mm.y, _gaze_data_eye.gaze_point_from_eye_tracker_mm.z
        self.gaze_point_on_display_normalized = _gaze_data_eye.gaze_point_on_display_normalized.x, _gaze_data_eye.gaze_point_on_display_normalized.y


cdef class GazeData:
    
    cdef readonly cgazesdk.uint64_t timestamp
    cdef readonly cgazesdk.tobiigaze_tracking_status tracking_status

    cdef readonly GazeDataEye left
    cdef readonly GazeDataEye right

    cdef void init(self, cgazesdk.tobiigaze_gaze_data* _gaze_data):
        self.timestamp = _gaze_data.timestamp
        self.tracking_status = _gaze_data.tracking_status
        self.left = GazeDataEye()
        self.left.init(_gaze_data.left)
        self.right = GazeDataEye()
        self.right.init(_gaze_data.right)


cdef void gaze_callback(cgazesdk.tobiigaze_gaze_data* _gaze_data, cgazesdk.tobiigaze_gaze_data_extensions* _gaze_data_extensions, void *user_data) with gil:
    g = GazeData()
    g.init(_gaze_data)
    event_queue = <object>user_data
    event_queue.put(g)

cdef class Tracker:

    cdef cgazesdk.tobiigaze_eye_tracker* _tracker
    cdef public object event_queue
    
    def __init__(self):
        self.event_queue = Queue.Queue()

    def create(self, url):
        cdef cgazesdk.tobiigaze_error_code error_code
        self._tracker = cgazesdk.tobiigaze_create(url, &error_code)

    def destroy(self):
        cgazesdk.tobiigaze_destroy(self._tracker)

    def run_event_loop(self):
        cdef cgazesdk.tobiigaze_error_code error_code
        with nogil:
            cgazesdk.tobiigaze_run_event_loop(self._tracker, &error_code)

    def break_event_loop(self):
        cgazesdk.tobiigaze_break_event_loop(self._tracker)

    def connect(self):
        cdef cgazesdk.tobiigaze_error_code error_code
        with nogil:
            cgazesdk.tobiigaze_connect(self._tracker, &error_code)

    def disconnect(self):
        cgazesdk.tobiigaze_disconnect(self._tracker)

    def is_connected(self):
        is_connected = cgazesdk.tobiigaze_is_connected(self._tracker)
        return bool(is_connected)

    def start_tracking(self):
        cdef cgazesdk.tobiigaze_error_code error_code
        cgazesdk.tobiigaze_start_tracking(self._tracker, gaze_callback, &error_code, <void*> self.event_queue)

    def stop_tracking(self):
        cdef cgazesdk.tobiigaze_error_code error_code
        cgazesdk.tobiigaze_stop_tracking(self._tracker, &error_code)




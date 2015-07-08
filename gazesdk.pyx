cimport cgazesdk
import  Queue
import threading

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
        self.eye_position_from_eye_tracker_mm = (_gaze_data_eye.eye_position_from_eye_tracker_mm.x, 
                                                 _gaze_data_eye.eye_position_from_eye_tracker_mm.y, 
                                                 _gaze_data_eye.eye_position_from_eye_tracker_mm.z)

        self.eye_position_in_track_box_normalized = (_gaze_data_eye.eye_position_in_track_box_normalized.x, 
                                                     _gaze_data_eye.eye_position_in_track_box_normalized.y, 
                                                     _gaze_data_eye.eye_position_in_track_box_normalized.z)

        self.gaze_point_from_eye_tracker_mm = (_gaze_data_eye.gaze_point_from_eye_tracker_mm.x, 
                                               _gaze_data_eye.gaze_point_from_eye_tracker_mm.y, 
                                               _gaze_data_eye.gaze_point_from_eye_tracker_mm.z)

        self.gaze_point_on_display_normalized = (_gaze_data_eye.gaze_point_on_display_normalized.x, 
                                                 _gaze_data_eye.gaze_point_on_display_normalized.y)


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


cdef void gaze_callback(cgazesdk.tobiigaze_gaze_data* _gaze_data, cgazesdk.tobiigaze_gaze_data_extensions* _gaze_data_extensions, 
          void *user_data) with gil:
    g = GazeData()
    g.init(_gaze_data)
    event_queue = <object>user_data
    event_queue.put(g)


cdef class Tracker:

    cdef cgazesdk.tobiigaze_eye_tracker* _tracker
    cdef public object event_queue
    cdef object event_loop
    
    def __cinit__(self, url):
        self.event_queue = Queue.Queue()
        cdef cgazesdk.tobiigaze_error_code error_code
        self._tracker = cgazesdk.tobiigaze_create(url, &error_code)
        if error_code > 0: 
            raise TrackerError(error_code)

    def __dealloc__(self):
        with nogil:
            cgazesdk.tobiigaze_destroy(self._tracker)

    def run_event_loop(self):
        self.event_loop = threading.Thread(target=self.__run_event_loop)
        self.event_loop.start()

    def run_event_loop_internal(self):
        cdef cgazesdk.tobiigaze_error_code error_code
        with nogil:
            cgazesdk.tobiigaze_run_event_loop(self._tracker, &error_code)
        if error_code > 0: 
            raise TrackerError(error_code)

    def break_event_loop(self):
        with nogil:
            cgazesdk.tobiigaze_break_event_loop(self._tracker)
        if(self.event_loop):
            self.event_loop.join()

    def connect(self):
        cdef cgazesdk.tobiigaze_error_code error_code
        with nogil:
            cgazesdk.tobiigaze_connect(self._tracker, &error_code)
        if error_code > 0: 
            raise TrackerError(error_code)

    def disconnect(self):
        with nogil:
            cgazesdk.tobiigaze_disconnect(self._tracker)

    def is_connected(self):
        with nogil:
            is_connected = cgazesdk.tobiigaze_is_connected(self._tracker)
        return bool(is_connected)

    def start_tracking(self):
        cdef cgazesdk.tobiigaze_error_code error_code
        with nogil:
            cgazesdk.tobiigaze_start_tracking(self._tracker, gaze_callback, &error_code, <void*> self.event_queue)
        if error_code > 0: 
            raise TrackerError(error_code)

    def stop_tracking(self):
        cdef cgazesdk.tobiigaze_error_code error_code
        with nogil:
            cgazesdk.tobiigaze_stop_tracking(self._tracker, &error_code)
        if error_code > 0: 
            raise TrackerError(error_code)


class TrackerError(Exception):

    def __init__(self, error_code):
        self.error_code = error_code
        message = error_codes[error_code]
        super(TrackerError, self).__init__(message)


error_codes = {
    0:          'TOBIIGAZE_ERROR_SUCCESS',
    1:          'TOBIIGAZE_ERROR_UNKNOWN',
    2:          'TOBIIGAZE_ERROR_OUT_OF_MEMORY',
    3:          'TOBIIGAZE_ERROR_BUFFER_TOO_SMALL',
    4:          'TOBIIGAZE_ERROR_INVALID_PARAMETER',
    5:          'TOBIIGAZE_ERROR_INVALID_OPERATION',
    100:        'TOBIIGAZE_ERROR_TIMEOUT',
    101:        'TOBIIGAZE_ERROR_OPERATION_ABORTED',
    200:        'TOBIIGAZE_ERROR_INVALID_URL',
    201:        'TOBIIGAZE_ERROR_ENDPOINT_NAME_LOOKUP_FAILED',
    202:        'TOBIIGAZE_ERROR_ENDPOINT_CONNECT_FAILED',
    203:        'TOBIIGAZE_ERROR_DEVICE_COMMUNICATION_ERROR',
    204:        'TOBIIGAZE_ERROR_ALREADY_CONNECTED',
    205:        'TOBIIGAZE_ERROR_NOT_CONNECTED',
    206:        'TOBIIGAZE_ERROR_TIMESYNC_COMMUNICATION_ERROR',
    300:        'TOBIIGAZE_ERROR_PROTOCOL_DECODING_ERROR',
    301:        'TOBIIGAZE_ERROR_PROTOCOL_VERSION_ERROR',
    0x20000500: 'TOBIIGAZE_FW_ERROR_UNKNOWN_OPERATION',
    0x20000501: 'TOBIIGAZE_FW_ERROR_UNSUPPORTED_OPERATION',
    0x20000502: 'TOBIIGAZE_FW_ERROR_OPERATION_FAILED',
    0x20000503: 'TOBIIGAZE_FW_ERROR_INVALID_PAYLOAD',
    0x20000504: 'TOBIIGAZE_FW_ERROR_UNKNOWN_ID',
    0x20000505: 'TOBIIGAZE_FW_ERROR_UNAUTHORIZED',
    0x20000506: 'TOBIIGAZE_FW_ERROR_EXTENSION_REQUIRED',
    0x20000507: 'TOBIIGAZE_FW_ERROR_INTERNAL_ERROR',
    0x20000508: 'TOBIIGAZE_FW_ERROR_STATE_ERROR',
    0x20000509: 'TOBIIGAZE_FW_ERROR_INVALID_PARAMETER',
    0x2000050A: 'TOBIIGAZE_FW_ERROR_OPERATION_ABORTED'
}

tracking_statuses = {
    0: 'TOBIIGAZE_TRACKING_STATUS_NO_EYES_TRACKED',
    1: 'TOBIIGAZE_TRACKING_STATUS_BOTH_EYES_TRACKED',
    2: 'TOBIIGAZE_TRACKING_STATUS_ONLY_LEFT_EYE_TRACKED',
    3: 'TOBIIGAZE_TRACKING_STATUS_ONE_EYE_TRACKED_PROBABLY_LEFT',
    4: 'TOBIIGAZE_TRACKING_STATUS_ONE_EYE_TRACKED_UNKNOWN_WHICH',
    5: 'TOBIIGAZE_TRACKING_STATUS_ONE_EYE_TRACKED_PROBABLY_RIGHT',
    6: 'TOBIIGAZE_TRACKING_STATUS_ONLY_RIGHT_EYE_TRACKED'
}

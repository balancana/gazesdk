from libc.stdint cimport uint32_t, uint64_t

cdef extern from "tobiigaze_data_types.h":

    ctypedef enum tobiigaze_error_code:
        pass

    ctypedef enum tobiigaze_tracking_status:
        pass

    ctypedef struct tobiigaze_eye_tracker:
        pass

    cdef struct tobiigaze_point_2d:
        double x
        double y

    cdef struct tobiigaze_point_3d:
        double x
        double y
        double z

    cdef struct tobiigaze_gaze_data_eye:
        tobiigaze_point_3d eye_position_from_eye_tracker_mm
        tobiigaze_point_3d eye_position_in_track_box_normalized
        tobiigaze_point_3d gaze_point_from_eye_tracker_mm
        tobiigaze_point_2d gaze_point_on_display_normalized

    cdef struct tobiigaze_gaze_data:
        uint64_t timestamp
        tobiigaze_tracking_status tracking_status
        tobiigaze_gaze_data_eye left
        tobiigaze_gaze_data_eye right

    cdef struct tobiigaze_gaze_data_extensions:
        pass


cdef extern from "tobiigaze.h":

    ctypedef void tobiigaze_gaze_listener(tobiigaze_gaze_data *gaze_data, tobiigaze_gaze_data_extensions *gaze_data_extensions, void *user_data) with gil
    ctypedef void *tobiigaze_async_callback(tobiigaze_error_code error_code, void *user_data)

    const char* tobiigaze_get_version()
    tobiigaze_eye_tracker* tobiigaze_create(const char *url, tobiigaze_error_code *error_code)
    void tobiigaze_run_event_loop(tobiigaze_eye_tracker *eye_tracker, tobiigaze_error_code *error_code) nogil

    void tobiigaze_connect(tobiigaze_eye_tracker *eye_tracker, tobiigaze_error_code *error_code) nogil
    void tobiigaze_disconnect(tobiigaze_eye_tracker *eye_tracker) 
    int tobiigaze_is_connected(tobiigaze_eye_tracker *eye_tracker)

    void tobiigaze_start_tracking(tobiigaze_eye_tracker *eye_tracker, tobiigaze_gaze_listener gaze_callback, tobiigaze_error_code *error_code, void *user_data)
    void tobiigaze_stop_tracking(tobiigaze_eye_tracker *eye_tracker, tobiigaze_error_code *error_code)
    void tobiigaze_break_event_loop(tobiigaze_eye_tracker *eye_tracker)
    void tobiigaze_destroy(tobiigaze_eye_tracker *eye_tracker)


cdef extern from "tobiigaze_discovery.h":
    void tobiigaze_get_connected_eye_tracker(char *url, uint32_t url_size, tobiigaze_error_code *error_code)


#+build windows
#+vet
package owin

import win32 "core:sys/windows"

stopwatch_tick :: u64
stopwatch_time :: f64

stopwatch :: struct {
	start_tick:          stopwatch_tick,
	stop_tick:           stopwatch_tick,
	last_tick:           stopwatch_tick,
	elapsed_ticks:       stopwatch_tick,
	start:               proc(this: ^stopwatch),
	stop:                proc(this: ^stopwatch),
	get_elapsed_seconds: proc(this: ^stopwatch) -> stopwatch_time,
	get_elapsed_ms:      proc(this: ^stopwatch) -> stopwatch_time,
	get_delta_seconds:   proc(this: ^stopwatch) -> stopwatch_time,
}

performance_frequency: stopwatch_tick = 0
@(private = "file")
ticks_to_seconds: stopwatch_time = 0
@(private = "file")
ticks_to_millisecond: stopwatch_time = 0
@(private = "file")
ticks_to_timespan: stopwatch_time = 0

@(private = "file")
stopwatch_start :: proc(this: ^stopwatch) {
	win32.Sleep(0)
	this.stop_tick = 0
	this.elapsed_ticks = 0
	win32.QueryPerformanceCounter(cast(^win32.LARGE_INTEGER)&this.start_tick)
	this.last_tick = this.start_tick
}

@(private = "file")
stopwatch_stop :: proc(this: ^stopwatch) {
	win32.QueryPerformanceCounter(cast(^win32.LARGE_INTEGER)&this.stop_tick)
	this.elapsed_ticks = this.stop_tick - this.start_tick
}

@(private = "file")
stopwatch_get_elapsed_seconds :: proc(this: ^stopwatch) -> stopwatch_time {
	return stopwatch_time(this.elapsed_ticks) * ticks_to_seconds
}

@(private = "file")
stopwatch_get_elapsed_ms :: proc(this: ^stopwatch) -> stopwatch_time {
	return stopwatch_time(this.elapsed_ticks) * ticks_to_millisecond
}

@(private = "file")
stopwatch_get_delta_seconds :: proc(this: ^stopwatch) -> stopwatch_time {
	tick: stopwatch_tick
	win32.QueryPerformanceCounter(cast(^win32.LARGE_INTEGER)&tick)
	delta_tick := tick - this.last_tick
	this.last_tick = tick
	return stopwatch_time(delta_tick) * ticks_to_seconds
}

create_stopwatch :: proc() -> stopwatch {

	if performance_frequency == 0 {
		if win32.QueryPerformanceFrequency(cast(^win32.LARGE_INTEGER)&performance_frequency) {
			ticks_to_seconds = 1.0 / stopwatch_time(performance_frequency)
			ticks_to_millisecond = 1_000.0 / stopwatch_time(performance_frequency)
			ticks_to_timespan = 10_000_000.0 / stopwatch_time(performance_frequency)
		}
	}

	sw := stopwatch {
		start_tick          = 0,
		stop_tick           = 0,
		last_tick           = 0,
		elapsed_ticks       = 0,
		start               = stopwatch_start,
		stop                = stopwatch_stop,
		get_elapsed_seconds = stopwatch_get_elapsed_seconds,
		get_elapsed_ms      = stopwatch_get_elapsed_ms,
		get_delta_seconds   = stopwatch_get_delta_seconds,
	}
	return sw
}

/*
@(init, private)
_initialization :: proc() {
	if win32.QueryPerformanceFrequency(cast(^win32.LARGE_INTEGER)&performance_frequency) {
		// fmt.println("QueryPerformanceFrequency:", performance_frequency)
		ticks_to_seconds = 1.0 / performance_frequency
		ticks_to_millisecond = 1_000.0 / performance_frequency
		ticks_to_timespan = 10_000_000.0 / performance_frequency
	}
	// QueryPerformanceCounter
}
*/

// +build windows
package win32app

import "core:fmt"
import win32 "core:sys/windows"

stopwatch :: struct {
	start_tick:          u64,
	stop_tick:           u64,
	last_tick:           u64,
	elapsed_ticks:       u64,
	start:               proc(this: ^stopwatch),
	stop:                proc(this: ^stopwatch),
	get_elapsed_seconds: proc(this: ^stopwatch) -> f64,
	get_elapsed_ms:      proc(this: ^stopwatch) -> f64,
	get_delta_seconds:   proc(this: ^stopwatch) -> f64,
}

performance_frequency: u64 = 0
@(private="file")
ticks_to_seconds: f64 = 0
@(private="file")
ticks_to_millisecond: f64 = 0
@(private="file")
ticks_to_timespan: f64 = 0

@(private="file")
stopwatch_start :: proc(this: ^stopwatch) {
	win32.Sleep(0)
	win32.QueryPerformanceCounter(cast(^win32.LARGE_INTEGER)&this.start_tick)
	this.last_tick = this.start_tick
	this.stop_tick = 0
	this.elapsed_ticks = 0
}

@(private="file")
stopwatch_stop :: proc(this: ^stopwatch) {
	win32.QueryPerformanceCounter(cast(^win32.LARGE_INTEGER)&this.stop_tick)
	this.elapsed_ticks = this.stop_tick - this.start_tick
}

@(private="file")
stopwatch_get_elapsed_seconds :: proc(this: ^stopwatch) -> f64 {
	return f64(this.elapsed_ticks) * ticks_to_seconds
}

@(private="file")
stopwatch_get_elapsed_ms :: proc(this: ^stopwatch) -> f64 {
	return f64(this.elapsed_ticks) * ticks_to_millisecond
}

@(private="file")
stopwatch_get_delta_seconds :: proc(this: ^stopwatch) -> f64 {
	pc: u64
	win32.QueryPerformanceCounter(cast(^win32.LARGE_INTEGER)&pc)
	delta := pc - this.last_tick
	this.last_tick = pc
	return f64(delta) * ticks_to_seconds
}

create_stopwatch :: proc() -> stopwatch {

	if performance_frequency == 0 {
		if win32.QueryPerformanceFrequency(cast(^win32.LARGE_INTEGER)&performance_frequency) {
			ticks_to_seconds = 1.0 / f64(performance_frequency)
			ticks_to_millisecond = 1_000.0 / f64(performance_frequency)
			ticks_to_timespan = 10_000_000.0 / f64(performance_frequency)
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

/*@(init, private)
_initialization :: proc() {
	if win32.QueryPerformanceFrequency(cast(^win32.LARGE_INTEGER)&performance_frequency) {
		// fmt.printf("QueryPerformanceFrequency: %v\n", performance_frequency)
		ticks_to_seconds = 1.0 / performance_frequency
		ticks_to_millisecond = 1_000.0 / performance_frequency
		ticks_to_timespan = 10_000_000.0 / performance_frequency
	}
	// QueryPerformanceCounter
}*/

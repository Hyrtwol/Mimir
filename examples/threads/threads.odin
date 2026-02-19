package main

import "core:fmt"
import win32 "core:sys/windows"
import "core:thread"
import "core:time"

// https://stackoverflow.com/questions/58740400/what-is-the-best-way-to-wait-a-thread
// https://learn.microsoft.com/en-us/windows/win32/sync/using-event-objects

signal: win32.HANDLE

do_it :: proc(t: ^thread.Thread) {

	fmt.println("WaitForSingleObject")
	res := win32.WaitForSingleObject(signal, win32.INFINITE)
	if res > win32.WAIT_OBJECT_0 {
		fmt.panicf("error=%v", res)
	}
	fmt.println("work work work")
}

main :: proc() {
	fmt.println("hello world")

    signal = win32.CreateEventW(nil, true, false, "just_a_test")
	defer win32.CloseHandle(signal)

	t := thread.create(do_it)

	fmt.println("start")
	thread.start(t)

	fmt.println("wait")
	time.sleep(time.Millisecond * 1000)

	fmt.println("write")
	if !win32.SetEvent(signal) {
		panic("fail!!!!")
	}

	fmt.println("wait")
	time.sleep(time.Millisecond * 1000)

	fmt.println("join")

	thread.join(t)

	fmt.println("done")
}

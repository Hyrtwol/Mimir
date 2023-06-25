package main

import          "core:fmt"
import          "core:intrinsics"
import          "core:math"
import          "core:math/linalg"
import hlm      "core:math/linalg/hlsl"
import          "core:math/noise"
import          "core:math/rand"
import          "core:mem"
import          "core:runtime"
import          "core:simd"
import          "core:strings"
import win32    "core:sys/windows"
import          "core:time"
import win32app "../../shared/tlc/win32app"
import canvas   "../../shared/tlc/canvas"
import "../../shared/fmod"
import "../../shared/tlc/wolf"

L :: intrinsics.constant_utf16_cstring

TITLE 	:: "FMOD Event System"
WIDTH  	:: 640
HEIGHT 	:: WIDTH * 9 / 16
CENTER  :: true
ZOOM  	:: 8

FMOD_MAXCHANNELS :: 32
FMOD_INIT_FLAGS :: fmod.FMOD_INIT_3D_RIGHTHANDED
DistanceFactor :: 1.0

screenbuffer  :: canvas.screenbuffer

bitmap_handle : win32.HGDIOBJ // win32.HBITMAP
bitmap_size   : win32app.int2
bitmap_count  : i32
pvBits        : screenbuffer
pixel_size    : win32app.int2 : {ZOOM, ZOOM}

dib           : canvas.DIB
timer1_id     : win32.UINT_PTR
// timer2_id     : win32.UINT_PTR

system: ^fmod.FMOD_SYSTEM = nil
eventsys: ^fmod.FMOD_EVENTSYSTEM = nil

events : [wolf.EVENTCOUNT_WOLFENSTEINSFX]^fmod.FMOD_EVENT
song : ^fmod.FMOD_SOUND = nil

title: string
dsp, stream, geometry, update, total : f32
channels_playing: i32

play_event :: proc(event_id: i32)
{
	event: ^fmod.FMOD_EVENT = events[event_id]
	if event == nil {
		fmt.printf("event_id %d is nil\n", event_id)
		return
	}

	res: fmod.FMOD_RESULT

	res = fmod.FMOD_Event_Stop(event, 1)
	if res != fmod.FMOD_RESULT.FMOD_OK {
		fmt.printf("%v %v\n", fmod.FMOD_EventSystem_Load, res)
		return
	}

	position := fmod.FMOD_VECTOR{0, 0, 0}
	velocity := fmod.FMOD_VECTOR{0, 0, 0}
	res = fmod.FMOD_Event_Set3DAttributes(event, &position, &velocity, nil)

	res = fmod.FMOD_Event_Start(event)
	if res != fmod.FMOD_RESULT.FMOD_OK {
		fmt.printf("%v %v\n", fmod.FMOD_EventSystem_Load, res)
		return
	}
}

play_song :: proc()
{
	res: fmod.FMOD_RESULT
	if song == nil {
		res = fmod.FMOD_System_CreateSound(system, "Ktulu.xm", fmod.FMOD_HARDWARE | fmod.FMOD_2D, nil, &song)
		if res != fmod.FMOD_RESULT.FMOD_OK {
			fmt.printf("FMOD_System_CreateSound %v\n", res)
			return
		}
	}
	if song != nil {
		channel: ^fmod.FMOD_CHANNEL
		res = fmod.FMOD_System_PlaySound(system, fmod.FMOD_CHANNELINDEX.FMOD_CHANNEL_FREE, song, 0, &channel)
		if res != fmod.FMOD_RESULT.FMOD_OK {
			fmt.printf("FMOD_System_PlaySound %v\n", res)
			return
		}
		fmt.printf("FMOD_System_PlaySound channel %v\n", channel)
	}
}

decode_scrpos :: proc(lparam: win32.LPARAM) -> win32app.int2 {
	scrpos := win32app.decode_lparam(lparam) / ZOOM
	scrpos.y = bitmap_size.y - 1 - scrpos.y
	return scrpos
}

setdot :: proc(pos: win32app.int2, col: canvas.byte4) {
	i := pos.y * bitmap_size.x + pos.x
	if i >= 0 && i < bitmap_count {
		pvBits[i] = col
	}
}

WM_CREATE :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	fmt.print("WM_CREATE\n")

	client_size := win32app.get_client_size(hwnd)
	bitmap_size = client_size / ZOOM

	hdc := win32.GetDC(hwnd)
	// todo defer win32.ReleaseDC(hwnd, hdc)

	PelsPerMeter :: 3780
	ColorSizeInBytes :: 4
	BitCount :: ColorSizeInBytes * 8

	bmiHeader := win32.BITMAPINFOHEADER {
		biSize = size_of(win32.BITMAPINFOHEADER),
		biWidth = bitmap_size.x,
		biHeight = bitmap_size.y,
		biPlanes = 1,
		biBitCount = BitCount,
		biCompression = win32.BI_RGB,
		biSizeImage = 0,
		biXPelsPerMeter = PelsPerMeter,
		biYPelsPerMeter = PelsPerMeter,
		biClrImportant = 0,
		biClrUsed = 0,
	}

	bitmap_handle = win32.HGDIOBJ(win32.CreateDIBSection(hdc, cast(^win32.BITMAPINFO)&bmiHeader, 0, &pvBits, nil, 0))

	if pvBits != nil {
		bitmap_count = bitmap_size.x * bitmap_size.y
		canvas.fill_screen(pvBits, bitmap_count, {150, 100, 50, 255})
	} else {
		bitmap_size = canvas.ZERO2
		bitmap_count = 0
	}

	win32.ReleaseDC(hwnd, hdc)

	timer1_id = win32.SetTimer(hwnd, win32app.IDT_TIMER1, 1000, nil)
	if timer1_id == 0 {
		win32app.show_error_and_panic("No timer 1")
	}

	return 0
}

WM_DESTROY :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	fmt.print("WM_DESTROY\n")

	if timer1_id != 0 {
		if !win32.KillTimer(hwnd, timer1_id) {
			win32.MessageBoxW(nil, L("Unable to kill timer1"), L("Error"), win32.MB_OK)
		}
	}
	if bitmap_handle != nil {
		win32.DeleteObject(bitmap_handle)
	}
	bitmap_handle = nil
	bitmap_size = canvas.ZERO2
	bitmap_count = 0
	pvBits = nil

	win32.PostQuitMessage(0)
	return 0
}

WM_ERASEBKGND :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	return 1
}

WM_CHAR :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	//fmt.printf("WM_CHAR %4d 0x%4x 0x%4x 0x%4x\n", wparam, wparam, win32.HIWORD(u32(lparam)), win32.LOWORD(u32(lparam)))
	switch wparam {
	case '\x1b':	win32.DestroyWindow(hwnd)
	case '1':		play_event(wolf.EVENT_WOLFENSTEINSFX_PLAYER_FOOTSTEPS_CARPET)
	case '2':		play_event(wolf.EVENT_WOLFENSTEINSFX_PLAYER_FOOTSTEPS_GRASS)
	case '3':		play_event(wolf.EVENT_WOLFENSTEINSFX_PLAYER_FOOTSTEPS_GRAVEL)
	case '4':		play_event(wolf.EVENT_WOLFENSTEINSFX_PLAYER_FOOTSTEPS_METAL)
	case '5':		play_event(wolf.EVENT_WOLFENSTEINSFX_PLAYER_FOOTSTEPS_ROOF)
	case '6':		play_event(wolf.EVENT_WOLFENSTEINSFX_PLAYER_FOOTSTEPS_SNOW)
	case '7':		play_event(wolf.EVENT_WOLFENSTEINSFX_PLAYER_FOOTSTEPS_STONE)
	case '8':		play_event(wolf.EVENT_WOLFENSTEINSFX_PLAYER_FOOTSTEPS_WATER)
	case '9':		play_event(wolf.EVENT_WOLFENSTEINSFX_PLAYER_FOOTSTEPS_WOOD)
	case '0':		play_event(wolf.EVENTGROUPCOUNT_WOLFENSTEINSFX_PLAYER_FOOTSTEPS + wolf.EVENT_WOLFENSTEINSFX_PLAYER_GASP)
	case '+':		play_event(wolf.EVENTGROUPCOUNT_WOLFENSTEINSFX_PLAYER_FOOTSTEPS + wolf.EVENT_WOLFENSTEINSFX_PLAYER_GIB)
	case 'm':		play_song()
	case:
	}
	return 0
}

WM_PAINT :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	ps: win32.PAINTSTRUCT
	hdc_target := win32.BeginPaint(hwnd, &ps) // todo check if defer can be used for EndPaint
	assert(hdc_target == ps.hdc)
	client_size := win32app.get_client_size(hwnd)
	assert(client_size == win32app.get_rect_size(&ps.rcPaint))

	hdc_source := win32app.CreateCompatibleDC(hdc_target)
	win32.SelectObject(hdc_source, bitmap_handle)
	win32.StretchBlt(
		hdc_target, 0, 0, client_size.x, client_size.y,
		hdc_source, 0, 0, bitmap_size.x, bitmap_size.y,
		win32.SRCCOPY,
	)
	win32app.DeleteDC(hdc_source)

	win32.EndPaint(hwnd, &ps)
	return 0
}

WM_TIMER :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	switch (wparam)
	{
	case win32app.IDT_TIMER1:
	{
	    fmod.FMOD_System_GetCPUUsage(system, &dsp, &stream, &geometry, &update, &total)
	    fmod.FMOD_System_GetChannelsPlaying(system, &channels_playing)
		newtitle := fmt.tprintf("%s cpu %v channels %v\n", title, total, channels_playing)
		win32.SetWindowTextW(hwnd, win32.utf8_to_wstring(newtitle))
	}
	}
	return 0
}

WM_MOUSEMOVE :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	return handle_input(hwnd, wparam, lparam)
}

WM_LBUTTONDOWN :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	return handle_input(hwnd, wparam, lparam)
}

WM_RBUTTONDOWN :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	return handle_input(hwnd, wparam, lparam)
}

handle_input :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	switch wparam {
	case 1:
		pos := decode_scrpos(lparam)
		setdot(pos, canvas.COLOR_RED)
		win32.InvalidateRect(hwnd, nil, false)
	case 2:
		pos := decode_scrpos(lparam)
		setdot(pos, canvas.COLOR_BLUE)
		win32.InvalidateRect(hwnd, nil, false)
	case 3:
		pos := decode_scrpos(lparam)
		setdot(pos, canvas.COLOR_GREEN)
		win32.InvalidateRect(hwnd, nil, false)
	case 4:
		fmt.printf("input %v %d\n", decode_scrpos(lparam), wparam)
	case:
		//fmt.printf("input %v %d\n", decode_scrpos(lparam), wparam)
	}
	return 0
}

wndproc :: proc "stdcall" ( hwnd: win32.HWND, msg: win32.UINT, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	context = runtime.default_context()
	switch msg {
	case win32.WM_CREATE:		return WM_CREATE(hwnd, wparam, lparam)
	case win32.WM_DESTROY:		return WM_DESTROY(hwnd, wparam, lparam)
	case win32.WM_ERASEBKGND:	return WM_ERASEBKGND(hwnd, wparam, lparam)
	//case win32.WM_SIZE:			return WM_SIZE(hwnd, wparam, lparam)
	case win32.WM_PAINT:		return WM_PAINT(hwnd, wparam, lparam)
	case win32.WM_CHAR:			return WM_CHAR(hwnd, wparam, lparam)
	case win32.WM_MOUSEMOVE:	return WM_MOUSEMOVE(hwnd, wparam, lparam)
	case win32.WM_LBUTTONDOWN:	return WM_LBUTTONDOWN(hwnd, wparam, lparam)
	case win32.WM_RBUTTONDOWN:	return WM_RBUTTONDOWN(hwnd, wparam, lparam)
	case win32.WM_TIMER:		return WM_TIMER(hwnd, wparam, lparam)
	case:						return win32.DefWindowProcW(hwnd, msg, wparam, lparam)
	}
}

main :: proc() {

	res := fmod.FMOD_EventSystem_Create(&eventsys)
	if res != fmod.FMOD_RESULT.FMOD_OK {
		fmt.printf("%v %v\n", fmod.FMOD_EventSystem_Create, res)
		return
	}
	defer fmod.FMOD_EventSystem_Release(eventsys)

	version: u32 = 0
	res = fmod.FMOD_EventSystem_GetVersion(eventsys, &version)
	if res != fmod.FMOD_RESULT.FMOD_OK {
		fmt.printf("%v %v\n", fmod.FMOD_EventSystem_GetVersion, res)
		return
	}
	fmod_version := transmute(fmod.FMOD_VERSION)version

	res = fmod.FMOD_EventSystem_GetSystemObject(eventsys, &system)
	if res != fmod.FMOD_RESULT.FMOD_OK {
		fmt.printf("%v %v\n", fmod.FMOD_EventSystem_GetSystemObject, res)
		return
	}
	driver_index: i32 = 0
	res = fmod.FMOD_System_GetDriver(system, &driver_index)
	if res != fmod.FMOD_RESULT.FMOD_OK {
		fmt.printf("%v %v\n", fmod.FMOD_System_GetDriver, res)
		return
	}
	caps: fmod.FMOD_CAPS_ENUM
	outputrate: i32
	speakermode: fmod.FMOD_SPEAKERMODE
	res = fmod.FMOD_System_GetDriverCaps(
		system,
		driver_index,
		&caps,
		&outputrate,
		&speakermode,
	)
	if res != fmod.FMOD_RESULT.FMOD_OK {
		fmt.printf("FMOD_System_GetDriverCaps %v\n", res)
		return
	}
	res = fmod.FMOD_System_SetSpeakerMode(system, speakermode)
	if ((caps & .HARDWARE_EMULATED) == .HARDWARE_EMULATED) {
		/* The user has the 'Acceleration' slider set to off!  This is really bad for latency!. */
		/* You might want to warn the user about this. */
		fmt.print("HARDWARE_EMULATED\n")
		res = fmod.FMOD_System_SetDSPBufferSize(system, 1024, 10)
		/* At 48khz, the latency between issuing an fmod command and hearing it will now be about 213ms. */
		if res != fmod.FMOD_RESULT.FMOD_OK {
			fmt.printf("FMOD_System_SetDSPBufferSize %v\n", res)
			return
		}
	}

	//initflags: u32 = FMOD_INIT_FLAGS
	res = fmod.FMOD_EventSystem_Init(eventsys, FMOD_MAXCHANNELS, FMOD_INIT_FLAGS, nil, fmod.FMOD_EVENT_INIT_NORMAL)
	if res == .FMOD_ERR_OUTPUT_CREATEBUFFER {
		fmt.print("ERR_OUTPUT_CREATEBUFFER Switch it back to stereo...\n")
		/* Ok, the speaker mode selected isn't supported by this soundcard.  Switch it back to stereo... */
		speakermode = fmod.FMOD_SPEAKERMODE.FMOD_SPEAKERMODE_STEREO;
		res = fmod.FMOD_System_SetSpeakerMode(system, speakermode)
		res = fmod.FMOD_EventSystem_Init(eventsys, FMOD_MAXCHANNELS, FMOD_INIT_FLAGS, nil, fmod.FMOD_EVENT_INIT_NORMAL)
	}
	if res != fmod.FMOD_RESULT.FMOD_OK {
		fmt.printf("FMOD_EventSystem_Init %v\n", res)
		return
	}
	res = fmod.FMOD_System_Set3DSettings(system, 1.0, DistanceFactor, 1.0)
	if res != fmod.FMOD_RESULT.FMOD_OK {
		fmt.printf("FMOD_System_Set3DSettings %v\n", res)
		return
	}

	{
		name := "WolfensteinSFX.fev"
		c_str := strings.clone_to_cstring(name, context.temp_allocator)
		res = fmod.FMOD_EventSystem_Load(eventsys, c_str, nil, nil)
		if res != fmod.FMOD_RESULT.FMOD_OK {
			fmt.printf("FMOD_EventSystem_Load %v\n", res)
			return
		}
	}

	num_events: i32 = 0
	res = fmod.FMOD_EventSystem_GetNumEvents(eventsys, &num_events)
	if res != fmod.FMOD_RESULT.FMOD_OK {
		fmt.printf("FMOD_EventSystem_GetNumEvents %v\n", res)
		return
	}
	fmt.printf("Events : %v\n", num_events)

	/*
	_events = new Event[WolfensteinSFX.EVENTCATEGORYCOUNT_WOLFENSTEINSFX_MASTER];
	for (int i = 0; i < WolfensteinSFX.EVENTCATEGORYCOUNT_WOLFENSTEINSFX_MASTER; i++)
	{
		_events[i] = _audioSystem.GetEventById(i);
	}
	*/

	//event : ^fmod.FMOD_EVENT = nil

	//for i:u32; i in 0..<wolf.EVENTCOUNT_WOLFENSTEINSFX {
	for i : u32 = 0; i < wolf.EVENTCOUNT_WOLFENSTEINSFX; i += 1 {
		res = fmod.FMOD_EventSystem_GetEventBySystemID(eventsys,
			i,
			fmod.FMOD_EVENT_DEFAULT, &events[i])
		if res != fmod.FMOD_RESULT.FMOD_OK {
			fmt.printf("FMOD_EventSystem_GetEventBySystemID %v event id %d\n", res, i)
			return
		}
	}

	//title := fmt.tprintf(
	title = fmt.aprintf(
		"%s Version : %d.%d.%d (0x%x)\n",
		TITLE,
		fmod_version.Major,
		fmod_version.Minor,
		fmod_version.Development,
		version,
	)

	settings : win32app.window_settings = {
		title = title,
		window_size = {WIDTH, HEIGHT},
		center = CENTER,
	}
	win32app.run(&settings, wndproc)
}

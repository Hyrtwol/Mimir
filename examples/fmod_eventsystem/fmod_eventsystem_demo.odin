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
import win32app "shared:tlc/win32app"
import canvas   "shared:tlc/canvas"
import "shared:fmod"
import "shared:tlc/wolf"

L :: intrinsics.constant_utf16_cstring

TITLE 	:: "FMOD Event System"
WIDTH  	:: 64 * 8
HEIGHT 	:: WIDTH * 9 / 16
CENTER  :: true
ZOOM  	:: 8

max_channels :: 32
init_flags :: fmod.FMOD_INIT_3D_RIGHTHANDED
DistanceFactor :: 1.0

screen_buffer  :: canvas.screen_buffer

bitmap_handle : win32.HGDIOBJ // win32.HBITMAP
bitmap_size   : win32app.int2
bitmap_count  : i32
pvBits        : screen_buffer
pixel_size    : win32app.int2 : {ZOOM, ZOOM}

//dib           : canvas.DIB
timer1_id     : win32.UINT_PTR
timer2_id     : win32.UINT_PTR

system: ^fmod.FMOD_SYSTEM = nil
eventsys: ^fmod.FMOD_EVENTSYSTEM = nil

events: [wolf.EVENTCOUNT_WOLFENSTEINSFX]^fmod.FMOD_EVENT
song: ^fmod.FMOD_SOUND = nil

title: string
dsp, stream, geometry, update, total: f32
channels_playing: i32

clear_color: canvas.byte4 : {150, 100, 50, 255}

play_event :: proc(event_id: i32) {
	event: ^fmod.FMOD_EVENT = events[event_id]
	if event == nil {
		fmt.printf("event_id %d is nil\n", event_id)
		return
	}

	res: fmod.FMOD_RESULT

	res = fmod.FMOD_Event_Stop(event, 1)
	if res != .FMOD_OK {
		fmt.printf("%v %v\n", fmod.FMOD_EventSystem_Load, res)
		return
	}

	position := fmod.FMOD_VECTOR{0, 0, 0}
	velocity := fmod.FMOD_VECTOR{0, 0, 0}
	res = fmod.FMOD_Event_Set3DAttributes(event, &position, &velocity, nil)

	res = fmod.FMOD_Event_Start(event)
	if res != .FMOD_OK {
		fmt.printf("%v %v\n", fmod.FMOD_EventSystem_Load, res)
		return
	}
}

play_song :: proc() {
	res: fmod.FMOD_RESULT
	if song == nil {
		res = fmod.FMOD_System_CreateSound(system, "Ktulu.xm", fmod.FMOD_HARDWARE | fmod.FMOD_2D, nil, &song)
		if res != .FMOD_OK {
			fmt.printf("FMOD_System_CreateSound %v\n", res)
			return
		}
	}
	if song != nil {
		channel: ^fmod.FMOD_CHANNEL
		res = fmod.FMOD_System_PlaySound(system, fmod.FMOD_CHANNELINDEX.FMOD_CHANNEL_FREE, song, 0, &channel)
		if res != .FMOD_OK {
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
	fmt.printf("bitmap_size=%v\n", bitmap_size)

	hdc := win32.GetDC(hwnd)
	// todo defer win32.ReleaseDC(hwnd, hdc)

	PelsPerMeter :: 3780
	ColorSizeInBytes :: 4
	BitCount :: ColorSizeInBytes * 8

	bmi_header := win32.BITMAPINFOHEADER {
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

	bitmap_handle = win32.HGDIOBJ(win32.CreateDIBSection(hdc, cast(^win32.BITMAPINFO)&bmi_header, 0, &pvBits, nil, 0))

	if pvBits != nil {
		bitmap_count = bitmap_size.x * bitmap_size.y
		canvas.fill_screen(pvBits, bitmap_count, clear_color)
	} else {
		bitmap_size = canvas.ZERO2
		bitmap_count = 0
	}

	win32.ReleaseDC(hwnd, hdc)

	timer1_id = win32.SetTimer(hwnd, win32app.IDT_TIMER1, 1000, nil)
	if timer1_id == 0 {
		win32app.show_error_and_panic("No timer 1")
	}

	timer2_id = win32.SetTimer(hwnd, win32app.IDT_TIMER2, 50, nil)
	if timer2_id == 0 {
		win32app.show_error_and_panic("No timer 2")
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
	if timer2_id != 0 {
		if !win32.KillTimer(hwnd, timer2_id) {
			win32.MessageBoxW(nil, L("Unable to kill timer2"), L("Error"), win32.MB_OK)
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

WM_CHAR :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	//fmt.printf("WM_CHAR %4d 0x%4x 0x%4x 0x%4x\n", wparam, wparam, win32.HIWORD(u32(lparam)), win32.LOWORD(u32(lparam)))
	// odinfmt: disable
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
	// odinfmt: enable
	return 0
}

spect_size :: 64
spec_left: [spect_size]f32
spec_right: [spect_size]f32
spectrum: [spect_size]f32
fft_window :: fmod.FMOD_DSP_FFT_WINDOW.FMOD_DSP_FFT_WINDOW_TRIANGLE
//fft_window :: fmod.FMOD_DSP_FFT_WINDOW.FMOD_DSP_FFT_WINDOW_BLACKMAN

// https://www.wolframalpha.com/input?i=y%3D+log10%28x%29*20+range+0..1
lin2dB :: proc(linear: f32) -> f32 {return math.clamp(math.log10(linear) * 20.0, -80.0, 0.0)}

WM_TIMER :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	switch (wparam)
	{
	case win32app.IDT_TIMER1:
		{
			fmod.FMOD_System_GetCPUUsage(system, &dsp, &stream, &geometry, &update, &total)
			fmod.FMOD_System_GetChannelsPlaying(system, &channels_playing)
			new_title := fmt.tprintf("%s cpu %v channels %v\n", title, total, channels_playing)
			win32.SetWindowTextW(hwnd, win32.utf8_to_wstring(new_title))
		}
	case win32app.IDT_TIMER2:
		{
			fmod.FMOD_System_GetSpectrum(system, &spec_left[0], spect_size, 0, fft_window)
			fmod.FMOD_System_GetSpectrum(system, &spec_right[0], spect_size, 1, fft_window)

			scale : f32 = 0.25 //f32(bitmap_size.y)
			for i in 0 ..< spect_size {
				spectrum[i] = (80 + lin2dB((spec_left[i] + spec_right[i])*0.5)) * scale
			}

			col: canvas.byte4
			for y in 0 ..< spect_size {
				i := i32(y) * bitmap_size.x
				for x in 0 ..< spect_size {
					if f32(y) > spectrum[x] {col = clear_color} else {col = canvas.COLOR_GREEN}
					//pvBits[i] = col
					if i >= 0 && i < bitmap_count {pvBits[i] = col}
					i += 1
				}
			}


			win32.InvalidateRect(hwnd, nil, false)
			//win32.InvalidateRect(hwnd)
			//win32app.RedrawWindowNow(hwnd)
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

wndproc :: proc "system" (hwnd: win32.HWND, msg: win32.UINT, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	context = runtime.default_context()
	// odinfmt: disable
	switch msg {
	case win32.WM_CREATE:		return WM_CREATE(hwnd, wparam, lparam)
	case win32.WM_DESTROY:		return WM_DESTROY(hwnd, wparam, lparam)
	case win32.WM_ERASEBKGND:	return 1
	case win32.WM_PAINT:		return canvas.wm_paint_dib(hwnd, bitmap_handle, bitmap_size)
	case win32.WM_CHAR:			return WM_CHAR(hwnd, wparam, lparam)
	case win32.WM_MOUSEMOVE:	return WM_MOUSEMOVE(hwnd, wparam, lparam)
	case win32.WM_LBUTTONDOWN:	return WM_LBUTTONDOWN(hwnd, wparam, lparam)
	case win32.WM_RBUTTONDOWN:	return WM_RBUTTONDOWN(hwnd, wparam, lparam)
	case win32.WM_TIMER:		return WM_TIMER(hwnd, wparam, lparam)
	case:						return win32.DefWindowProcW(hwnd, msg, wparam, lparam)
	}
	// odinfmt: enable
}

main :: proc() {

	res := fmod.FMOD_EventSystem_Create(&eventsys)
	if res != .FMOD_OK {
		fmt.printf("%v %v\n", fmod.FMOD_EventSystem_Create, res)
		return
	}
	defer fmod.FMOD_EventSystem_Release(eventsys)

	fmod_version: fmod.FMOD_VERSION
	res = fmod.FMOD_EventSystem_GetVersion(eventsys, &fmod_version)
	if res != .FMOD_OK {
		fmt.printf("%v %v\n", fmod.FMOD_EventSystem_GetVersion, res)
		return
	}

	res = fmod.FMOD_EventSystem_GetSystemObject(eventsys, &system)
	if res != .FMOD_OK {
		fmt.printf("%v %v\n", fmod.FMOD_EventSystem_GetSystemObject, res)
		return
	}
	driver_index: i32 = 0
	res = fmod.FMOD_System_GetDriver(system, &driver_index)
	if res != .FMOD_OK {
		fmt.printf("%v %v\n", fmod.FMOD_System_GetDriver, res)
		return
	}
	driver_caps: fmod.FMOD_CAPS
	output_rate: i32
	speaker_mode: fmod.FMOD_SPEAKERMODE
	res = fmod.FMOD_System_GetDriverCaps(system, driver_index, &driver_caps, &output_rate, &speaker_mode)
	if res != .FMOD_OK {
		fmt.printf("%v %v\n", fmod.FMOD_System_GetDriverCaps, res)
		return
	}
	fmt.printf("caps: %v\n", driver_caps)

	res = fmod.FMOD_System_SetSpeakerMode(system, speaker_mode)
	if .HARDWARE_EMULATED in driver_caps {
		/* The user has the 'Acceleration' slider set to off!  This is really bad for latency!. */
		/* You might want to warn the user about this. */
		fmt.print("HARDWARE_EMULATED\n")
		res = fmod.FMOD_System_SetDSPBufferSize(system, 1024, 10)
		/* At 48khz, the latency between issuing an fmod command and hearing it will now be about 213ms. */
		if res != .FMOD_OK {
			fmt.printf("%v %v\n", fmod.FMOD_System_SetDSPBufferSize, res)
			return
		}
	}

	res = fmod.FMOD_EventSystem_Init(eventsys, max_channels, init_flags, nil, fmod.FMOD_EVENT_INIT_NORMAL)
	if res == .FMOD_ERR_OUTPUT_CREATEBUFFER {
		fmt.print("ERR_OUTPUT_CREATEBUFFER Switch it back to stereo...\n")
		/* Ok, the speaker mode selected isn't supported by this soundcard.  Switch it back to stereo... */
		speaker_mode = fmod.FMOD_SPEAKERMODE.FMOD_SPEAKERMODE_STEREO
		res = fmod.FMOD_System_SetSpeakerMode(system, speaker_mode)
		res = fmod.FMOD_EventSystem_Init(eventsys, max_channels, init_flags, nil, fmod.FMOD_EVENT_INIT_NORMAL)
	}
	if res != .FMOD_OK {
		fmt.printf("%v %v\n", fmod.FMOD_EventSystem_Init, res)
		return
	}
	res = fmod.FMOD_System_Set3DSettings(system, 1.0, DistanceFactor, 1.0)
	if res != .FMOD_OK {
		fmt.printf("%v %v\n", fmod.FMOD_System_Set3DSettings, res)
		return
	}

	//name := "WolfensteinSFX.fev"
	//c_str := strings.clone_to_cstring(name, context.temp_allocator)
	//res = fmod.FMOD_EventSystem_Load(eventsys, c_str, nil, nil)
	res = fmod.FMOD_EventSystem_Load(eventsys, "WolfensteinSFX.fev", nil, nil)
	if res != .FMOD_OK {
		fmt.printf("%v %v\n", fmod.FMOD_EventSystem_Load, res)
		return
	}

	num_events: i32 = 0
	res = fmod.FMOD_EventSystem_GetNumEvents(eventsys, &num_events)
	if res != .FMOD_OK {
		fmt.printf("%v %v\n", fmod.FMOD_EventSystem_GetNumEvents, res)
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
	for i: u32 = 0; i < wolf.EVENTCOUNT_WOLFENSTEINSFX; i += 1 {
		res = fmod.FMOD_EventSystem_GetEventBySystemID(eventsys, i, fmod.FMOD_EVENT_DEFAULT, &events[i])
		if res != .FMOD_OK {
			fmt.printf("%v %v event id %d\n", fmod.FMOD_EventSystem_GetEventBySystemID, res, i)
			return
		}
	}

	title = fmt.aprintf("%s Version : %d.%d.%d (0x%x)\n", TITLE, fmod_version.Major, fmod_version.Minor, fmod_version.Development, transmute(u32)fmod_version)
	defer delete(title)

	settings: win32app.window_settings = {
		title       = title,
		window_size = {WIDTH, HEIGHT},
		center      = CENTER,
	}
	win32app.run(&settings, wndproc)
}

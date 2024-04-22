package main

import          "core:fmt"
import          "core:intrinsics"
import          "core:math"
import          "core:math/noise"
import          "core:runtime"
import win32	"core:sys/windows"
import			"libs:tlc/win32app"
import cv		"libs:tlc/canvas"
import fmod		"shared:fmodex"
import			"libs:tlc/wolf"

L :: intrinsics.constant_utf16_cstring

TITLE 	:: "FMOD Event System"
WIDTH  	:: 64 * 8
HEIGHT 	:: WIDTH * 9 / 16
ZOOM  	:: 8

max_channels :: 32
init_flags :: fmod.FMOD_INIT_3D_RIGHTHANDED
DistanceFactor :: 1.0

screen_buffer  :: cv.screen_buffer

bitmap_handle : win32.HGDIOBJ // win32.HBITMAP
bitmap_size   : win32app.int2
bitmap_count  : i32
pvBits        : screen_buffer
pixel_size    : win32app.int2 : {ZOOM, ZOOM}

//dib           : cv.DIB
timer1_id     : win32.UINT_PTR
timer2_id     : win32.UINT_PTR

system: ^fmod.FMOD_SYSTEM = nil
eventsys: ^fmod.FMOD_EVENTSYSTEM = nil

events: [wolf.EVENTCOUNT_WOLFENSTEINSFX]^fmod.FMOD_EVENT
song: ^fmod.FMOD_SOUND = nil

title: string
dsp, stream, geometry, update, total: f32
channels_playing: i32

clear_color: cv.byte4 : {150, 100, 50, 255}

play_event :: proc(event_id: i32) {
	event: ^fmod.FMOD_EVENT = events[event_id]
	if event == nil {
		fmt.eprintfln("event_id %d is nil", event_id)
		return
	}

	res: fmod.FMOD_RESULT

	res = fmod.FMOD_Event_Stop(event, 1)
	if res != .FMOD_OK {
		fmt.eprintfln("FMOD_Event_Stop:", res)
		return
	}

	position := fmod.FMOD_VECTOR{0, 0, 0}
	velocity := fmod.FMOD_VECTOR{0, 0, 0}
	res = fmod.FMOD_Event_Set3DAttributes(event, &position, &velocity, nil)

	res = fmod.FMOD_Event_Start(event)
	if res != .FMOD_OK {
		fmt.eprintfln("FMOD_EventSystem_Load", res)
		return
	}
}

play_song :: proc() {
	res: fmod.FMOD_RESULT
	if song == nil {
		res = fmod.FMOD_System_CreateSound(system, "Ktulu.xm", fmod.FMOD_HARDWARE | fmod.FMOD_2D, nil, &song)
		if res != .FMOD_OK {
			fmt.eprintfln("FMOD_System_CreateSound:", res)
			return
		}
	}
	if song != nil {
		channel: ^fmod.FMOD_CHANNEL
		res = fmod.FMOD_System_PlaySound(system, fmod.FMOD_CHANNELINDEX.FMOD_CHANNEL_FREE, song, 0, &channel)
		if res != .FMOD_OK {
			fmt.eprintfln("FMOD_System_PlaySound:", res)
			return
		}
		fmt.println("FMOD_System_PlaySound channel:", channel)
	}
}

decode_scrpos :: proc(lparam: win32.LPARAM) -> win32app.int2 {
	scrpos := win32app.decode_lparam(lparam) / ZOOM
	scrpos.y = bitmap_size.y - 1 - scrpos.y
	return scrpos
}

set_dot :: proc(pos: win32app.int2, col: cv.byte4) {
	i := pos.y * bitmap_size.x + pos.x
	if i >= 0 && i < bitmap_count {
		pvBits[i] = col
	}
}

WM_CREATE :: proc(hwnd: win32.HWND, lparam: win32.LPARAM) -> win32.LRESULT {
	fmt.println(#procedure, hwnd)

	timer1_id = win32app.set_timer(hwnd, win32app.IDT_TIMER1, 1000)
	timer2_id = win32app.set_timer(hwnd, win32app.IDT_TIMER2, 50)

	client_size := win32app.get_client_size(hwnd)
	bitmap_size = client_size / ZOOM
	fmt.println("bitmap_size:", bitmap_size)

	hdc := win32.GetDC(hwnd)
	defer win32.ReleaseDC(hwnd, hdc)

	color_byte_count :: 4
	color_bit_count :: color_byte_count * 8
	bmi_header := win32app.create_bmi_header(bitmap_size, false, color_bit_count)

	bitmap_handle = win32.HGDIOBJ(win32.CreateDIBSection(hdc, cast(^win32.BITMAPINFO)&bmi_header, 0, &pvBits, nil, 0))

	if pvBits != nil {
		bitmap_count = bitmap_size.x * bitmap_size.y
		cv.fill_screen(pvBits, bitmap_count, clear_color)
	} else {
		bitmap_size = {0, 0}
		bitmap_count = 0
	}

	return 0
}

WM_DESTROY :: proc(hwnd: win32.HWND) -> win32.LRESULT {
	fmt.println(#procedure, hwnd)
	win32app.kill_timer(hwnd, &timer1_id)
	win32app.kill_timer(hwnd, &timer2_id)
	win32app.delete_object(&bitmap_handle)
	bitmap_size = {0, 0}
	bitmap_count = 0
	pvBits = nil
	win32app.post_quit_message(0)
	return 0
}

WM_CHAR :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	//fmt.printfln("%s %4d 0x%4x 0x%4x 0x%4x", #procedure, wparam, wparam, win32.HIWORD(u32(lparam)), win32.LOWORD(u32(lparam)))
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

spectrum_size :: 64
spectrum_left: [spectrum_size]f32
spectrum_right: [spectrum_size]f32
spectrum: [spectrum_size]f32
fft_window :: fmod.FMOD_DSP_FFT_WINDOW.FMOD_DSP_FFT_WINDOW_TRIANGLE
//fft_window :: fmod.FMOD_DSP_FFT_WINDOW.FMOD_DSP_FFT_WINDOW_BLACKMAN

// https://www.wolframalpha.com/input?i=y%3D+log10%28x%29*20+range+0..1
lin2dB :: proc(linear: f32) -> f32 {return math.clamp(math.log10(linear) * 20.0, -80.0, 0.0)}

WM_TIMER :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	switch win32.UINT_PTR(wparam)
	{
	case win32app.IDT_TIMER1:
		{
			fmod.FMOD_System_GetCPUUsage(system, &dsp, &stream, &geometry, &update, &total)
			fmod.FMOD_System_GetChannelsPlaying(system, &channels_playing)
			new_title := fmt.tprintf("%s cpu %v channels %v", title, total, channels_playing)
			win32.SetWindowTextW(hwnd, win32.utf8_to_wstring(new_title))
		}
	case win32app.IDT_TIMER2:
		{
			fmod.FMOD_System_GetSpectrum(system, &spectrum_left[0], spectrum_size, 0, fft_window)
			fmod.FMOD_System_GetSpectrum(system, &spectrum_right[0], spectrum_size, 1, fft_window)

			scale: f32 = 0.25 //f32(bitmap_size.y)
			for i in 0 ..< spectrum_size {
				spectrum[i] = (80 + lin2dB((spectrum_left[i] + spectrum_right[i]) * 0.5)) * scale
			}

			col: cv.byte4
			for y in 0 ..< spectrum_size {
				i := i32(y) * bitmap_size.x
				for x in 0 ..< spectrum_size {
					if f32(y) > spectrum[x] {col = clear_color} else {col = cv.COLOR_GREEN}
					//pvBits[i] = col
					if i >= 0 && i < bitmap_count {pvBits[i] = col}
					i += 1
				}
			}


			win32.InvalidateRect(hwnd, nil, false)
			//win32.InvalidateRect(hwnd)
			win32app.redraw_window(hwnd)
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
		set_dot(pos, cv.COLOR_RED)
		win32.InvalidateRect(hwnd, nil, false)
	case 2:
		pos := decode_scrpos(lparam)
		set_dot(pos, cv.COLOR_BLUE)
		win32.InvalidateRect(hwnd, nil, false)
	case 3:
		pos := decode_scrpos(lparam)
		set_dot(pos, cv.COLOR_GREEN)
		win32.InvalidateRect(hwnd, nil, false)
	case 4:
		fmt.printfln("input %v %d", decode_scrpos(lparam), wparam)
	case:
	//fmt.printfln("input %v %d", decode_scrpos(lparam), wparam)
	}
	return 0
}

wndproc :: proc "system" (hwnd: win32.HWND, msg: win32.UINT, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	context = runtime.default_context()
	// odinfmt: disable
	switch msg {
	case win32.WM_CREATE:		return WM_CREATE(hwnd, lparam)
	case win32.WM_DESTROY:		return WM_DESTROY(hwnd)
	case win32.WM_ERASEBKGND:	return 1
	case win32.WM_PAINT:		return cv.wm_paint_dib(hwnd, bitmap_handle, bitmap_size)
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
		fmt.eprintln("FMOD_EventSystem_Create:", res)
		return
	}
	defer fmod.FMOD_EventSystem_Release(eventsys)

	fmod_version: fmod.FMOD_VERSION
	res = fmod.FMOD_EventSystem_GetVersion(eventsys, &fmod_version)
	if res != .FMOD_OK {
		fmt.eprintln("FMOD_EventSystem_GetVersion:", res)
		return
	}

	res = fmod.FMOD_EventSystem_GetSystemObject(eventsys, &system)
	if res != .FMOD_OK {
		fmt.eprintln("FMOD_EventSystem_GetSystemObject:", res)
		return
	}
	driver_index: i32 = 0
	res = fmod.FMOD_System_GetDriver(system, &driver_index)
	if res != .FMOD_OK {
		fmt.eprintln("FMOD_System_GetDriver:", res)
		return
	}
	driver_caps: fmod.FMOD_CAPS
	output_rate: i32
	speaker_mode: fmod.FMOD_SPEAKERMODE
	res = fmod.FMOD_System_GetDriverCaps(system, driver_index, &driver_caps, &output_rate, &speaker_mode)
	if res != .FMOD_OK {
		fmt.eprintln("FMOD_System_GetDriverCaps:", res)
		return
	}
	fmt.println("caps:", driver_caps)

	res = fmod.FMOD_System_SetSpeakerMode(system, speaker_mode)
	if .HARDWARE_EMULATED in driver_caps {
		/* The user has the 'Acceleration' slider set to off!  This is really bad for latency!. */
		/* You might want to warn the user about this. */
		fmt.println("HARDWARE_EMULATED")
		res = fmod.FMOD_System_SetDSPBufferSize(system, 1024, 10)
		/* At 48khz, the latency between issuing an fmod command and hearing it will now be about 213ms. */
		if res != .FMOD_OK {
			fmt.eprintln("FMOD_System_SetDSPBufferSize:", res)
			return
		}
	}

	res = fmod.FMOD_EventSystem_Init(eventsys, max_channels, init_flags, nil, fmod.FMOD_EVENT_INIT_NORMAL)
	if res == .FMOD_ERR_OUTPUT_CREATEBUFFER {
		fmt.println("ERR_OUTPUT_CREATEBUFFER Switch it back to stereo...")
		/* Ok, the speaker mode selected isn't supported by this soundcard.  Switch it back to stereo... */
		speaker_mode = fmod.FMOD_SPEAKERMODE.FMOD_SPEAKERMODE_STEREO
		res = fmod.FMOD_System_SetSpeakerMode(system, speaker_mode)
		if res != .FMOD_OK {
			fmt.eprintln("FMOD_System_SetSpeakerMode:", res)
			return
		}
		res = fmod.FMOD_EventSystem_Init(eventsys, max_channels, init_flags, nil, fmod.FMOD_EVENT_INIT_NORMAL)
	}
	if res != .FMOD_OK {
		fmt.eprintln("FMOD_EventSystem_Init:", res)
		return
	}
	res = fmod.FMOD_System_Set3DSettings(system, 1.0, DistanceFactor, 1.0)
	if res != .FMOD_OK {
		fmt.eprintln("FMOD_System_Set3DSettings:", res)
		return
	}

	//name := "WolfensteinSFX.fev"
	//c_str := strings.clone_to_cstring(name, context.temp_allocator)
	//res = fmod.FMOD_EventSystem_Load(eventsys, c_str, nil, nil)
	res = fmod.FMOD_EventSystem_Load(eventsys, "WolfensteinSFX.fev", nil, nil)
	if res != .FMOD_OK {
		fmt.eprintln("FMOD_EventSystem_Load:", res)
		return
	}

	num_events: i32 = 0
	res = fmod.FMOD_EventSystem_GetNumEvents(eventsys, &num_events)
	if res != .FMOD_OK {
		fmt.eprintln("FMOD_EventSystem_GetNumEvents:", res)
		return
	}
	fmt.println("Events:", num_events)

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
			fmt.eprintln("FMOD_EventSystem_GetEventBySystemID", res, i)
			return
		}
	}

	title = fmt.aprintf("%s Version : %d.%d.%d (0x%x)", TITLE, fmod_version.Major, fmod_version.Minor, fmod_version.Development, transmute(u32)fmod_version)
	defer delete(title)

	settings := win32app.create_window_settings(title, WIDTH, HEIGHT, wndproc)
	win32app.run(&settings)
}

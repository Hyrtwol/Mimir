// +vet
package audioplayer

import "core:fmt"
import "base:intrinsics"
import "core:math"
import "core:math/rand"
import "base:runtime"
//import "core:math/noise"
//import "core:mem"
//import "core:simd"
//import "core:time"
import win32 "core:sys/windows"
import cv "libs:tlc/canvas"
import win32app "libs:tlc/win32app"
import f "shared:flac"

_ :: f

// https://learn.microsoft.com/en-us/windows/win32/multimedia/example-of-writing-waveform-data
// https://github.com/cornyum/Windows-programming-5th/blob/master/Chap22/SineWave/SineWave.c
// D:\dev\pascal\Delphi7\Audio\PerlinNoisePlayer\PerlinNoisePlayerMain.pas
// https://www.codeproject.com/articles/6543/playing-wav-files-using-the-windows-multi-media-li
// https://www.markheath.net/post/waveoutopen-callbacks-in-naudio

// aliases
L				:: intrinsics.constant_utf16_cstring
wstring			:: win32.wstring
utf8_to_wstring	:: win32.utf8_to_wstring
color			:: [4]u8
int2			:: [2]i32

// constants
TITLE :: "Audio Player"
WIDTH :: 640
HEIGHT :: WIDTH * 9 / 16
ZOOM :: 8

// audio

sample :: i16

FORMAT_TAG :: win32.WAVE_FORMAT_PCM
CHANNELS :: 2
SAMPLES_PER_SEC :: 44100
BITS_PER_SAMPLE :: size_of(sample) * 8

NUM_BUFFERS :: 8

WM_STOP_PLAY :: win32.WM_USER
WM_PREPARE_NEXT_BUFFER :: win32.WM_USER + 1

WAVE_DISPLAY_WIDTH :: 512
WAVE_DISPLAY_HEIGHT :: 128
WAVE_DISPLAY_COUNT :: WAVE_DISPLAY_WIDTH * WAVE_DISPLAY_HEIGHT

NOISE_DISPLAY_WIDTH :: 512
NOISE_DISPLAY_HEIGHT :: 512
NOISE_DISPLAY_COUNT :: NOISE_DISPLAY_WIDTH * NOISE_DISPLAY_HEIGHT

NumSamples :: WAVE_DISPLAY_WIDTH * 4
MaxIndex :: NumSamples - 1
MaxPeak :: 255

TWaveDisplay :: [WAVE_DISPLAY_COUNT]i32
PWaveDisplay :: ^TWaveDisplay

TNoiseDisplay :: [NOISE_DISPLAY_COUNT]i32
PNoiseDisplay :: ^TNoiseDisplay

TDoBuffer :: proc(Buf: rawptr)

dib: win32app.DIB
colidx := 1
cols := cv.C64_COLORS

Headers: [NUM_BUFFERS]win32.WAVEHDR
BufferLength: u32
CurrentBuffer, Ending: i32
waveout: win32.HWAVEOUT
Closing: bool

WaveFormatEx: win32.WAVEFORMATEX

//BmpLeft: i32

WaveDisplayBits: PWaveDisplay
WaveDisplayTop: i32

NoiseDisplayBits: PWaveDisplay
NoiseDisplayTop: i32

// d, Radius: f32
// x, y, z: f32

DoBuffer := DoBuffer3

set_dot :: #force_inline proc "contextless" (pos: win32app.int2, col: cv.byte4) {
	cv.canvas_set_dot(&dib, pos, col)
}

DoBuffer1 :: proc(header: ^win32.WAVEHDR) {
	data := ([^]sample)(header.lpData)
	cnt := BufferLength / CHANNELS
	for i in 0 ..< cnt {
		data[i] = i16(i & 1023)
	}
}

DoBuffer2 :: proc(header: ^win32.WAVEHDR) {
	data := ([^]sample)(header.lpData)
	cnt := BufferLength / CHANNELS
	for i in 0 ..< cnt {
		data[i] = sample(rand.int31_max(4000))
	}
}

time: f64 = 0
freq: f64 = 2000

scale := SAMPLES_PER_SEC

DoBuffer3 :: proc(header: ^win32.WAVEHDR) {
	data := ([^]sample)(header.lpData)
	cnt := BufferLength / CHANNELS
	for i in 0 ..< cnt {
		v := math.sin(time) * freq
		data[i] = sample(v)
		time += 0.01
	}
}

OpenFile :: proc(hwnd: win32.HWND) {

	WaveFormatEx = win32.WAVEFORMATEX {
		wFormatTag     = FORMAT_TAG,
		nChannels      = CHANNELS,
		nSamplesPerSec = SAMPLES_PER_SEC,
		wBitsPerSample = BITS_PER_SAMPLE,
		cbSize         = 0,
	}
	WaveFormatEx.nBlockAlign = WaveFormatEx.nChannels * WaveFormatEx.wBitsPerSample / 8
	WaveFormatEx.nAvgBytesPerSec = WaveFormatEx.nSamplesPerSec * win32.DWORD(WaveFormatEx.nBlockAlign)
	fmt.println("WaveFormatEx:", WaveFormatEx)

	BufferLength = WAVE_DISPLAY_WIDTH << 4
	fmt.println("BufferLength:", BufferLength)
	CurrentBuffer = 0
	Ending = 1
	Closing = false

	fmt.println("waveOutOpen pre")
	hr := win32.waveOutOpen(&waveout, win32.WAVE_MAPPER, &WaveFormatEx, win32.DWORD_PTR(uintptr(hwnd)), 0, win32.CALLBACK_WINDOW | win32.WAVE_ALLOWSYNC)

	if hr != win32.MMSYSERR_NOERROR {
		win32app.show_last_errorf("waveOutOpen %v\n%v", hr, WaveFormatEx)
		return
	}

	fmt.println("waveOutOpen waveout=%v", waveout)

	for i in 0 ..< NUM_BUFFERS {
		header := &Headers[i]
		runtime.memset(header, 0, size_of(win32.WAVEHDR)) // don't think this is need as odin by default zeros mem

		//data := make([]byte, BufferLength)
		//header.lpData = win32.LPSTR(&data[0])
		data := win32.GlobalAlloc(win32.GMEM_FIXED, win32.SIZE_T(BufferLength))
		header.lpData = win32.LPSTR(data)
		header.dwBufferLength = win32.DWORD(BufferLength)
		header.dwFlags = win32.WHDR_DONE

		hr = win32.waveOutPrepareHeader(waveout, header, size_of(win32.WAVEHDR))
		if hr != 0 {
			win32app.show_last_errorf("header[%d]=%v", i, header)
			return
		}
	}

	for _ in 0 ..< NUM_BUFFERS {
		WriteBuffer()
	}
}

CloseFile :: proc() {
	if waveout == nil {return}

	Closing = true

	hr := win32.waveOutReset(waveout)
	assert(hr == 0)

	for i in 0 ..< NUM_BUFFERS {
		header := &Headers[i]
		data := rawptr(header.lpData)
		hr = win32.waveOutUnprepareHeader(waveout, header, size_of(win32.WAVEHDR))
		header.lpData = nil
		//delete(p^)
		data = win32.GlobalFree(data)
		assert(data == nil)
		assert(hr == 0)
	}

	fmt.printfln("waveOutClose waveout=%v", waveout)
	hr = win32.waveOutClose(waveout)
	assert(hr == 0)
	waveout = nil
}

WriteBuffer :: proc() {
	if Closing || (DoBuffer == nil) {return}

	header := &Headers[CurrentBuffer]
	DoBuffer(header)

	hr := win32.waveOutWrite(waveout, header, size_of(win32.WAVEHDR))
	assert(hr == 0)
	CurrentBuffer = (CurrentBuffer + 1) % NUM_BUFFERS
	// win32.PostMessage(Handle, WM_PREPARE_NEXT_BUFFER, CurrentBuffer, 0);
	//fmt.printfln("WB %d", CurrentBuffer)
}

decode_scrpos :: #force_inline proc "contextless" (lparam: win32.LPARAM) -> win32app.int2 {
	size := win32app.decode_lparam_as_int2(lparam)
	return size / ZOOM
}

WM_CREATE :: proc(hwnd: win32.HWND, lparam: win32.LPARAM) -> win32.LRESULT {
	fmt.println(#procedure, hwnd, win32app.get_createstruct_from_lparam(lparam))

	client_size := win32app.get_client_size(hwnd)

	hdc := win32.GetDC(hwnd)
	defer win32.ReleaseDC(hwnd, hdc)

	dib = win32app.dib_create_v5(hdc, client_size / ZOOM)
	if dib.canvas.pvBits != nil {
		cv.canvas_clear(&dib, {50, 100, 150, 255})
	}

	OpenFile(hwnd)

	return 0
}

WM_DESTROY :: proc(hwnd: win32.HWND) -> win32.LRESULT {
	fmt.println(#procedure, hwnd)
	win32app.dib_free_section(&dib)
	//CloseFile()
	win32app.post_quit_message(0)
	return 0
}

WM_CHAR :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	// fmt.printfln("WM_CHAR %4d 0x%4x 0x%4x 0x%4x", wparam, wparam, win32.HIWORD(u32(lparam)), win32.LOWORD(u32(lparam)))
	// odinfmt: disable
	switch wparam {
	case '\x1b': CloseFile()
	case '\t':	 fmt.println("tab")
	case '\r':	 fmt.println("return")
	case '1':	 if colidx > 0 {colidx -= 1}
	case '2':	 if colidx < 15 {colidx += 1}
	case '3':	 cols = cv.C64_COLORS
	case '4':	 cols = cv.W95_COLORS
	}
	// odinfmt: enable
	return 0
}

WM_SIZE :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	size := win32app.decode_lparam_as_int2(lparam)
	win32app.set_window_textf(hwnd, "%s %v %v", TITLE, size, dib.canvas.size)
	return 0
}

/*WM_PAINT :: proc(hwnd: win32.HWND) -> win32.LRESULT {
	ps: win32.PAINTSTRUCT
	win32.BeginPaint(hwnd, &ps)
	defer win32.EndPaint(hwnd, &ps)

	hdc_source := win32.CreateCompatibleDC(ps.hdc)
	defer win32.DeleteDC(hdc_source)

	win32.SelectObject(hdc_source, win32.HGDIOBJ(dib.hbitmap))
	client_size := win32app.get_rect_size(&ps.rcPaint)
	win32.StretchBlt(ps.hdc, 0, 0, client_size.x, client_size.y, hdc_source, 0, 0, dib.size.x, dib.size.y, win32.SRCCOPY)

	return 0
}*/

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
		set_dot(pos, cols[colidx])
		win32.InvalidateRect(hwnd, nil, false)
	case 2:
		pos := decode_scrpos(lparam)
		set_dot(pos, cv.C64_BLUE)
		win32.InvalidateRect(hwnd, nil, false)
	case 3:
		pos := decode_scrpos(lparam)
		set_dot(pos, cv.C64_GREEN)
		win32.InvalidateRect(hwnd, nil, false)
	case 4:
		fmt.println("input:", decode_scrpos(lparam), wparam)
	case:
	}
	return 0
}

get_waveout :: #force_inline proc "contextless" (wparam: win32.WPARAM) -> win32.HWAVEOUT {
	return win32.HWAVEOUT(wparam)
}

MM_WOM_OPEN :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	wo := get_waveout(wparam)
	fmt.println(#procedure, wo)
	return 0
}

MM_WOM_CLOSE :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	wo := get_waveout(wparam)
	fmt.println(#procedure, wo)
	win32app.close_application(hwnd)
	return 0
}

n_done := 0

MM_WOM_DONE :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	//wo := get_waveout(wparam)
	//fmt.println(#procedure, wo)
	WriteBuffer()
	n_done += 1

	//new_title := fmt.tprintf("%s %v", TITLE, n_done)
	//win32.SetWindowTextW(hwnd, win32.utf8_to_wstring(new_title))

	return 0
}

StopPlay :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	fmt.println(#procedure)
	CloseFile()
	return 0
}

PrepareNext :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	fmt.println(#procedure)
	return 0
}

wndproc :: proc "system" (hwnd: win32.HWND, msg: win32.UINT, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	context = runtime.default_context()
	// odinfmt: disable
	switch msg {
	case win32.WM_CREATE:        return WM_CREATE(hwnd, lparam)
	case win32.WM_DESTROY:       return WM_DESTROY(hwnd)
	//case win32.WM_CLOSE:       return WM_CLOSE(hwnd, wparam, lparam)
	case win32.WM_ERASEBKGND:    return 1
	case win32.WM_SIZE:          return WM_SIZE(hwnd, wparam, lparam)
	//case win32.WM_PAINT:       return WM_PAINT(hwnd)
	case win32.WM_PAINT:         return win32app.wm_paint_dib(hwnd, dib)
	case win32.WM_CHAR:          return WM_CHAR(hwnd, wparam, lparam)
	case win32.WM_MOUSEMOVE:     return WM_MOUSEMOVE(hwnd, wparam, lparam)
	case win32.WM_LBUTTONDOWN:   return WM_LBUTTONDOWN(hwnd, wparam, lparam)
	case win32.WM_RBUTTONDOWN:   return WM_RBUTTONDOWN(hwnd, wparam, lparam)
	case win32.MM_WOM_OPEN:      return MM_WOM_OPEN(hwnd, wparam, lparam)
	case win32.MM_WOM_CLOSE:     return MM_WOM_CLOSE(hwnd, wparam, lparam)
	case win32.MM_WOM_DONE:      return MM_WOM_DONE(hwnd, wparam, lparam)
	case WM_STOP_PLAY:           return StopPlay(hwnd, wparam, lparam)
	case WM_PREPARE_NEXT_BUFFER: return PrepareNext(hwnd, wparam, lparam)
	case:                        return win32.DefWindowProcW(hwnd, msg, wparam, lparam)
	}
	// odinfmt: enable
}

list_audio_devices :: proc() {
	num_devs := win32.waveOutGetNumDevs()
	fmt.printfln("Audio Devices (%d)", num_devs)
	woc: win32.WAVEOUTCAPSW
	for i in 0 ..< num_devs {
		if win32.waveOutGetDevCapsW(win32.UINT_PTR(i), &woc, size_of(win32.WAVEOUTCAPSW)) == 0 {
			fmt.printfln("Device ID #%d: '%s'", i, woc.szPname)
		}
	}
}

main :: proc() {
	list_audio_devices()
	settings := win32app.create_window_settings(TITLE, WIDTH, HEIGHT, wndproc)
	win32app.run(&settings)
}

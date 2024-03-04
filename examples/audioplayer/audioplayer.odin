package audioplayer

import "core:fmt"
import "core:intrinsics"
import "core:math"
import "core:math/linalg"
import hlm "core:math/linalg/hlsl"
import "core:math/noise"
import "core:math/rand"
import "core:mem"
import "core:runtime"
import "core:simd"
import "core:strings"
import win32 "core:sys/windows"
import "core:time"
import canvas "shared:tlc/canvas"
import win32app "shared:tlc/win32app"
//import win32ex "shared:sys/windows"
win32ex :: win32

// https://learn.microsoft.com/en-us/windows/win32/multimedia/example-of-writing-waveform-data
// https://github.com/cornyum/Windows-programming-5th/blob/master/Chap22/SineWave/SineWave.c
// D:\dev\pascal\Delphi7\Audio\PerlinNoisePlayer\PerlinNoisePlayerMain.pas
// https://www.codeproject.com/articles/6543/playing-wav-files-using-the-windows-multi-media-li
// https://www.markheath.net/post/waveoutopen-callbacks-in-naudio

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

dib: canvas.DIB
colidx := 1
cols := canvas.C64_COLORS

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

rng := rand.create(1)

DoBuffer := DoBuffer1

DoBuffer1 :: proc(Buf: rawptr) {
	data := ([^]sample)(Buf)
	cnt := BufferLength / CHANNELS
	for i in 0 ..< cnt {
		//data[i] = i16(i & 255)
		data[i] = sample(rand.int31_max(4000, &rng))
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

	BufferLength = WAVE_DISPLAY_WIDTH << 4
	CurrentBuffer = 0
	Ending = 1
	Closing = false

	fmt.print("waveOutOpen pre\n")
	hr := win32.waveOutOpen(&waveout, win32.WAVE_MAPPER, &WaveFormatEx, win32.DWORD_PTR(uintptr(hwnd)), 0, win32.CALLBACK_WINDOW | win32.WAVE_ALLOWSYNC)

	if hr != win32.MMSYSERR_NOERROR {
		win32app.show_error_and_panic(fmt.tprintf("waveOutOpen %v\n%v", hr, WaveFormatEx))
		return
	}

	fmt.printf("waveOutOpen waveout=%v\n", waveout)

	for i in 0 ..< NUM_BUFFERS {
		header := &Headers[i]
		runtime.memset(header, 0, size_of(win32.WAVEHDR)) // don't think this is need as odin by default zeros mem

		//data := make([]byte, BufferLength)
		//header.lpData = win32.LPSTR(&data[0])
		data := win32.GlobalAlloc(win32.GMEM_FIXED, win32.SIZE_T(BufferLength))
		header.lpData = win32.LPSTR(data)
		header.dwBufferLength = win32.DWORD(BufferLength)
		header.dwFlags = win32.WHDR_DONE

		hr := win32.waveOutPrepareHeader(waveout, header, size_of(win32.WAVEHDR))
		assert(hr == 0)
		fmt.printf("header[%d]=%v\n", i, header)
	}

	for i in 0 ..< NUM_BUFFERS {
		WriteBuffer()
	}
}

CloseFile :: proc() {
	if waveout == nil {return}

	Closing = true

	hr := win32ex.waveOutReset(waveout)
	assert(hr == 0)

	for i in 0 ..< NUM_BUFFERS {
		header := &Headers[i]
		data := rawptr(header.lpData)
		hr = win32ex.waveOutUnprepareHeader(waveout, header, size_of(win32ex.WAVEHDR))
		header.lpData = nil
		//delete(p^)
		data = win32.GlobalFree(data)
		assert(data == nil)
		assert(hr == 0)
	}

	fmt.printf("waveOutClose waveout=%v\n", waveout)
	hr = win32ex.waveOutClose(waveout)
	assert(hr == 0)
	waveout = nil
}

WriteBuffer :: proc() {
	if Closing || (DoBuffer == nil) {return}

	header := &Headers[CurrentBuffer]
	DoBuffer(header.lpData)

	hr := win32ex.waveOutWrite(waveout, header, size_of(win32ex.WAVEHDR))
	assert(hr == 0)
	CurrentBuffer = (CurrentBuffer + 1) % NUM_BUFFERS
	// win32.PostMessage(Handle, WM_PREPARE_NEXT_BUFFER, CurrentBuffer, 0);
	//fmt.printf("WB %d\n", CurrentBuffer)
}

decode_scrpos :: proc(lparam: win32.LPARAM) -> win32app.int2 {
	size := win32app.decode_lparam(lparam)
	scrpos := size / ZOOM
	return scrpos
}

setdot :: proc(pos: win32app.int2, col: canvas.byte4) {
	i := pos.y * dib.size.x + pos.x
	if i >= 0 && i < dib.pixel_count {
		dib.pvBits[i] = col
	}
}

WM_CREATE :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	fmt.print("WM_CREATE\n")

	client_size := win32app.get_client_size(hwnd)

	hdc := win32.GetDC(hwnd)
	defer win32.ReleaseDC(hwnd, hdc)

	dib = canvas.dib_create_v5(hdc, client_size / ZOOM)
	if dib.pvBits != nil {
		canvas.dib_clear(&dib, {50, 100, 150, 255})
	}

	OpenFile(hwnd)

	return 0
}

WM_DESTROY :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	fmt.print("WM_DESTROY\n")

	canvas.dib_free_section(&dib)

	//CloseFile()

	win32.PostQuitMessage(0)
	return 0
}

/*WM_CLOSE :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	fmt.print("WM_CLOSE\n")
	//CloseFile()
	win32.DestroyWindow(hwnd)
	return 0
}*/

WM_ERASEBKGND :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	return 1
}

WM_CHAR :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	//fmt.printf("WM_CHAR %4d 0x%4x 0x%4x 0x%4x\n", wparam, wparam, win32.HIWORD(u32(lparam)), win32.LOWORD(u32(lparam)))
	switch wparam {
	//case '\x1b':win32.DestroyWindow(hwnd)
	//case '\x1b':assert( win32.CloseWindow(hwnd) == true )
	//case '\x1b': win32.PostMessageW(hwnd, win32.WM_CLOSE, 0, 0)
	case '\x1b': CloseFile()
	case '\t':	 fmt.print("tab\n")
	case '\r':	 fmt.print("return\n")
	case '1':	 if colidx > 0 {colidx -= 1}
	case '2':	 if colidx < 15 {colidx += 1}
	case '3':	 cols = canvas.C64_COLORS
	case '4':	 cols = canvas.W95_COLORS
	}
	return 0
}

WM_SIZE :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	size := win32app.decode_lparam(lparam)
	newtitle := fmt.tprintf("%s %v %v\n", TITLE, size, dib.size)
	win32.SetWindowTextW(hwnd, win32.utf8_to_wstring(newtitle))
	return 0
}

WM_PAINT :: proc(hwnd: win32.HWND) -> win32.LRESULT {
	ps: win32.PAINTSTRUCT
	win32.BeginPaint(hwnd, &ps)
	defer win32.EndPaint(hwnd, &ps)

	hdc_source := win32ex.CreateCompatibleDC(ps.hdc)
	defer win32ex.DeleteDC(hdc_source)

	win32.SelectObject(hdc_source, win32.HGDIOBJ(dib.hbitmap))
	client_size := win32app.get_rect_size(&ps.rcPaint)
	win32.StretchBlt(ps.hdc, 0, 0, client_size.x, client_size.y, hdc_source, 0, 0, dib.size.x, dib.size.y, win32.SRCCOPY)

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
		setdot(pos, cols[colidx])
		win32.InvalidateRect(hwnd, nil, false)
	case 2:
		pos := decode_scrpos(lparam)
		setdot(pos, canvas.C64_BLUE)
		win32.InvalidateRect(hwnd, nil, false)
	case 3:
		pos := decode_scrpos(lparam)
		setdot(pos, canvas.C64_GREEN)
		win32.InvalidateRect(hwnd, nil, false)
	case 4:
		fmt.printf("input %v %d\n", decode_scrpos(lparam), wparam)
	case:
	}
	return 0
}

MM_WOM_OPEN :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	wo: win32ex.HWAVEOUT = win32ex.HWAVEOUT(uintptr(wparam))
	fmt.printf("MM_WOM_OPEN waveout=%v\n", wo)
	return 0
}

MM_WOM_CLOSE :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	wo: win32ex.HWAVEOUT = win32ex.HWAVEOUT(uintptr(wparam))
	fmt.printf("MM_WOM_CLOSE waveout=%v\n", wo)
	win32.PostMessageW(hwnd, win32.WM_CLOSE, 0, 0)
	return 0
}

n_done := 0

MM_WOM_DONE :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	wo: win32ex.HWAVEOUT = win32ex.HWAVEOUT(uintptr(wparam))
	//fmt.printf("MM_WOM_DONE waveout=%v\n", wo)
	WriteBuffer()
	n_done += 1

	//newtitle := fmt.tprintf("%s %v\n", TITLE, n_done)
	//win32.SetWindowTextW(hwnd, win32.utf8_to_wstring(newtitle))

	return 0
}

StopPlay :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	fmt.print("WM_STOP_PLAY\n")
	CloseFile()
	return 0
}

PrepareNext :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	fmt.print("WM_PREPARE_NEXT_BUFFER\n")
	return 0
}


wndproc :: proc "system" (hwnd: win32.HWND, msg: win32.UINT, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	context = runtime.default_context()
	switch msg {
	// odinfmt: disable
	case win32.WM_CREATE:		return WM_CREATE(hwnd, wparam, lparam)
	case win32.WM_DESTROY:		return WM_DESTROY(hwnd, wparam, lparam)
	//case win32.WM_CLOSE:		return WM_CLOSE(hwnd, wparam, lparam)
	case win32.WM_ERASEBKGND:	return WM_ERASEBKGND(hwnd, wparam, lparam)
	case win32.WM_SIZE:			return WM_SIZE(hwnd, wparam, lparam)
	case win32.WM_PAINT:		return WM_PAINT(hwnd)
	case win32.WM_CHAR:			return WM_CHAR(hwnd, wparam, lparam)
	case win32.WM_MOUSEMOVE:	return WM_MOUSEMOVE(hwnd, wparam, lparam)
	case win32.WM_LBUTTONDOWN:	return WM_LBUTTONDOWN(hwnd, wparam, lparam)
	case win32.WM_RBUTTONDOWN:	return WM_RBUTTONDOWN(hwnd, wparam, lparam)
	case win32.MM_WOM_OPEN:	    return MM_WOM_OPEN(hwnd, wparam, lparam)
	case win32.MM_WOM_CLOSE:	return MM_WOM_CLOSE(hwnd, wparam, lparam)
	case win32.MM_WOM_DONE:	    return MM_WOM_DONE(hwnd, wparam, lparam)
	case WM_STOP_PLAY:	        return StopPlay(hwnd, wparam, lparam)
	case WM_PREPARE_NEXT_BUFFER: return PrepareNext(hwnd, wparam, lparam)
	case:						return win32.DefWindowProcW(hwnd, msg, wparam, lparam)
	// odinfmt: enable
	}
}

list_audio_devices :: proc() {
	num_devs := win32ex.waveOutGetNumDevs()
	fmt.printf("Audio Devices (%d)\n", num_devs)
	woc: win32ex.WAVEOUTCAPSW
	for i in 0 ..< num_devs {
		if win32ex.waveOutGetDevCapsW(win32.UINT_PTR(i), &woc, size_of(win32ex.WAVEOUTCAPSW)) == 0 {
			fmt.printf("Device ID #%d: '%s'\n", i, woc.szPname)
		}
	}
}

main :: proc() {
	list_audio_devices()
	settings := win32app.create_window_settings(TITLE, WIDTH, HEIGHT, wndproc)
	win32app.run(&settings)
}

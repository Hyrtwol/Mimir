package fmod

import "core:bytes"
import "core:fmt"
import "core:runtime"
import "shared:ounit"
//import win32 "core:sys/windows"
//import win32app "../../shared/tlc/win32app"

@(test)
fmod_speaker :: proc(t: ^testing.T) {
	exp := FMOD_SPEAKER.FMOD_SPEAKER_SBL
	act := FMOD_SPEAKER.FMOD_SPEAKER_SIDE_LEFT
	testing.expect(t, act == exp, fmt.tprintf("FMOD_SPEAKER: %v (should be: %v)", act, exp))
	exp = FMOD_SPEAKER.FMOD_SPEAKER_SBR
	act = FMOD_SPEAKER.FMOD_SPEAKER_SIDE_RIGHT
	testing.expect(t, act == exp, fmt.tprintf("FMOD_SPEAKER: %v (should be: %v)", act, exp))
}

/*
@(test)
make_lresult_from_true :: proc(t: ^testing.T) {
	exp := 1
	result := win32app.MAKELRESULT(true)
	testing.expect(t, exp == result, fmt.tprintf("MAKELRESULT: %v -> %v (should be: %v)", false, result, exp))
}

@(test)
wstring_convert :: proc(t: ^testing.T) {
	exp := "ABC"
	wstr := win32.utf8_to_wstring(exp)
	result, err := win32.wstring_to_utf8(wstr, 256, context.allocator)
	testing.expect(t, exp == result, fmt.tprintf("wstring_convert: %v (should be: %v)", result, exp))
	testing.expect(t, err == .None, fmt.tprintf("wstring_convert: error %v", err))
}
*/

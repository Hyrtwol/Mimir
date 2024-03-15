package fmod

//import "core:bytes"
import "core:testing"
import o "shared:ounit"

@(test)
fmod_result :: proc(t: ^testing.T) {
	o.expect_value(t, FMOD_RESULT.FMOD_OK, 0)
	o.expect_value(t, FMOD_RESULT.FMOD_ERR_MUSIC_NOCALLBACK, 95)
}

@(test)
fmod_speaker :: proc(t: ^testing.T) {
	o.expect_value(t, FMOD_SPEAKER.FMOD_SPEAKER_FRONT_LEFT, 0)
	o.expect_value(t, FMOD_SPEAKER.FMOD_SPEAKER_FRONT_RIGHT, 1)
	o.expect_value(t, FMOD_SPEAKER.FMOD_SPEAKER_SBL, FMOD_SPEAKER.FMOD_SPEAKER_SIDE_LEFT)
	o.expect_value(t, FMOD_SPEAKER.FMOD_SPEAKER_SBR, FMOD_SPEAKER.FMOD_SPEAKER_SIDE_RIGHT)
}

@(test)
verify_enums :: proc(t: ^testing.T) {
	o.expect_value(t, transmute(u32)FMOD_CAPS({.HARDWARE}), 0x00000001)
	o.expect_value(t, transmute(u32)FMOD_CAPS({.HARDWARE_EMULATED}), 0x00000002)
	o.expect_value(t, transmute(u32)FMOD_CAPS({.OUTPUT_MULTICHANNEL}), 0x00000004)
	o.expect_value(t, transmute(u32)FMOD_CAPS({.OUTPUT_FORMAT_PCM8}), 0x00000008)
	o.expect_value(t, transmute(u32)FMOD_CAPS({.OUTPUT_FORMAT_PCM16}), 0x00000010)
	o.expect_value(t, transmute(u32)FMOD_CAPS({.OUTPUT_FORMAT_PCM24}), 0x00000020)
	o.expect_value(t, transmute(u32)FMOD_CAPS({.OUTPUT_FORMAT_PCM32}), 0x00000040)
	o.expect_value(t, transmute(u32)FMOD_CAPS({.OUTPUT_FORMAT_PCMFLOAT}), 0x00000080)
	o.expect_value(t, transmute(u32)FMOD_CAPS({.REVERB_LIMITED}), 0x00002000)
	o.expect_value(t, transmute(u32)FMOD_CAPS({.FMOD_CAPS_LOOPBACK}), 0x00004000)
}

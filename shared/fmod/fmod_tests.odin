package fmod

import _t "core:testing"
import _o "shared:ounit"

expect_value :: _o.expect_value

@(test)
fmod_result :: proc(t: ^_t.T) {
	expect_value(t, FMOD_RESULT.FMOD_OK, 0)
	expect_value(t, FMOD_RESULT.FMOD_ERR_MUSIC_NOCALLBACK, 95)
}

@(test)
fmod_speaker :: proc(t: ^_t.T) {
	expect_value(t, FMOD_SPEAKER.FMOD_SPEAKER_FRONT_LEFT, 0)
	expect_value(t, FMOD_SPEAKER.FMOD_SPEAKER_FRONT_RIGHT, 1)
	expect_value(t, FMOD_SPEAKER.FMOD_SPEAKER_SBL, FMOD_SPEAKER.FMOD_SPEAKER_SIDE_LEFT)
	expect_value(t, FMOD_SPEAKER.FMOD_SPEAKER_SBR, FMOD_SPEAKER.FMOD_SPEAKER_SIDE_RIGHT)
}

@(test)
verify_enums :: proc(t: ^_t.T) {
	expect_value(t, transmute(u32)FMOD_CAPS({.HARDWARE}), 0x00000001)
	expect_value(t, transmute(u32)FMOD_CAPS({.HARDWARE_EMULATED}), 0x00000002)
	expect_value(t, transmute(u32)FMOD_CAPS({.OUTPUT_MULTICHANNEL}), 0x00000004)
	expect_value(t, transmute(u32)FMOD_CAPS({.OUTPUT_FORMAT_PCM8}), 0x00000008)
	expect_value(t, transmute(u32)FMOD_CAPS({.OUTPUT_FORMAT_PCM16}), 0x00000010)
	expect_value(t, transmute(u32)FMOD_CAPS({.OUTPUT_FORMAT_PCM24}), 0x00000020)
	expect_value(t, transmute(u32)FMOD_CAPS({.OUTPUT_FORMAT_PCM32}), 0x00000040)
	expect_value(t, transmute(u32)FMOD_CAPS({.OUTPUT_FORMAT_PCMFLOAT}), 0x00000080)
	expect_value(t, transmute(u32)FMOD_CAPS({.REVERB_LIMITED}), 0x00002000)
	expect_value(t, transmute(u32)FMOD_CAPS({.FMOD_CAPS_LOOPBACK}), 0x00004000)
}

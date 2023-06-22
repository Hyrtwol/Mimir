package fmod

USE_LINALG :: #config(RAYLIB_USE_LINALG, true)

import "core:math/linalg"
import _c "core:c"

/*
    FMOD version number.  Check this against FMOD::System::getVersion.
    0xaaaabbcc -> aaaa = major version number.  bb = minor version number.  cc = development version number.
*/
FMOD_VERSION :: struct {
	Development: _c.uchar,
	Minor:       _c.uchar,
	Major:       _c.ushort,
}

CAPS :: enum i32 {
	// Device has no special capabilities.
	NONE                   = 0x00000000,

	// Device supports hardware mixing.
	HARDWARE               = 0x00000001,

	// User has device set to 'Hardware acceleration = off' in control panel, and now extra 200ms latency is incurred.
	HARDWARE_EMULATED      = 0x00000002,

	// Device can do multichannel output, ie greater than 2 channels.
	OUTPUT_MULTICHANNEL    = 0x00000004,

	// Device can output to 8bit integer PCM.
	OUTPUT_FORMAT_PCM8     = 0x00000008,

	// Device can output to 16bit integer PCM.
	OUTPUT_FORMAT_PCM16    = 0x00000010,

	// Device can output to 24bit integer PCM.
	OUTPUT_FORMAT_PCM24    = 0x00000020,

	/// Device can output to 32bit integer PCM.
	OUTPUT_FORMAT_PCM32    = 0x00000040,

	// Device can output to 32bit floating point PCM.
	OUTPUT_FORMAT_PCMFLOAT = 0x00000080,

	// Device supports some form of limited hardware reverb, maybe parameterless and only selectable by environment.
	REVERB_LIMITED         = 0x00002000,
}

//FMOD_RESULT_FLAGS :: bit_set[FMOD_RESULT; u32]
//FMOD_RESULT_FLAGS :: bit_set[FMOD_SPEAKERMODE; u32]

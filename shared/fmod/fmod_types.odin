package fmod

FMOD_BOOL :: i32
FMOD_MODE :: u32
FMOD_TIMEUNIT :: u32
FMOD_INITFLAGS :: u32
FMOD_DEBUGLEVEL :: u32
FMOD_MEMORY_TYPE :: u32

FMOD_EVENT_INITFLAGS :: u32
FMOD_EVENT_MODE :: u32
FMOD_EVENT_STATE :: u32
FMOD_MUSIC_ID :: u32
FMOD_MUSIC_CUE_ID :: u32
FMOD_MUSIC_PARAM_ID :: u32

/*
    FMOD version number.  Check this against FMOD::System::getVersion.
    0xaaaabbcc -> aaaa = major version number.  bb = minor version number.  cc = development version number.
*/
FMOD_VERSION :: struct {
	Development: u8,
	Minor:       u8,
	Major:       u16,
}

FMOD_CAPS :: distinct bit_set[FMOD_CAPS_FLAG;u32]
FMOD_CAPS_FLAG :: enum u32 {
	// Device supports hardware mixing.
	HARDWARE               = 0,
	// User has device set to 'Hardware acceleration = off' in control panel, and now extra 200ms latency is incurred.
	HARDWARE_EMULATED      = 1,
	// Device can do multichannel output, ie greater than 2 channels.
	OUTPUT_MULTICHANNEL    = 2,
	// Device can output to 8bit integer PCM.
	OUTPUT_FORMAT_PCM8     = 3,
	// Device can output to 16bit integer PCM.
	OUTPUT_FORMAT_PCM16    = 4,
	// Device can output to 24bit integer PCM.
	OUTPUT_FORMAT_PCM24    = 5,
	/// Device can output to 32bit integer PCM.
	OUTPUT_FORMAT_PCM32    = 6,
	// Device can output to 32bit floating point PCM.
	OUTPUT_FORMAT_PCMFLOAT = 7,
	// Device supports some form of limited hardware reverb, maybe parameterless and only selectable by environment.
	REVERB_LIMITED         = 13,
	FMOD_CAPS_LOOPBACK     = 14,
}

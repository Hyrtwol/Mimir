// +build windows
package sys_windows_ex

import win32 "core:sys/windows"

foreign import winmm "system:Winmm.lib"

MMRESULT :: win32.MMRESULT

@(default_calling_convention="system")
foreign winmm {

	waveOutGetNumDevs :: proc() -> UINT ---
	waveOutGetDevCapsW :: proc(uDeviceID: UINT_PTR, pwoc: LPWAVEOUTCAPSW, cbwoc: UINT) -> MMRESULT ---
	waveOutGetVolume :: proc(hwo: HWAVEOUT, pdwVolume: LPDWORD) -> MMRESULT ---
	waveOutSetVolume :: proc(hwo: HWAVEOUT, dwVolume: DWORD) -> MMRESULT ---
	waveOutGetErrorTextW :: proc(mmrError: MMRESULT, pszText: LPWSTR, cchText: UINT) -> MMRESULT ---
	waveOutOpen :: proc(phwo: LPHWAVEOUT, uDeviceID: UINT, pwfx: LPCWAVEFORMATEX, dwCallback: DWORD_PTR, dwInstance: DWORD_PTR, fdwOpen: DWORD) -> MMRESULT ---
	waveOutClose :: proc(hwo: HWAVEOUT) -> MMRESULT ---
	waveOutPrepareHeader :: proc(hwo: HWAVEOUT, pwh: LPWAVEHDR, cbwh: UINT) -> MMRESULT ---
	waveOutUnprepareHeader :: proc(hwo: HWAVEOUT, pwh: LPWAVEHDR, cbwh: UINT) -> MMRESULT ---
	waveOutWrite :: proc(hwo: HWAVEOUT, pwh: LPWAVEHDR, cbwh: UINT) -> MMRESULT ---
	waveOutPause :: proc(hwo: HWAVEOUT) -> MMRESULT ---
	waveOutRestart :: proc(hwo: HWAVEOUT) -> MMRESULT ---
	waveOutReset :: proc(hwo: HWAVEOUT) -> MMRESULT ---
	waveOutBreakLoop :: proc(hwo: HWAVEOUT) -> MMRESULT ---
	waveOutGetPosition :: proc(hwo: HWAVEOUT, pmmt: LPMMTIME, cbmmt: UINT) -> MMRESULT ---
	waveOutGetPitch :: proc(hwo: HWAVEOUT, pdwPitch: LPDWORD) -> MMRESULT ---
	waveOutSetPitch :: proc(hwo: HWAVEOUT, pdwPitch: DWORD) -> MMRESULT ---
	waveOutGetPlaybackRate :: proc(hwo: HWAVEOUT, pdwRate: LPDWORD) -> MMRESULT ---
	waveOutSetPlaybackRate :: proc(hwo: HWAVEOUT, pdwRate: DWORD) -> MMRESULT ---
	waveOutGetID :: proc(hwo: HWAVEOUT, puDeviceID: LPUINT) -> MMRESULT ---

	waveInGetNumDevs :: proc() -> UINT ---
	waveInGetDevCapsW :: proc(uDeviceID: UINT_PTR, pwic: LPWAVEINCAPSW, cbwic: UINT) -> MMRESULT ---

	PlaySoundW :: proc(pszSound: LPCWSTR, hmod: HMODULE, fdwSound: DWORD) -> BOOL ---
}

// String resource number bases (internal use)
MMSYSERR_BASE :: win32.MMSYSERR_BASE
WAVERR_BASE :: win32.WAVERR_BASE

/* waveform audio error return values */
WAVERR_BADFORMAT    :: WAVERR_BASE + 0 /* unsupported wave format */
WAVERR_STILLPLAYING :: WAVERR_BASE + 1 /* still something playing */
WAVERR_UNPREPARED   :: WAVERR_BASE + 2 /* header not prepared */
WAVERR_SYNC         :: WAVERR_BASE + 3 /* device is synchronous */
WAVERR_LASTERROR    :: WAVERR_BASE + 3 /* last error in range */

/* waveform output */
MM_WOM_OPEN  :: 0x3BB
MM_WOM_CLOSE :: 0x3BC
MM_WOM_DONE  :: 0x3BD
/* waveform input */
MM_WIM_OPEN  :: 0x3BE
MM_WIM_CLOSE :: 0x3BF
MM_WIM_DATA  :: 0x3C0

WOM_OPEN  :: MM_WOM_OPEN
WOM_CLOSE :: MM_WOM_CLOSE
WOM_DONE  :: MM_WOM_DONE
WIM_OPEN  :: MM_WIM_OPEN
WIM_CLOSE :: MM_WIM_CLOSE
WIM_DATA  :: MM_WIM_DATA

WAVE_MAPPER : UINT : 0xFFFFFFFF // -1

WAVE_FORMAT_QUERY                        :: 0x0001
WAVE_ALLOWSYNC                           :: 0x0002
WAVE_MAPPED                              :: 0x0004
WAVE_FORMAT_DIRECT                       :: 0x0008
WAVE_FORMAT_DIRECT_QUERY                 :: (WAVE_FORMAT_QUERY | WAVE_FORMAT_DIRECT)
WAVE_MAPPED_DEFAULT_COMMUNICATION_DEVICE :: 0x0010

WHDR_DONE      :: 0x00000001 /* done bit */
WHDR_PREPARED  :: 0x00000002 /* set if this header has been prepared */
WHDR_BEGINLOOP :: 0x00000004 /* loop start block */
WHDR_ENDLOOP   :: 0x00000008 /* loop end block */
WHDR_INQUEUE   :: 0x00000010 /* reserved for driver */

WAVECAPS_PITCH          :: 0x0001 /* supports pitch control */
WAVECAPS_PLAYBACKRATE   :: 0x0002 /* supports playback rate control */
WAVECAPS_VOLUME         :: 0x0004 /* supports volume control */
WAVECAPS_LRVOLUME       :: 0x0008 /* separate left-right volume control */
WAVECAPS_SYNC           :: 0x0010
WAVECAPS_SAMPLEACCURATE :: 0x0020

WAVE_INVALIDFORMAT :: 0x00000000 /* invalid format */
WAVE_FORMAT_1M08   :: 0x00000001 /* 11.025 kHz, Mono,   8-bit  */
WAVE_FORMAT_1S08   :: 0x00000002 /* 11.025 kHz, Stereo, 8-bit  */
WAVE_FORMAT_1M16   :: 0x00000004 /* 11.025 kHz, Mono,   16-bit */
WAVE_FORMAT_1S16   :: 0x00000008 /* 11.025 kHz, Stereo, 16-bit */
WAVE_FORMAT_2M08   :: 0x00000010 /* 22.05  kHz, Mono,   8-bit  */
WAVE_FORMAT_2S08   :: 0x00000020 /* 22.05  kHz, Stereo, 8-bit  */
WAVE_FORMAT_2M16   :: 0x00000040 /* 22.05  kHz, Mono,   16-bit */
WAVE_FORMAT_2S16   :: 0x00000080 /* 22.05  kHz, Stereo, 16-bit */
WAVE_FORMAT_4M08   :: 0x00000100 /* 44.1   kHz, Mono,   8-bit  */
WAVE_FORMAT_4S08   :: 0x00000200 /* 44.1   kHz, Stereo, 8-bit  */
WAVE_FORMAT_4M16   :: 0x00000400 /* 44.1   kHz, Mono,   16-bit */
WAVE_FORMAT_4S16   :: 0x00000800 /* 44.1   kHz, Stereo, 16-bit */
WAVE_FORMAT_44M08  :: 0x00000100 /* 44.1   kHz, Mono,   8-bit  */
WAVE_FORMAT_44S08  :: 0x00000200 /* 44.1   kHz, Stereo, 8-bit  */
WAVE_FORMAT_44M16  :: 0x00000400 /* 44.1   kHz, Mono,   16-bit */
WAVE_FORMAT_44S16  :: 0x00000800 /* 44.1   kHz, Stereo, 16-bit */
WAVE_FORMAT_48M08  :: 0x00001000 /* 48     kHz, Mono,   8-bit  */
WAVE_FORMAT_48S08  :: 0x00002000 /* 48     kHz, Stereo, 8-bit  */
WAVE_FORMAT_48M16  :: 0x00004000 /* 48     kHz, Mono,   16-bit */
WAVE_FORMAT_48S16  :: 0x00008000 /* 48     kHz, Stereo, 16-bit */
WAVE_FORMAT_96M08  :: 0x00010000 /* 96     kHz, Mono,   8-bit  */
WAVE_FORMAT_96S08  :: 0x00020000 /* 96     kHz, Stereo, 8-bit  */
WAVE_FORMAT_96M16  :: 0x00040000 /* 96     kHz, Mono,   16-bit */
WAVE_FORMAT_96S16  :: 0x00080000 /* 96     kHz, Stereo, 16-bit */

HWAVE    :: distinct HANDLE
HWAVEIN  :: distinct HANDLE
HWAVEOUT :: distinct HANDLE

LPHWAVEIN :: ^HWAVEIN
LPHWAVEOUT :: ^HWAVEOUT

//typedef void (CALLBACK DRVCALLBACK)(HDRVR hdrvr, UINT uMsg, DWORD_PTR dwUser, DWORD_PTR dw1, DWORD_PTR dw2);
//WAVECALLBACK :: DRVCALLBACK
//LPWAVECALLBACK :: ^WAVECALLBACK

// https://learn.microsoft.com/en-us/windows/win32/multimedia/multimedia-timer-structures
MMTIME :: struct {
	wType: UINT,
	u: struct #raw_union {
		ms: DWORD,
		sample: DWORD,
		cb: DWORD,
		ticks: DWORD,
		smpte: struct {
			hour: BYTE,
			min: BYTE,
			sec: BYTE,
			frame: BYTE,
			fps: BYTE,
			dummy: BYTE,
			pad: [2]BYTE,
		},
		midi: struct {
			songptrpos: DWORD,
		},
	},
}
LPMMTIME :: ^MMTIME

MAXPNAMELEN :: 32
MAXERRORLENGTH :: 256
MMVERSION :: UINT

/* flags for wFormatTag field of WAVEFORMAT */
WAVE_FORMAT_PCM :: 1

WAVEFORMATEX :: struct {
	wFormatTag:      WORD,
	nChannels:       WORD,
	nSamplesPerSec:  DWORD,
	nAvgBytesPerSec: DWORD,
	nBlockAlign:     WORD,
	wBitsPerSample:  WORD,
	cbSize:          WORD,
}
LPCWAVEFORMATEX :: ^WAVEFORMATEX

WAVEHDR :: struct {
	lpData:          LPSTR, /* pointer to locked data buffer */
	dwBufferLength:  DWORD, /* length of data buffer */
	dwBytesRecorded: DWORD, /* used for input only */
	dwUser:          DWORD_PTR, /* for client's use */
	dwFlags:         DWORD, /* assorted flags (see defines) */
	dwLoops:         DWORD, /* loop control counter */
	lpNext:          LPWAVEHDR, /* reserved for driver */
	reserved:        DWORD_PTR, /* reserved for driver */
}
LPWAVEHDR :: ^WAVEHDR

WAVEINCAPSW :: struct {
	wMid:           WORD, /* manufacturer ID */
	wPid:           WORD, /* product ID */
	vDriverVersion: MMVERSION, /* version of the driver */
	szPname:        [MAXPNAMELEN]WCHAR, /* product name (NULL terminated string) */
	dwFormats:      DWORD, /* formats supported */
	wChannels:      WORD, /* number of channels supported */
	wReserved1:     WORD, /* structure packing */
}
LPWAVEINCAPSW :: ^WAVEINCAPSW

WAVEOUTCAPSW :: struct {
	wMid:           WORD, /* manufacturer ID */
	wPid:           WORD, /* product ID */
	vDriverVersion: MMVERSION, /* version of the driver */
	szPname:        [MAXPNAMELEN]WCHAR, /* product name (NULL terminated string) */
	dwFormats:      DWORD, /* formats supported */
	wChannels:      WORD, /* number of sources supported */
	wReserved1:     WORD, /* packing */
	dwSupport:      DWORD, /* functionality supported by driver */
}
LPWAVEOUTCAPSW :: ^WAVEOUTCAPSW

// flag values for PlaySound
SND_SYNC		:: 0x0000  /* play synchronously (default) */
SND_ASYNC		:: 0x0001  /* play asynchronously */
SND_NODEFAULT	:: 0x0002  /* silence (!default) if sound not found */
SND_MEMORY		:: 0x0004  /* pszSound points to a memory file */
SND_LOOP		:: 0x0008  /* loop the sound until next sndPlaySound */
SND_NOSTOP		:: 0x0010  /* don't stop any currently playing sound */

SND_NOWAIT		:: 0x00002000 /* don't wait if the driver is busy */
SND_ALIAS		:: 0x00010000 /* name is a registry alias */
SND_ALIAS_ID	:: 0x00110000 /* alias is a predefined ID */
SND_FILENAME	:: 0x00020000 /* name is file name */
SND_RESOURCE	:: 0x00040004 /* name is resource name or atom */

SND_PURGE		:: 0x0040  /* purge non-static events for task */
SND_APPLICATION	:: 0x0080  /* look for application specific association */

SND_SENTRY		:: 0x00080000 /* Generate a SoundSentry event with this sound */
SND_RING		:: 0x00100000 /* Treat this as a "ring" from a communications app - don't duck me */
SND_SYSTEM		:: 0x00200000 /* Treat this as a system sound */


CALLBACK_TYPEMASK :: 0x00070000    /* callback type mask */
CALLBACK_NULL     :: 0x00000000    /* no callback */
CALLBACK_WINDOW   :: 0x00010000    /* dwCallback is a HWND */
CALLBACK_TASK     :: 0x00020000    /* dwCallback is a HTASK */
CALLBACK_FUNCTION :: 0x00030000    /* dwCallback is a FARPROC */
CALLBACK_THREAD   :: CALLBACK_TASK /* thread ID replaces 16 bit task */
CALLBACK_EVENT    :: 0x00050000    /* dwCallback is an EVENT Handle */

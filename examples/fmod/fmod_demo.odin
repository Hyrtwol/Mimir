package main

import "core:fmt"
import "core:os"
import "core:runtime"
import "core:strings"
import "shared:fmod"
import "shared:tlc/wolf"

system: ^fmod.FMOD_SYSTEM = nil
eventsys: ^fmod.FMOD_EVENTSYSTEM = nil

distance_factor :: 1.0


main :: proc() {

	fmt.print("FMOD Event System\n")

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

	fmt.printf("Version : %d.%d.%d (0x%x)\n", fmod_version.Major, fmod_version.Minor, fmod_version.Development, transmute(u32)fmod_version)

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
	fmt.printf("Driver      : %x\n", driver_index)

	{
		name : [256]u8
		name_cstr := cstring(&name[0]) // todo there must be a better way to do this
		guid: fmod.FMOD_GUID
		res = fmod.FMOD_System_GetDriverInfo(system, driver_index, name_cstr, len(name), &guid)
		if res != .FMOD_OK {
			fmt.printf("%v %v\n", fmod.FMOD_System_GetDriverInfo, res)
			return
		}
		driver_name := string(name_cstr)

		fmt.printf("Driver info : '%s'\n", driver_name)
		fmt.printf("Driver guid : %v\n", guid)
	}

	driver_caps: fmod.FMOD_CAPS
	output_rate: i32
	speaker_mode: fmod.FMOD_SPEAKERMODE
	res = fmod.FMOD_System_GetDriverCaps(system, driver_index, &driver_caps, &output_rate, &speaker_mode)
	if res != .FMOD_OK {
		fmt.printf("FMOD_System_GetDriverCaps %v\n", res)
		return
	}

	fmt.printf("driver caps                : %v\n", driver_caps)
	fmt.printf("control panel output rate  : %v\n", output_rate)
	fmt.printf("control panel speaker mode : %v\n", speaker_mode)

	res = fmod.FMOD_System_SetSpeakerMode(system, speaker_mode)

	if .HARDWARE_EMULATED in driver_caps {
		// The user has the 'Acceleration' slider set to off!  This is really bad for latency!
		// You might want to warn the user about this.
		fmt.print("HARDWARE_EMULATED\n")
		res = fmod.FMOD_System_SetDSPBufferSize(system, 1024, 10)
		// At 48khz, the latency between issuing an fmod command and hearing it will now be about 213ms.
		if res != .FMOD_OK {
			fmt.printf("FMOD_System_SetDSPBufferSize %v\n", res)
			return
		}
	}

	init_flags: u32 = fmod.FMOD_INIT_3D_RIGHTHANDED

	res = fmod.FMOD_EventSystem_Init(eventsys, 32, init_flags, nil, fmod.FMOD_EVENT_INIT_NORMAL)
	if res == .FMOD_ERR_OUTPUT_CREATEBUFFER {
		fmt.print("ERR_OUTPUT_CREATEBUFFER Switch it back to stereo...\n")
		res = fmod.FMOD_System_SetSpeakerMode(system, fmod.FMOD_SPEAKERMODE.FMOD_SPEAKERMODE_STEREO)
		// Ok, the speaker mode selected isn't supported by this soundcard.  Switch it back to stereo...
		res = fmod.FMOD_EventSystem_Init(eventsys, 32, init_flags, nil, fmod.FMOD_EVENT_INIT_NORMAL)
		// Replace with whatever channel count and flags you use!
	}
	if res != .FMOD_OK {
		fmt.printf("FMOD_EventSystem_Init %v\n", res)
		return
	}

	// Set the distance units. (meters/feet etc).
	res = fmod.FMOD_System_Set3DSettings(system, 1.0, distance_factor, 1.0)
	if res != .FMOD_OK {
		fmt.printf("FMOD_System_Set3DSettings %v\n", res)
		return
	}

	res = fmod.FMOD_EventSystem_Load(eventsys, "WolfensteinSFX.fev", nil, nil)
	if res != .FMOD_OK {
		fmt.printf("FMOD_EventSystem_Load %v\n", res)
		return
	}

	num_events: i32
	res = fmod.FMOD_EventSystem_GetNumEvents(eventsys, &num_events)
	if res != .FMOD_OK {
		fmt.printf("%v %v\n", fmod.FMOD_EventSystem_Load, res)
		return
	}
	fmt.printf("Events : %v\n", num_events)

	event: ^fmod.FMOD_EVENT = nil
	res = fmod.FMOD_EventSystem_GetEventBySystemID(eventsys, wolf.EVENTID_WOLFENSTEINSFX_PLAYER_UNDERWATER, fmod.FMOD_EVENT_DEFAULT, &event)
	if res != .FMOD_OK {
		fmt.printf("%v %v\n", fmod.FMOD_EventSystem_GetEventBySystemID, res)
		return
	}

	position := fmod.FMOD_VECTOR{0, 0, 0}
	velocity := fmod.FMOD_VECTOR{0, 0, 0}
	fmod.FMOD_Event_Set3DAttributes(event, &position, &velocity, nil)

	/*
	res = fmod.FMOD_Event_Start(event)
	if res != .FMOD_OK {
		fmt.printf("%v %v\n", fmod.FMOD_EventSystem_Load, res)
		return
	}
	{
		ch: [1]byte
		os.read(os.stdin, ch[:])
	}
	*/
	fmt.print("Done.\n")
}

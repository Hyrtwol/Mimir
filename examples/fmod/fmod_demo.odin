// +vet
package main

import "core:fmt"
import "libs:tlc/wolf"
import fmod "shared:fmodex"

system: ^fmod.FMOD_SYSTEM = nil
eventsys: ^fmod.FMOD_EVENTSYSTEM = nil

distance_factor :: 1.0


main :: proc() {

	fmt.println("FMOD Event System")

	res := fmod.FMOD_EventSystem_Create(&eventsys)
	if res != .FMOD_OK {
		fmt.println(fmod.FMOD_EventSystem_Create, res)
		return
	}
	defer fmod.FMOD_EventSystem_Release(eventsys)

	fmod_version: fmod.FMOD_VERSION
	res = fmod.FMOD_EventSystem_GetVersion(eventsys, &fmod_version)
	if res != .FMOD_OK {
		fmt.println(fmod.FMOD_EventSystem_GetVersion, res)
		return
	}

	fmt.printfln("Version : %d.%d.%d (0x%x)", fmod_version.Major, fmod_version.Minor, fmod_version.Development, transmute(u32)fmod_version)

	res = fmod.FMOD_EventSystem_GetSystemObject(eventsys, &system)
	if res != .FMOD_OK {
		fmt.println(fmod.FMOD_EventSystem_GetSystemObject, res)
		return
	}

	driver_index: i32 = 0
	res = fmod.FMOD_System_GetDriver(system, &driver_index)
	if res != .FMOD_OK {
		fmt.println(fmod.FMOD_System_GetDriver, res)
		return
	}
	fmt.printfln("Driver      : %x", driver_index)

	{
		name: [256]u8
		name_cstr := cstring(&name[0]) // todo there must be a better way to do this
		guid: fmod.FMOD_GUID
		res = fmod.FMOD_System_GetDriverInfo(system, driver_index, name_cstr, len(name), &guid)
		if res != .FMOD_OK {
			fmt.eprintln("FMOD_System_GetDriverInfo", res)
			return
		}
		driver_name := string(name_cstr)

		fmt.printfln("Driver info : '%s'", driver_name)
		fmt.printfln("Driver guid : %v", guid)
	}

	driver_caps: fmod.FMOD_CAPS
	output_rate: i32
	speaker_mode: fmod.FMOD_SPEAKERMODE
	res = fmod.FMOD_System_GetDriverCaps(system, driver_index, &driver_caps, &output_rate, &speaker_mode)
	if res != .FMOD_OK {
		fmt.eprintln("FMOD_System_GetDriverCaps:", res)
		return
	}

	fmt.printfln("driver caps                : %v", driver_caps)
	fmt.printfln("control panel output rate  : %v", output_rate)
	fmt.printfln("control panel speaker mode : %v", speaker_mode)

	res = fmod.FMOD_System_SetSpeakerMode(system, speaker_mode)

	if .HARDWARE_EMULATED in driver_caps {
		// The user has the 'Acceleration' slider set to off!  This is really bad for latency!
		// You might want to warn the user about this.
		fmt.println("HARDWARE_EMULATED")
		res = fmod.FMOD_System_SetDSPBufferSize(system, 1024, 10)
		// At 48khz, the latency between issuing an fmod command and hearing it will now be about 213ms.
		if res != .FMOD_OK {
			fmt.eprintln("FMOD_System_SetDSPBufferSize:", res)
			return
		}
	}

	init_flags: u32 = fmod.FMOD_INIT_3D_RIGHTHANDED

	res = fmod.FMOD_EventSystem_Init(eventsys, 32, init_flags, nil, fmod.FMOD_EVENT_INIT_NORMAL)
	if res == .FMOD_ERR_OUTPUT_CREATEBUFFER {
		fmt.println("ERR_OUTPUT_CREATEBUFFER Switch it back to stereo...")
		res = fmod.FMOD_System_SetSpeakerMode(system, fmod.FMOD_SPEAKERMODE.FMOD_SPEAKERMODE_STEREO)
		// Ok, the speaker mode selected isn't supported by this soundcard.  Switch it back to stereo...
		res = fmod.FMOD_EventSystem_Init(eventsys, 32, init_flags, nil, fmod.FMOD_EVENT_INIT_NORMAL)
		// Replace with whatever channel count and flags you use!
	}
	if res != .FMOD_OK {
		fmt.eprintln("FMOD_EventSystem_Init:", res)
		return
	}

	// Set the distance units. (meters/feet etc).
	res = fmod.FMOD_System_Set3DSettings(system, 1.0, distance_factor, 1.0)
	if res != .FMOD_OK {
		fmt.eprintln("FMOD_System_Set3DSettings:", res)
		return
	}

	res = fmod.FMOD_EventSystem_Load(eventsys, "WolfensteinSFX.fev", nil, nil)
	if res != .FMOD_OK {
		fmt.eprintln("FMOD_EventSystem_Load:", res)
		return
	}

	num_events: i32
	res = fmod.FMOD_EventSystem_GetNumEvents(eventsys, &num_events)
	if res != .FMOD_OK {
		fmt.eprintln("FMOD_EventSystem_Load", res)
		return
	}
	fmt.printfln("Events : %v", num_events)

	event: ^fmod.FMOD_EVENT = nil
	res = fmod.FMOD_EventSystem_GetEventBySystemID(eventsys, wolf.EVENTID_WOLFENSTEINSFX_PLAYER_UNDERWATER, fmod.FMOD_EVENT_DEFAULT, &event)
	if res != .FMOD_OK {
		fmt.eprintln("FMOD_EventSystem_GetEventBySystemID", res)
		return
	}

	position := fmod.FMOD_VECTOR{0, 0, 0}
	velocity := fmod.FMOD_VECTOR{0, 0, 0}
	fmod.FMOD_Event_Set3DAttributes(event, &position, &velocity, nil)

	/*
	res = fmod.FMOD_Event_Start(event)
	if res != .FMOD_OK {
		fmt.eprintln("FMOD_EventSystem_Load", res)
		return
	}
	{
		ch: [1]byte
		os.read(os.stdin, ch[:])
	}
	*/
	fmt.println("Done.")
}

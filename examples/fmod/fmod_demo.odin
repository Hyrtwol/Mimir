package main

import "core:runtime"
import "core:fmt"
import "core:strings"
import "core:os"
import _c "core:c"
import "../../shared/fmod"
import "../../shared/tlc/wolf"

system: ^fmod.FMOD_SYSTEM = nil
eventsys: ^fmod.FMOD_EVENTSYSTEM = nil

DistanceFactor :: 1.0

GetVersion :: proc() -> (res: int, err: bool) {
	return 666, false
}

main :: proc() {

	//GetVersion() or_return


	fmt.print("FMOD\n")

	/*
	fmt.print("FMOD_System_Create: ")

	res := fmod.FMOD_System_Create(&system)
	fmt.printf("%v\n", res)
	if res != fmod.FMOD_RESULT.FMOD_OK {
		return
	}

	defer fmod.FMOD_System_Release(system)

	version: u32
	res = fmod.FMOD_System_GetVersion(system, &version)
	fmt.printf("%v %x\n", res, version)
	*/

	// fmod_eventsystem

	fmt.print("FMOD Event System\n")

	res := fmod.FMOD_EventSystem_Create(&eventsys)
	if res != fmod.FMOD_RESULT.FMOD_OK {
		fmt.printf("%v %v\n", fmod.FMOD_EventSystem_Create, res)
		return
	}
	defer fmod.FMOD_EventSystem_Release(eventsys)

	version: u32 = 0
	res = fmod.FMOD_EventSystem_GetVersion(eventsys, &version)
	if res != fmod.FMOD_RESULT.FMOD_OK {
		fmt.printf("%v %v\n", fmod.FMOD_EventSystem_GetVersion, res)
		return
	}

	fmod_version := transmute(fmod.FMOD_VERSION)version
	fmt.printf(
		"Version : %d.%d.%d (0x%x)\n",
		fmod_version.Major,
		fmod_version.Minor,
		fmod_version.Development,
		version,
	)

	res = fmod.FMOD_EventSystem_GetSystemObject(eventsys, &system)
	if res != fmod.FMOD_RESULT.FMOD_OK {
		fmt.printf("%v %v\n", fmod.FMOD_EventSystem_GetSystemObject, res)
		return
	}
	//fmt.printf("%v\n", system)

	driver_index: i32 = 0
	res = fmod.FMOD_System_GetDriver(system, &driver_index)
	if res != fmod.FMOD_RESULT.FMOD_OK {
		fmt.printf("%v %v\n", fmod.FMOD_System_GetDriver, res)
		return
	}
	fmt.printf("Driver      : %x\n", driver_index)

	//FMOD_VERSION
	{
		defer fmt.print("defer info\n")

		name: [256]u8
		name_cstr := cstring(&name[0])
		guid: fmod.FMOD_GUID
		res = fmod.FMOD_System_GetDriverInfo(system, driver_index, name_cstr, 256, &guid)
		if res != fmod.FMOD_RESULT.FMOD_OK {
			fmt.printf("%v %v\n", fmod.FMOD_System_GetDriverInfo, res)
			return
		}
		driver_name: string = runtime.cstring_to_string(name_cstr)

		fmt.printf("Driver info : '%s'\n", driver_name)
		fmt.printf("Driver guid : %v\n", guid)
	}

	caps: fmod.FMOD_CAPS_ENUM
	controlpaneloutputrate: _c.int
	controlpanelspeakermode: fmod.FMOD_SPEAKERMODE
	//speakerMode : fmod.FMOD_SPEAKERMODE = 0
	//speakerMode : fmod.FMOD_SPEAKERMODE = 0
	res = fmod.FMOD_System_GetDriverCaps(
		system,
		driver_index,
		&caps,
		&controlpaneloutputrate,
		&controlpanelspeakermode,
	)
	if res != fmod.FMOD_RESULT.FMOD_OK {
		fmt.printf("FMOD_System_GetDriverCaps %v\n", res)
		return
	}

	fmt.printf("caps                    : %x\n", i32(caps))
	fmt.printf("controlpaneloutputrate  : %v\n", controlpaneloutputrate)
	fmt.printf("controlpanelspeakermode : %v\n", controlpanelspeakermode)

	// _system.SetSpeakerMode(fmod.speakerMode).ThrowIfNotOk(); /* Set the user selected speaker mode. */
	res = fmod.FMOD_System_SetSpeakerMode(system, controlpanelspeakermode)

	if ((caps & .HARDWARE_EMULATED) == .HARDWARE_EMULATED) {
		/* The user has the 'Acceleration' slider set to off!  This is really bad for latency!. */
		/* You might want to warn the user about this. */
		fmt.print("HARDWARE_EMULATED\n")
		res = fmod.FMOD_System_SetDSPBufferSize(system, 1024, 10)
		/* At 48khz, the latency between issuing an fmod command and hearing it will now be about 213ms. */
		if res != fmod.FMOD_RESULT.FMOD_OK {
			fmt.printf("FMOD_System_SetDSPBufferSize %v\n", res)
			return
		}
	}

	initflags: u32 = fmod.FMOD_INIT_3D_RIGHTHANDED
	//if (CoordinateSystem.IsRight) initflags |= INITFLAGS._3D_RIGHTHANDED;
	//if (CoordinateSystem.IsRight) initflags |= fmod.FMOD_INIT_3D_RIGHTHANDED;

	//var initResult = _eventSystem.Init(32, initflags, (IntPtr)null);
	res = fmod.FMOD_EventSystem_Init(eventsys, 32, initflags, nil, fmod.FMOD_EVENT_INIT_NORMAL)
	if res == .FMOD_ERR_OUTPUT_CREATEBUFFER {
		fmt.print("ERR_OUTPUT_CREATEBUFFER Switch it back to stereo...\n")
		//fmod.speakerMode = SPEAKERMODE.STEREO;
		res = fmod.FMOD_System_SetSpeakerMode(system, fmod.FMOD_SPEAKERMODE.FMOD_SPEAKERMODE_STEREO)
		/* Ok, the speaker mode selected isn't supported by this soundcard.  Switch it back to stereo... */
		//initResult = _eventSystem.Init(32, initflags, (IntPtr)null);
		res = fmod.FMOD_EventSystem_Init(eventsys, 32, initflags, nil, fmod.FMOD_EVENT_INIT_NORMAL)
		/* Replace with whatever channel count and flags you use! */
	}
	//initResult.ThrowIfNotOk();
	if res != fmod.FMOD_RESULT.FMOD_OK {
		fmt.printf("FMOD_EventSystem_Init %v\n", res)
		return
	}

	// Set the distance units. (meters/feet etc).
	//_system.Set3DSettings(1.0f, DistanceFactor, 1.0f).ThrowIfNotOk();
	res = fmod.FMOD_System_Set3DSettings(system, 1.0, DistanceFactor, 1.0)


	name := "WolfensteinSFX.fev"
	c_str := strings.clone_to_cstring(name, context.temp_allocator)
	res = fmod.FMOD_EventSystem_Load(eventsys, c_str, nil, nil)
	if res != fmod.FMOD_RESULT.FMOD_OK {
		fmt.printf("FMOD_EventSystem_Load %v\n", res)
		return
	}

	num_events: i32
	res = fmod.FMOD_EventSystem_GetNumEvents(eventsys, &num_events)
	if res != fmod.FMOD_RESULT.FMOD_OK {
		fmt.printf("%v %v\n", fmod.FMOD_EventSystem_Load, res)
		return
	}
	fmt.printf("Events : %v\n", num_events)

	/*
	_events = new Event[WolfensteinSFX.EVENTCATEGORYCOUNT_WOLFENSTEINSFX_MASTER];
	for (int i = 0; i < WolfensteinSFX.EVENTCATEGORYCOUNT_WOLFENSTEINSFX_MASTER; i++)
	{
		_events[i] = _audioSystem.GetEventById(i);
	}
	*/

	event : ^fmod.FMOD_EVENT = nil
	res = fmod.FMOD_EventSystem_GetEventBySystemID(eventsys,
		wolf.EVENTID_WOLFENSTEINSFX_PLAYER_UNDERWATER,
		fmod.FMOD_EVENT_DEFAULT, &event)

	/*
	var e = _events[i];
	e.Stop().ThrowIfNotOk();
	Float3 position = Float3.Zero;
	Float3 velocity = Float3.Zero;
	e.Set3DAttributes(ref position, ref velocity).ThrowIfNotOk();
	e.Start().ThrowIfNotOk();
	*/
	// return FMOD_Event_Set3DAttributes(_eventraw, ref position, ref velocity, (IntPtr)null);

	position := fmod.FMOD_VECTOR{0, 0, 0}
	velocity := fmod.FMOD_VECTOR{0, 0, 0}
	fmod.FMOD_Event_Set3DAttributes(event, &position, &velocity, nil)

	res = fmod.FMOD_Event_Start(event)
	if res != fmod.FMOD_RESULT.FMOD_OK {
		fmt.printf("%v %v\n", fmod.FMOD_EventSystem_Load, res)
		return
	}

	{
		ch: [1]byte
		os.read(os.stdin, ch[:])
	}
	fmt.print("Done.\n")
}

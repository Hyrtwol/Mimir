package main

import "core:fmt"
//import "core:runtime"
import "core:os"
import win32 "core:sys/windows"

TITLE :: "Odin operations setup"

setup_windows :: proc() -> int {

	// todo add file registrations https://learn.microsoft.com/en-us/windows/win32/shell/how-to-assign-a-custom-icon-to-a-file-type

	fmt.println("Notify windows to reload icons...")
	win32.SHChangeNotify(win32.SHCNE_ASSOCCHANGED, win32.SHCNF_IDLIST, nil, nil)
	return 0
}

main :: proc() {
	//fmt.printfln("%s (%v %v %v %v)", TITLE, ODIN_VENDOR, ODIN_VERSION, ODIN_OS, ODIN_ARCH)
	fmt.println(TITLE)
	fmt.println(ODIN_VENDOR, ODIN_VERSION, ODIN_ROOT)
	fmt.println(ODIN_OS, ODIN_ARCH)
	exit_code: int = 0
	when ODIN_OS == .Windows {
		exit_code = setup_windows()
	} else {
		fmt.printfln("Sorry this tool dont do anything good on %v for now.", ODIN_OS)
		exit_code = 1
	}
	fmt.println("Done.", exit_code)
	os.exit(exit_code)
}

package main

import "core:fmt"
import "core:os"
import win32 "core:sys/windows"

TITLE :: "Odin setup"

main :: proc() {
	fmt.printf("%s\n", TITLE)

	// https://learn.microsoft.com/en-us/windows/win32/api/shlobj_core/nf-shlobj_core-shchangenotify

	fmt.print("SHChangeNotify\n")
	win32.SHChangeNotify(win32.SHCNE_ASSOCCHANGED, win32.SHCNF_IDLIST, nil, nil)

	fmt.print("Done!\n")
	//os.exit(666)
}

package test_xterm

import vt ".."
import "core:bytes"
import "core:fmt"
import "core:runtime"
import "core:testing"
//import _o "shared:ounit"

@(test)
verify_constants :: proc(t: ^testing.T) {
	exp := "\x1b"
	testing.expectf(t, vt.ESC == exp, "%v != %v", vt.ESC, exp)
	exp = "\x1b["
	testing.expectf(t, vt.CSI == exp, "%v != %v", vt.CSI, exp)
}

@(test)
write_colors :: proc(t: ^testing.T) {
	col := vt.vt_rgb{255, 200, 100}
	vt.vt_printfln(col, "hello")
	fmt.println("bye", "bye")
}

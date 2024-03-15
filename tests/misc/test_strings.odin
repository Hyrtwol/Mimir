package test_misc

import "core:fmt"
import "core:os"
import "core:bytes"
import "core:testing"
import "shared:ascii"
import "shared:ounit"

@(test)
verify_ascii :: proc(t: ^testing.T) {
	ounit.expect_value(t, ascii.control_characters.BEL, '\a')
	ounit.expect_value(t, ascii.control_characters.BS , '\b')
	ounit.expect_value(t, ascii.control_characters.TAB, '\t')
	ounit.expect_value(t, ascii.control_characters.LF , '\n')
	ounit.expect_value(t, ascii.control_characters.VT , '\v')
	ounit.expect_value(t, ascii.control_characters.FF , '\f')
	ounit.expect_value(t, ascii.control_characters.CR , '\r')
}

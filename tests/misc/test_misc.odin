package test_misc

import "core:fmt"
import "core:os"
import "core:testing"
import "shared:ounit"

get_version :: proc() -> (res: int, err: bool) {
	return 666, false
}

// +vet
package test_owin

import _w		".."
import _c		"core:c"
import			"base:intrinsics"
import win32	"core:sys/windows"
import _t		"core:testing"
import o		"libs:ounit"

@(test)
verify_type_sizes :: proc(t: ^_t.T) {
	o.expect_size(t, _w.sbyte, 1);o.expect_size(t, _w.SByte, 1)
	o.expect_size(t, _w.byte, 1);o.expect_size(t, _w.Byte, 1)
	o.expect_size(t, _w.short, 2);o.expect_size(t, _w.Int16, 2)
	o.expect_size(t, _w.ushort, 2);o.expect_size(t, _w.UInt16, 2)
	o.expect_size(t, _w.int, 4);o.expect_size(t, _w.Int32, 4)
	o.expect_size(t, _w.uint, 4);o.expect_size(t, _w.UInt32, 4)
	o.expect_size(t, _w.long, 8);o.expect_size(t, _w.Int64, 8)
	o.expect_size(t, _w.ulong, 8);o.expect_size(t, _w.UInt64, 8)
	o.expect_size(t, _w.nint, 8);o.expect_size(t, _w.IntPtr, 8)
	o.expect_size(t, _w.nuint, 8);o.expect_size(t, _w.UIntPtr, 8)
	o.expect_size(t, _w.float, 4);o.expect_size(t, _w.Single, 4)
	o.expect_size(t, _w.double, 8);o.expect_size(t, _w.Double, 8)
	o.expect_size(t, _w.bool, 1);o.expect_size(t, _w.Bool, 1)
	o.expect_size(t, _w.char, 2);o.expect_size(t, _w.Char, 2)
	o.expect_size(t, _w.string, 8);o.expect_size(t, _w.String, 8)

	o.expect_value(t, size_of(_w.byte), size_of(_c.char))
	o.expect_value(t, size_of(_w.sbyte), size_of(_c.schar))
	o.expect_value(t, size_of(_w.short), size_of(_c.short))
	o.expect_value(t, size_of(_w.ushort), size_of(_c.ushort))
	o.expect_value(t, size_of(_w.int), size_of(_c.int))
	o.expect_value(t, size_of(_w.uint), size_of(_c.uint))
	o.expect_value(t, size_of(_w.long), size_of(_c.longlong))
	o.expect_value(t, size_of(_w.ulong), size_of(_c.ulonglong))
	o.expect_value(t, size_of(_w.nint), size_of(_c.intptr_t))
	o.expect_value(t, size_of(_w.nuint), size_of(_c.uintptr_t))
	o.expect_value(t, size_of(_w.float), size_of(_c.float))
	o.expect_value(t, size_of(_w.double), size_of(_c.double))
	o.expect_value(t, size_of(_w.bool), size_of(_c.bool))
	o.expect_value(t, size_of(_w.char), size_of(_c.wchar_t))

	o.expect_value(t, size_of(_w.char), size_of(win32.WCHAR))
	o.expect_value(t, size_of(_w.string), size_of(win32.wstring))
}

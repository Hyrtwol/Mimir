#+vet
package test_csharp

import cs ".."
import "base:intrinsics"
import _c "core:c"
import win32 "core:sys/windows"
import "core:testing"
import o "shared:ounit"

@(test)
verify_type_sizes :: proc(t: ^testing.T) {
	o.expect_size(t, cs.sbyte , 1);o.expect_size(t, cs.SByte  , 1)
	o.expect_size(t, cs.byte  , 1);o.expect_size(t, cs.Byte   , 1)
	o.expect_size(t, cs.short , 2);o.expect_size(t, cs.Int16  , 2)
	o.expect_size(t, cs.ushort, 2);o.expect_size(t, cs.UInt16 , 2)
	o.expect_size(t, cs.int   , 4);o.expect_size(t, cs.Int32  , 4)
	o.expect_size(t, cs.uint  , 4);o.expect_size(t, cs.UInt32 , 4)
	o.expect_size(t, cs.long  , 8);o.expect_size(t, cs.Int64  , 8)
	o.expect_size(t, cs.ulong , 8);o.expect_size(t, cs.UInt64 , 8)
	o.expect_size(t, cs.nint  , 8);o.expect_size(t, cs.IntPtr , 8)
	o.expect_size(t, cs.nuint , 8);o.expect_size(t, cs.UIntPtr, 8)
	o.expect_size(t, cs.float , 4);o.expect_size(t, cs.Single , 4)
	o.expect_size(t, cs.double, 8);o.expect_size(t, cs.Double , 8)
	o.expect_size(t, cs.bool  , 1);o.expect_size(t, cs.Bool   , 1)
	o.expect_size(t, cs.char  , 2);o.expect_size(t, cs.Char   , 2)
	o.expect_size(t, cs.string, 8);o.expect_size(t, cs.String , 8)
}

@(test)
compare_type_sizes_c :: proc(t: ^testing.T) {
	o.expect_value(t, size_of(cs.byte)   , size_of(_c.char)      )
	o.expect_value(t, size_of(cs.sbyte)  , size_of(_c.schar)     )
	o.expect_value(t, size_of(cs.short)  , size_of(_c.short)     )
	o.expect_value(t, size_of(cs.ushort) , size_of(_c.ushort)    )
	o.expect_value(t, size_of(cs.int)    , size_of(_c.int)       )
	o.expect_value(t, size_of(cs.uint)   , size_of(_c.uint)      )
	o.expect_value(t, size_of(cs.long)   , size_of(_c.longlong)  )
	o.expect_value(t, size_of(cs.ulong)  , size_of(_c.ulonglong) )
	o.expect_value(t, size_of(cs.nint)   , size_of(_c.intptr_t)  )
	o.expect_value(t, size_of(cs.nuint)  , size_of(_c.uintptr_t) )
	o.expect_value(t, size_of(cs.float)  , size_of(_c.float)     )
	o.expect_value(t, size_of(cs.double) , size_of(_c.double)    )
	o.expect_value(t, size_of(cs.bool)   , size_of(_c.bool)      )
	o.expect_value(t, size_of(cs.char)   , size_of(_c.wchar_t)   )
}

@(test)
compare_type_sizes_win32 :: proc(t: ^testing.T) {
	o.expect_value(t, size_of(cs.char)   , size_of(win32.WCHAR)  )
	o.expect_value(t, size_of(cs.string) , size_of(win32.wstring))
}

package xterm

import "core:fmt"

ESC :: "\x1B"
CSI :: ESC + "["

vt_rgb :: [3]u8
vt_int2 :: [2]i32

vt_set_foreground_color :: #force_inline proc(col: vt_rgb) {
	fmt.printf("%s[38;2;%d;%d;%dm", ESC, col.r, col.g, col.b)
}

vt_set_background_color :: #force_inline proc(col: vt_rgb) {
	fmt.printf("%s[48;2;%d;%d;%dm", ESC, col.r, col.g, col.b)
}

vt_restore_color :: #force_inline proc() {
	fmt.printf("%s0m", CSI)
}

vt_enter_line_drawing_mode :: #force_inline proc() {
	fmt.printf("%s(0", CSI)
}

vt_exit_line_drawing_mode :: #force_inline proc() {
	fmt.printf("%s(B", CSI)
}

vt_set_cursor_position :: #force_inline proc(pos: vt_int2) {
	fmt.printf("%s%d;%dH", CSI, pos.x, pos.y)
}

vt_set_cursor_position_home :: #force_inline proc() {
	fmt.printf("%sH", CSI)
}

vt_clear :: #force_inline proc(mode: i32) {
	fmt.printf("%s%dJ", CSI, mode)
}

vt_print :: proc(col: vt_rgb, text: string) {
	vt_set_foreground_color(col)
	fmt.print(text)
	vt_restore_color()
}

vt_println :: proc(col: vt_rgb, text: string) {
	vt_print(col, text)
	fmt.println()
}

vt_printf :: proc(col: vt_rgb, format: string, args: ..any, flush := true) {
	vt_set_foreground_color(col)
	fmt.printf(format, args = args, flush = flush)
	vt_restore_color()
}

vt_printfln :: proc(col: vt_rgb, format: string, args: ..any, flush := true) {
	vt_printf(col, format, args = args, flush = flush)
	fmt.println()
}

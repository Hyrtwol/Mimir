package z80

foreign import "Z80.lib"

zusize :: u64
zuint8 :: u8
zuint16 :: u16
zuint32 :: u32
zint16 :: i16
zint32 :: i32
zboolean :: bool

Z80_MAXIMUM_CYCLES :: max(zuint32) - 30
Z80_MAXIMUM_CYCLES_PER_STEP :: 23

Z80_HOOK :: 0x64

Z80_SF :: 128
Z80_ZF :: 64
Z80_YF :: 32
Z80_HF :: 16
Z80_XF :: 8
Z80_PF :: 4
Z80_NF :: 2
Z80_CF :: 1


Z80_OPTION_OUT_VC_255 :: 1
Z80_OPTION_LD_A_IR_BUG :: 2
Z80_OPTION_HALT_SKIP :: 4
Z80_OPTION_XQ :: 8
Z80_OPTION_IM0_RETX_NOTIFICATIONS :: 16
Z80_OPTION_YQ :: 32

Z80_MODEL_ZILOG_NMOS :: (Z80_OPTION_LD_A_IR_BUG | Z80_OPTION_XQ | Z80_OPTION_YQ)
Z80_MODEL_ZILOG_CMOS :: (Z80_OPTION_OUT_VC_255 | Z80_OPTION_XQ | Z80_OPTION_YQ)
Z80_MODEL_NEC_NMOS :: Z80_OPTION_LD_A_IR_BUG
Z80_MODEL_ST_CMOS :: (Z80_OPTION_OUT_VC_255 | Z80_OPTION_LD_A_IR_BUG | Z80_OPTION_YQ)

Z80_REQUEST_REJECT_NMI :: 2
Z80_REQUEST_NMI :: 4
Z80_REQUEST_INT :: 8
Z80_REQUEST_SPECIAL_RESET :: 16

Z80_RESUME_HALT :: 1
Z80_RESUME_XY :: 2
Z80_RESUME_IM0_XY :: 3

Z80_HALT_EXIT :: 0
Z80_HALT_ENTER :: 1
Z80_HALT_EXIT_EARLY :: 2
Z80_HALT_CANCEL :: 3

PZ80 :: ^TZ80

// Z80Read :: #type proc "c" (zcontext: rawptr, address: zuint16) -> zuint8
// Z80Write :: #type proc "c" (zcontext: rawptr, address: zuint16, value: zuint8)
// Z80Halt :: #type proc "c" (zcontext: rawptr, signal: zuint8)
// Z80Notify :: #type proc "c" (zcontext: rawptr)
// Z80Illegal :: #type proc "c" (zcpu: PZ80, opcode: zuint8) -> zuint8

Z80Read :: #type proc(zcontext: rawptr, address: zuint16) -> zuint8
Z80Write :: #type proc(zcontext: rawptr, address: zuint16, value: zuint8)
Z80Halt :: #type proc(zcontext: rawptr, signal: zuint8)
Z80Notify :: #type proc(zcontext: rawptr)
Z80Illegal :: #type proc(zcpu: PZ80, opcode: zuint8) -> zuint8

TZ80 :: struct {
	/** @brief Number of clock cycles already executed. */
	cycles:       zusize,

	/** @brief Maximum number of clock cycles to be executed. */
	cycle_limit:  zusize,

	/** @brief Pointer to pass as the first argument to all callback
	  * functions.
	  *
	  * This member is intended to hold a reference to the context to which
	  * the object belongs. It is safe not to initialize it when this is not
	  * necessary. */
	_context:     rawptr,

	/** @brief Invoked to perform an opcode fetch.
	  *
	  * This callback indicates the beginning of an opcode fetch M-cycle.
	  * The function must return the byte located at the memory address
	  * specified by the second argument. */
	fetch_opcode: Z80Read,

	/** @brief Invoked to perform a memory read on instruction data.
	  *
	  * This callback indicates the beginning of a memory read M-cycle
	  * during which the CPU fetches one byte of instruction data (i.e., one
	  * byte of the instruction that is neither a prefix nor an opcode). The
	  * function must return the byte located at the memory address
	  * specified by the second argument. */
	fetch:        Z80Read,

	/** @brief Invoked to perform a memory read.
	  *
	  * This callback indicates the beginning of a memory read M-cycle. The
	  * function must return the byte located at the memory address
	  * specified by the second argument. */
	read:         Z80Read,

	/** @brief Invoked to perform a memory write.
	  *
	  * This callback indicates the beginning of a memory write M-cycle. The
	  * function must write the third argument into the memory location
	  * specified by the second argument. */
	write:        Z80Write,

	/** @brief Invoked to perform an I/O port read.
	  *
	  * This callback indicates the beginning of an I/O read M-cycle. The
	  * function must return the byte read from the I/O port specified by
	  * the second argument. */
	_in:          Z80Read,

	/** @brief Invoked to perform an I/O port write.
	  *
	  * This callback indicates the beginning of an I/O write M-cycle. The
	  * function must write the third argument to the I/O port specified by
	  * the second argument. */
	out:          Z80Write,

	/** @brief Invoked to notify a signal change on the HALT line.
	  *
	  * This callback is optional and must be set to @c Z_NULL when not in
	  * use. Its invocation is always deferred until the next emulation step
	  * so that the emulator can abort the signal change if any invalidating
	  * condition occurs, such as the acceptance of an interrupt during the
	  * execution of a @c halt instruction.
	  *
	  * The second parameter of the function specifies the type of signal
	  * change and can only contain a boolean value if the Z80 library has
	  * not been built with special RESET support:
	  *
	  * - @c 1 indicates that the HALT line is going low during the last
	  *   clock cycle of a @c halt instruction, which means that the CPU
	  *   is entering the HALT state.
	  *
	  * - @c 0 indicates that the HALT line is going high during the last
	  *   clock cycle of an internal NOP executed during the HALT state,
	  *   i.e., the CPU is exiting the HALT state due to an interrupt or
	  *   normal RESET.
	  *
	  * If the library has been built with special RESET support, the values
	  * <tt>@ref Z80_HALT_EXIT_EARLY</tt> and <tt>@ref Z80_HALT_CANCEL</tt>
	  * are also possible for the second parameter. */
	halt:         Z80Halt,

	/** @brief Invoked to perform an opcode fetch that corresponds to an
	  * internal NOP.
	  *
	  * This callback indicates the beginning of an opcode fetch M-cycle of
	  * 4 clock cycles that is generated in the following two cases:
	  *
	  * - During the HALT state, the CPU repeatedly executes an internal NOP
	  *   that fetches the next opcode after the @c halt instruction without
	  *   incrementing the PC register. This opcode is read again and again
	  *   until an exit condition occurs (i.e., NMI, INT or RESET).
	  *
	  * - After detecting a special RESET signal, the CPU completes the
	  *   ongoing instruction or interrupt response and then zeroes the PC
	  *   register during the first clock cycle of the next M1 cycle. If no
	  *   interrupt has been accepted at the end of the instruction or
	  *   interrupt response, the CPU produces an internal NOP to allow for
	  *   the fetch-execute overlap to take place, during which it fetches
	  *   the next opcode and zeroes PC.
	  *
	  * This callback is optional but note that setting it to @c Z_NULL is
	  * equivalent to enabling <tt>@ref Z80_OPTION_HALT_SKIP</tt>. */
	nop:          Z80Read,

	/** @brief Invoked to perform an opcode fetch that corresponds to a
	  * non-maskable interrupt acknowledge M-cycle.
	  *
	  * This callback is optional and must be set to @c Z_NULL when not in
	  * use. It indicates the beginning of an NMI acknowledge M-cycle. The
	  * value returned by the function is ignored. */
	nmia:         Z80Read,

	/** @brief Invoked to perform a data bus read that corresponds to a
	  * maskable interrupt acknowledge M-cycle.
	  *
	  * This callback is optional and must be set to @c Z_NULL when not in
	  * use. It indicates the beginning of an INT acknowledge M-cycle. The
	  * function must return the byte that the interrupting I/O device
	  * supplies to the CPU via the data bus during this M-cycle.
	  *
	  * When this callback is @c Z_NULL, the emulator assumes that the value
	  * read from the data bus is @c 0xFF. */
	inta:         Z80Read,

	/** @brief Invoked to perform a memory read on instruction data during a
	  * maskable interrupt response in mode 0.
	  *
	  * The role of this callback is analogous to that of
	  * <tt>@ref Z80::fetch</tt>, but it is specific to the INT response in
	  * mode 0. Ideally, the function should return a byte of instruction
	  * data that the interrupting I/O device supplies to the CPU via the
	  * data bus, but depending on the emulated hardware, the device may not
	  * be able to do this during a memory read M-cycle because the memory
	  * is addressed instead, in which case the function must return the
	  * byte located at the memory address specified by the second
	  * parameter.
	  *
	  * This callback will only be invoked if <tt>@ref Z80::inta</tt> is not
	  * @c Z_NULL and returns an opcode that implies subsequent memory read
	  * M-cycles to fetch the non-opcode bytes of the instruction, so it is
	  * safe not to initialize it or set it to @c Z_NULL if such a scenario
	  * is not possible. */
	int_fetch:    Z80Read,

	/** @brief Invoked to notify that an <tt>ld i,a</tt> instruction has
	  * been fetched.
	  *
	  * This callback is optional and must be set to @c Z_NULL when not in
	  * use. It is invoked before executing the instruction. */
	ld_i_a:       Z80Notify,

	/** @brief Invoked to notify that an <tt>ld r,a</tt> instruction has
	  * been fetched.
	  *
	  * This callback is optional and must be set to @c Z_NULL when not in
	  * use. It is invoked before executing the instruction. */
	ld_r_a:       Z80Notify,

	/** @brief Invoked to notify that a @c reti instruction has been
	  * fetched.
	  *
	  * This callback is optional and must be set to @c Z_NULL when not in
	  * use. It is invoked before executing the instruction. */
	reti:         Z80Notify,

	/** @brief Invoked to notify that a @c retn instruction has been
	  * fetched.
	  *
	  * This callback is optional and must be set to @c Z_NULL when not in
	  * use. It is invoked before executing the instruction. */
	retn:         Z80Notify,

	/** @brief Invoked when a trap is fetched.
	  *
	  * This callback is optional and must be set to @c Z_NULL when not in
	  * use, in which case the opcode of the trap will be executed normally.
	  * The function receives the memory address of the trap as the second
	  * parameter and must return the opcode to be executed instead of the
	  * trap. If the function returns a trap (i.e., <tt>@ref Z80_HOOK</tt>),
	  * the emulator will do nothing, so the trap will be fetched again
	  * unless the function has modified <tt>@ref Z80::pc</tt> or replaced
	  * the trap in memory with another opcode. Also note that returning a
	  * trap does not revert the increment of <tt>@ref Z80::r</tt> performed
	  * before each opcode fetch. */
	hook:         Z80Read,

	/** @brief Invoked to delegate the execution of an illegal instruction.
	  *
	  * This callback is optional and must be set to @c Z_NULL when not in
	  * use. Only those instructions with the @c 0xED prefix that behave the
	  * same as two consecutive @c nop instructions are considered illegal.
	  * The function receives the illegal opcode as the second parameter and
	  * must return the number of clock cycles taken by the instruction.
	  *
	  * At the time of invoking this callback, and relative to the start of
	  * the instruction, only <tt>@ref Z80::r</tt> has been incremented
	  * (twice), so <tt>@ref Z80::pc</tt> still contains the memory address
	  * of the @c 0xED prefix. */
	illegal:      Z80Illegal,

	/** @brief Temporary storage used for instruction fetch. */
	data:         zint32,
	ix_iy:        [2]zuint16, /**< @brief Index registers, IX and IY.    */
	pc:           zuint16, /**< @brief Register PC (program counter). */
	sp:           zuint16, /**< @brief Register SP (stack pointer).   */

	/** @brief Temporary index register.
	  *
	  * All instructions with the @c 0xDD prefix behave exactly the same as
	  * their counterparts with the @c 0xFD prefix, differing only in the
	  * index register: the former use IX, whereas the latter use IY. When
	  * one of these prefixes is fetched, the corresponding index register
	  * is copied into this member; the instruction logic is then executed
	  * and finally this member is copied back into the index register. */
	xy:           zint16,
	memptr:       zint16, /**< @brief Register MEMPTR, also known as WZ.        */
	af:           zint16, /**< @brief Register pair AF (accumulator and flags). */
	bc:           zint16, /**< @brief Register pair BC.                         */
	de:           zint16, /**< @brief Register pair DE.                         */
	hl:           zint16, /**< @brief Register pair HL.                         */
	af_:          zint16, /**< @brief Register pair AF'.                        */
	bc_:          zint16, /**< @brief Register pair BC'.                        */
	de_:          zint16, /**< @brief Register pair DE'.                        */
	hl_:          zint16, /**< @brief Register pair HL'.                        */
	r:            zuint8, /**< @brief Register R (memory refresh).              */
	i:            zuint8, /**< @brief Register I (interrupt vector base).       */

	/** @brief Backup of bit 7 of the R register.
	  *
	  * The Z80 CPU increments the R register during each M1 cycle without
	  * altering its most significant bit, commonly known as R7. However,
	  * the emulator only performs normal full-byte increments for speed
	  * reasons, which eventually corrupts R7.
	  *
	  * Before entering the execution loop, both <tt>@ref z80_execute</tt>
	  * and <tt>@ref z80_run</tt> copy <tt>@ref Z80::r</tt> into this member
	  * to preserve the value of R7, so that they can restore it before
	  * returning. The emulation of the <tt>ld r, a</tt> instruction also
	  * updates the value of this member. */
	r7:           zuint8,

	/** @brief Maskable interrupt mode.
	  *
	  * Contains the number of the maskable interrupt mode in use: @c 0,
	  * @c 1 or @c 2. */
	im:           zuint8,

	/** @brief Requests pending to be responded. */
	request:      zuint8,

	/** @brief Type of unfinished operation to be resumed. */
	resume:       zuint8,
	iff1:         zuint8, /**< @brief Interrupt enable flip-flop #1 (IFF1). */
	iff2:         zuint8, /**< @brief Interrupt enable flip-flop #2 (IFF2). */
	q:            zuint8, /**< @brief Pseudo-register Q. */

	/** @brief Emulation options.
	  *
	  * This member specifies the different emulation options that are
	  * enabled. It is mandatory to initialize it before using the emulator.
	  * Setting it to @c 0 disables all options. */
	options:      zuint8,

	/** @brief State of the INT line.
	  *
	  * The value of this member is @c 1 if the INT line is low; otherwise,
	  * @c 0. */
	int_line:     zuint8,

	/** @brief State of the HALT line.
	  *
	  * The value of this member is @c 1 if the HALT line is low; otherwise,
	  * @c 0. The emulator updates this member before invoking
	  * <tt>@ref Z80::halt</tt>, not after. */
	halt_line:    zuint8,
}

//@(default_calling_convention = "c", link_prefix = "Newton")
@(default_calling_convention = "c")
foreign Z80 {

	/** @brief Sets the power state of a <tt>@ref Z80</tt>.
	*
	* @param self Pointer to the object on which the function is called.
	* @param state
	*   @c Z_TRUE  = power on;
	*   @c Z_FALSE = power off. */
	z80_power :: proc(self: PZ80, state: zboolean) ---

	/** @brief Performs an instantaneous normal RESET on a <tt>@ref Z80</tt>.
	*
	* @param self Pointer to the object on which the function is called. */
	z80_instant_reset :: proc(self: PZ80) ---

	/** @brief Sends a special RESET signal to a <tt>@ref Z80</tt>.
	*
	* @sa
	* - http://www.primrosebank.net/computers/z80/z80_special_reset.htm
	* - US Patent 4486827
	*
	* @param self Pointer to the object on which the function is called. */
	z80_special_reset :: proc(self: PZ80) ---

	/** @brief Sets the state of the INT line of a <tt>@ref Z80</tt>.
	*
	* @param self Pointer to the object on which the function is called.
	* @param state
	*   @c Z_TRUE  = set line low;
	*   @c Z_FALSE = set line high. */
	z80_int :: proc(self: PZ80, state: zboolean) ---

	/** @brief Triggers the NMI line of a <tt>@ref Z80</tt>.
	*
	* @param self Pointer to the object on which the function is called. */
	z80_nmi :: proc(self: PZ80) ---

	/** @brief Runs a <tt>@ref Z80</tt> for a given number of clock @p cycles,
	* executing only instructions without responding to signals.
	*
	* @param self Pointer to the object on which the function is called.
	* @param cycles Number of clock cycles to be emulated.
	* @return The actual number of clock cycles emulated. */
	z80_execute :: proc(self: PZ80, cycles: zusize) -> zusize ---

	/** @brief Runs a <tt>@ref Z80</tt> for a given number of clock @p cycles.
	*
	* @param self Pointer to the object on which the function is called.
	* @param cycles Number of clock cycles to be emulated.
	* @return The actual number of clock cycles emulated. */
	z80_run :: proc(self: PZ80, cycles: zusize) -> zusize ---
}

/** @brief Ends the emulation loop of <tt>@ref z80_execute</tt> or
  * <tt>@ref z80_run</tt>.
  *
  * This function should only be used inside callback functions. It zeroes
  * <tt>@ref Z80::cycle_limit</tt>, thus breaking the emulation loop after the
  * ongoing emulation step has finished executing.
  *
  * @param self Pointer to the object on which the function is called. */

z80_break :: #force_inline proc(self: PZ80) {self.cycle_limit = 0}

/** @brief Gets the full value of the R register of a <tt>@ref Z80</tt>.
  *
  * @param self Pointer to the object on which the function is called.
  * @return The value of the R register. */

z80_r :: #force_inline proc(self: PZ80) -> zuint8 {
	return (self.r & 127) | (self.r7 & 128)
}

/** @brief Obtains the refresh address of the M1 cycle being executed by a
  * <tt>@ref Z80</tt>.
  *
  * @param self Pointer to the object on which the function is called.
  * @return The refresh address. */

z80_refresh_address :: #force_inline proc(self: PZ80) -> zuint16 {
	return zuint16((zuint16(self.i) << 8) | zuint16((self.r - 1) & 127) | zuint16(self.r7 & 128))
}


/** @brief Obtains the clock cycle, relative to the start of the instruction, at
  * which the I/O read M-cycle being executed by a <tt>@ref Z80</tt> begins.
  *
  * @param self Pointer to the object on which the function is called.
  * @return The clock cycle at which the I/O read M-cycle begins. */

z80_in_cycle :: #force_inline proc(self: PZ80) -> zuint8 {
	d := transmute([4]zuint8)self.data
	x: zint32 = 7 if d[0] == 0xDB else 8
	return zuint8(x + (zint32(d[1]) >> 7))
}

/** @brief Obtains the clock cycle, relative to the start of the instruction, at
  * which the I/O write M-cycle being executed by a <tt>@ref Z80</tt> begins.
  *
  * @param self Pointer to the object on which the function is called.
  * @return The clock cycle at which the I/O write M-cycle begins. */

z80_out_cycle :: #force_inline proc(self: PZ80) -> zuint8 {
	d := transmute([4]zuint8)self.data
	x: zint32 = 7 if d[0] == 0xD3 else 8
	return zuint8(x + ((zint32(d[1]) >> 7) << 2))
}

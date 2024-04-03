package amstrad

import "core:os"

// https://www.cpcwiki.eu/index.php/Format:DSK_disk_image_file_format
// EXTENDED CPC DSK File

disk_image_file_extension :: ".DSK"
disk_image_id :: "EXTENDED CPC DSK File\r\nDisk-Info\r\n"
/*
00 - 21	"EXTENDED CPC DSK File\r\nDisk-Info\r\n"	34
22 - 2f	name of creator (utility/emulator)	14
30	number of tracks	1
31	number of sides	1
32 - 33	unused	2
34 - xx	track size table	number of tracks*number of sides
*/
disc_information_block :: struct #packed {
	id:               [34]u8,
	name_of_creator:  [14]u8,
	number_of_tracks: u8,
	number_of_sides:  u8,
	_:                [2]u8,
	//track_size_table: []u8,
}
p_disc_information_block :: ^disc_information_block

track_information_block_id :: "Track-Info\r\n"
/*
offset	description	bytes
00 - 0b	"Track-Info\r\n"	12
0c - 0f	unused	4
10	track number	1
11	side number	1
12 - 13	unused	2
14	sector size	1
15	number of sectors	1
16	GAP#3 length	1
17	filler byte	1
18 - xx	Sector Information List	xx
*/
track_information_block :: struct #packed {
	id:                [12]u8,
	_:                 [4]u8,
	track_number:      u8,
	side_number:       u8,
	_:                 [2]u8,
	sector_size:       u8,
	number_of_sectors: u8,
	gap_3_length:      u8,
	filler_byte:       u8,
}
p_track_information_block :: ^track_information_block
/*
SECTOR INFORMATION LIST
offset	description	bytes
00	track (equivalent to C parameter in NEC765 commands)	1
01	side (equivalent to H parameter in NEC765 commands)	1
02	sector ID (equivalent to R parameter in NEC765 commands)	1
03	sector size (equivalent to N parameter in NEC765 commands)	1
04	FDC status register 1 (equivalent to NEC765 ST1 status register)	1
05	FDC status register 2 (equivalent to NEC765 ST2 status register)	1
06 - 07	actual data length in bytes	2
*/
sector_info :: struct {}

registers :: struct #packed {
	F, A, C, B, E, D, L, H: u8,
}

cpu_type :: enum u8 {
	CPC464       = 0,
	CPC664       = 1,
	CPC6128      = 2,
	unknown      = 3,
	CPC6128_Plus = 4,
	CPC464_Plus  = 5,
	GX4000       = 6,
}

crtc_type :: enum u8 {
	HD6845S_UM6845  = 0,
	UM6845R         = 1,
	MC6845          = 2,
	MC6845_CPC_ASIC = 3,
	MC6845_PRE_ASIC = 4,
}

snapshot_file_extension :: ".DSK"
snapshot_id :: "MV - SNA"

// https://www.cpcwiki.eu/index.php/Format:SNA_snapshot_file_format
snapshot :: struct #packed {
	id:                         [8]u8, // 00-07 (8) The identification string "MV - SNA". This must exist for the snapshot to be valid.
	_:                          [8]u8, // 08-0f	(8) (not used; set to 0)
	version:                    u8, // 10 snapshot version
	regs:                       registers, // 11-18 registers
	R, I:                       u8, // 19 memory refresh, 1a interrupt vector base
	IFF0:                       u8, // 1b interrupt flip-flop
	IFF1:                       u8, // 1c interrupt flip-flop
	IX:                         u16, // 1d-1e
	IY:                         u16, // 1f-20
	SP:                         u16, // 21-22
	PC:                         u16, // 23-24
	interrupt_mode:             u8, // 25 (0,1,2) (note 3)
	alt_regs:                   registers, // 26-2d alternate registers
	pen:                        u8, // 2e GA: index of selected pen (note 10)
	palette:                    [17]u8, // 2f-3f (17) GA: current palette (note 11)
	multi_conf:                 u8, // 40 GA: multi configuration (note 12)
	ram_conf:                   u8, // 41 current RAM configuration (note 13)
	crtc_sel:                   u8, // 42 CRTC: index of selected register (note 14)
	crtc_data:                  [18]u8, // 43-54 (18) CRTC: register data (0..17) (note 15)
	current_rom:                u8, // 55 current ROM selection (note 16)
	PPI_A:                      u8, // 56 port A (note 6)
	PPI_B:                      u8, // 57 port B (note 7)
	PPI_C:                      u8, // 58 port C (note 8)
	PPI_ctrl:                   u8, // 59 control port (note 9)
	PSG_sel:                    u8, // 5a index of selected register (note 17)
	PSG_data:                   [16]u8, // 5b-6a (16) register data (0,1,....15)
	memory_dump_size:           u16, // 6b-6c memory dump size in Kilobytes (e.g. 64 for 64K, 128 for 128k) (note 18)
	cpc_type:                   cpu_type, // 6d (1) CPC type:
	interrupt_number:           u8, // 6e interrupt number (0..5) (note 1a)
	multimode_bytes:            [6]u8, // 6f-74 (6) multimode bytes (note 1b)
	_:                          [27]u8,
	fdd_motor_drive_state:      u8, // 9C FDD motor drive state (0=off, 1=on)
	fdd_current_physical_track: [4]u8, // 9D-A0 (4)	FDD current physical track (note 15)
	printer_data:               u8, // A1 Printer Data/Strobe Register (note 1)
	_:                          [2]u8, // A2-A3   (2) ??
	crtc_type:                  crtc_type, // A4 (1) CRTC type:

	/*
	Offset	Count	Description
	00-07	8	The identification string "MV - SNA". This must exist for the snapshot to be valid.
	08-0f	8	(not used; set to 0)
	10		1	snapshot version (1)
	11		1	Z80 register F
	12		1	Z80 register A
	13		1	Z80 register C
	14		1	Z80 register B
	15		1	Z80 register E
	16		1	Z80 register D
	17		1	Z80 register L
	18		1	Z80 register H
	19		1	Z80 register R
	1a		1	Z80 register I
	1b		1	Z80 interrupt flip-flop IFF0 (note 2)
	1c		1	Z80 interrupt flip-flop IFF1 (note 2)
	1d		1	Z80 register IX (low) (note 5)
	1e		1	Z80 register IX (high) (note 5)
	1f		1	Z80 register IY (low) (note 5)
	20		1	Z80 register IY (high) (note 5)
	21		1	Z80 register SP (low) (note 5)
	22		1	Z80 register SP (high) (note 5)
	23		1	Z80 register PC (low) (note 5)
	24		1	Z80 register PC (high) (note 5)
	25		1	Z80 interrupt mode (0,1,2) (note 3)
	26		1	Z80 register F' (note 4)
	27		1	Z80 register A' (note 4)
	28		1	Z80 register C' (note 4)
	29		1	Z80 register B' (note 4)
	2a		1	Z80 register E' (note 4)
	2b		1	Z80 register D' (note 4)
	2c		1	Z80 register L' (note 4)
	2d		1	Z80 register H' (note 4)
	2e		1	GA: index of selected pen (note 10)
	2f-3f	17	GA: current palette (note 11)
	40		1	GA: multi configuration (note 12)
	41		1	current RAM configuration (note 13)
	42		1	CRTC: index of selected register (note 14)
	43-54	18	CRTC: register data (0..17) (note 15)
	55		1	current ROM selection (note 16)
	56		1	PPI: port A (note 6)
	57		1	PPI: port B (note 7)
	58		1	PPI: port C (note 8)
	59		1	PPI: control port (note 9)
	5a		1	PSG: index of selected register (note 17)
	5b-6a	16	PSG: register data (0,1,....15)
	6b-6c	1	memory dump size in Kilobytes (e.g. 64 for 64K, 128 for 128k) (note 18)

	Notes:
		1. All multi-byte values are stored in little-endian format (low byte followed by higher bytes).
		2. "IFF0" reflects the state of the maskable interrupt (INT). "IFF1" is used to store the state of IFF0 when a non-maskable interrupt (NMI) is executed. Bit 0 of these bytes is significant. For CPCEMU compatibility, these bytes should be set to "1" when the IFF flip-flop is "1" and "0" when the flip-flop is "0". For compatibility with other emulators, bits 7-1 should be set to "0". When bit 0 of "IFF0" is "0" maskable interrupts will be ignored. When bit 0 of "IFF1" is "1" maskable interrupts will be acknowledged and executed. See the document about the Z80 for more information.
		3. This byte will be 0, 1 or 2 for the interrupt modes 0, 1 or 2. The interrupt mode is set using the "IM x" instructions. See the document about the Z80 for more information.
		4. These registers are from the alternate register set of the Z80.
		5. These registers are 16-bit. "low" indicates bits 7..0, "high"indicates bits 15..8.
		6. This byte represents the inputs to PPI port A regardless of the input/output setting of this port.
		7. This byte represents the inputs to PPI port B regardless of the input/output setting of this port.
		8. This byte represents the outputs from port C regardless of the input/output setting of this port.
		9. This byte represents the PPI control byte which defines the input/output and mode of each port and not the last value written to this port. For CPCEMU compatibility bit 7 of this byte must be set to "1".
		10. This byte in the snapshot represents the selected pen register of the Gate-Array. This byte is the last value written to this port. Bit 7,6,5 should be set to "0".
		11. This byte in the snapshot represents the multi-configuration register of the Gate-Array. This byte is the last byte written to this register. For CPCEMU compatibility, bit 7 should be set to "1" and bit 6 and bit 5 set to "0".
		12. These bytes are the current palette. For CPCEMU compatibility, these bytes should have bit 7=bit 6=bit 5="0". Bits 4..0 define the colour using the hardware colour code. The colours are stored in the order pen 0, pen1, pen 2,...,pen 15 followed by border colour.
		13. This byte represents a ram configuration for a Dk'Tronics/Dobbertin/Amstrad compatible RAM expansion, or the built in RAM expansion of the CPC6128 and CPC6128+. Bits 5..0 define the ram expansion code. For CPCEMU compatibility, bit 7 and bit 6 of this byte should be set to "0".
		14. This byte in the snapshot represents the index of the currently selected CRTC register. For compatibility with CPCEMU this value should be in the range 0-31.
		15. These bytes represent the data of the CRTC's registers.
		16. This byte in the snapshot represents the last byte written to the "ROM select" I/O port.
		17. This byte in the snapshot represents the index of the currently selected PSG register. For CPCEMU compatibility, this byte should be in the range 0-15.
		18. the first 64k is always the base 64k of ram. The second 64k (if present) is the additional ram in a Dk'Tronics/Dobbertin/Amstrad compatible RAM expansion or the internal ram of the CPC6128/CPC6128+. The memory dump is not dependant on the current RAM configuration. Note that CPCEMU can only write a 64K or 128K snapshot.

	6d		CPC type:
	6e		interrupt number (0..5) (note 1a)
	6f-74	(6) 6 multimode bytes (note 1b)

	75-9B   (27) ??

	9C		FDD motor drive state (0=off, 1=on)
	9D-A0	(4)	FDD current physical track (note 15)
	A1		Printer Data/Strobe Register (note 1)
	A2-A3   (2) ??
	A4		1	CRTC type:
			0 = HD6845S_UM6845
			1 = UM6845R
			2 = MC6845
			3 = MC6845_CPC_ASIC
			4 = MC6845_PRE_ASIC
	A5-A8	(4) ??
	A9		CRTC horizontal character counter register (note 11)
	AA		(1)	unused
	AB		CRTC character-line counter register (note 2)
	AC		CRTC raster-line counter register (note 3)
	AD		CRTC vertical total adjust counter register (note 4)
	AE		CRTC horizontal sync width counter (note 5)
	AF		CRTC vertical sync width counter (note 6)
	B0-B1	(2)
			CRTC state flags. (note 7)
			Bit	Function
			0	if "1" VSYNC is active, if "0" VSYNC is inactive (note 8)
			1	if "1" HSYNC is active, if "0" HSYNC is inactive (note 9)
			2-7	reserved
			7	if "1" Vertical Total Adjust is active, if "0" Vertical Total Adjust is inactive (note 10)
			8-15	Reserved (0)
	B2		GA vsync delay counter (note 14)
	B3		GA interrupt scanline counter (note 12)
	B4		interrupt request flag (0=no interrupt requested, 1=interrupt requested) (note 13)
	B5-FF	(75) unused

	100-...	(defined by memory dump size)	memory dump

	Notes:
		1. This byte in the snapshot represents the last byte written to the printer I/O port (this byte does not include the automatic inversion of the strobe caused by the Amstrad hardware).
		2. This register is internal to the CRTC and counts the number of character-lines. The counter counts up. This value is in the range 0-127. (This counter is compared against CRTC register 4).
		3. This register is internal to the CRTC and counts the number of raster-lines. The counter counts up. This value is in the range 0-31. (This counter is compared against CRTC register 9).
		4. This register is internal to the CRTC and counts the number of raster-lines during vertical adjust. The counter counts up. This value is in the range 0-31. This should be ignored if the CRTC is not "executing" vertical. adjust.(This counter is compared against CRTC register 5).
		5. This register is internal to the CRTC and counts the number of characters during horizontal sync. This counter counts up. This value is in the range 0-16. This should be ignored if the CRTC is not "executing" horizontal sync. (This counter is compared against CRTC register 3).
		6. This register is internal to the CRTC and counts the number of scan-lines during vertical sync. This counter counts up. This value is in the range 0-16. This should be ignored if the CRTC is not "executing" vertical sync. (This counter is compared against CRTC register 3).
		7. These bytes define the internal state of the CRTC. Each bit in these bytes represents a state.
		8. When VSYNC is active, the CRTC is "executing" vertical sync, and the vertical sync width counter in the snapshot is used.
		9. When HSYNC is active, the CRTC is "executing" horizontal sync width counter in the snapshot is used.
		10. When Vertical total adjust is active, the CRTC is "executing" vertical total adjust and the vertical total adjust counter in the snapshot is used.
		11. This register is internal to the CRTC and counts the number of characters. This counter counts up. This value is in the range 0-255. (This counter is compared against CRTC register 0).
		12. This counter is internal to the GA and counts the number of HSYNCs. This counter is used to generate CPC raster interrupts. This counter counts up. This value is in the range 0-51.
		13. This flag is "1" if a interrupt request has been sent to the Z80 and it has not yet been acknowledged by the Z80. (A interrupt request is sent by the GA for standard CPC raster interrupts or by the ASIC for raster or dma interrupts).
		14. This is a counter internal to the GA and counts the number of HSYNCs since the start of the VSYNC and it is used to reset the interrupt counter to synchronise interrupts with the VSYNC. This counter counts up. This value is between 0 and 2. If this value is 0, the counter is inactive. If this counter is 1 or 2 the counter is active.
	*/
}
psnapshot :: ^snapshot

load_snapshot :: proc(path: string, pss: psnapshot, ram: []u8) -> os.Errno {
	err: os.Errno
	fd: os.Handle
	fd, err = os.open(path)
	if err != 0 {return err}
	defer os.close(fd)

	buf: [256]u8
	total_read: int
	total_read, err = os.read(fd, buf[:])
	if err != 0 {return err}
	assert(total_read == 0x100)
	pss^ = psnapshot(&buf[0])^

	total_read, err = os.read(fd, ram)
	assert(total_read == 0x10000)
	return err
}

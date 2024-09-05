package test_amstrad

import am ".."
import "core:encoding/json"
import "core:fmt"
import "core:os"
import fp "core:path/filepath"
import "core:strings"
import "core:testing"
import o "shared:ounit"
import z80 "shared:z80"
//import z80m "shared:z80/amstrad"
//import "shared:ascii"

// expect_value :: proc(t: ^testing.T, act: u8, exp: u8, loc := #caller_location) {
// 	testing.expectf(t, act == exp, "0b%8b (should be: 0b%8b)", act, exp, loc = loc)
// }

expect_value :: testing.expect_value

@(test)
size_up :: proc(t: ^testing.T) {
	exp := 52
	testing.expectf(t, size_of(am.disc_information_block) == exp, "exp %d was %d", exp, size_of(am.disc_information_block))
	exp = 24
	testing.expectf(t, size_of(am.track_information_block) == exp, "exp %d was %d", exp, size_of(am.track_information_block))
	exp = 8
	testing.expectf(t, size_of(am.registers) == exp, "exp %d was %d", exp, size_of(am.registers))
	exp = 153
	testing.expectf(t, size_of(am.snapshot) == exp, "exp %d was %d", exp, size_of(am.snapshot))
}

//@(test)
load_disk_image :: proc(t: ^testing.T) {
	path := fp.clean("../examples/amstrad/data/pinup.dsk", context.temp_allocator)
	fmt.printfln("reading %s", path)
	fd, err := os.open(path)
	testing.expect(t, err == 0)
	if err != 0 {return}
	defer os.close(fd)

	pbuf :: ^[size_of(am.disc_information_block)]u8
	dib: am.disc_information_block
	os.read(fd, pbuf(&dib)[:])

	// fmt.printf("id: %s", pdib.id)
	fmt.printfln("name_of_creator: \"%s\"", dib.name_of_creator)
	fmt.printfln("number_of_tracks: %d", dib.number_of_tracks)
	fmt.printfln("number_of_sides: %d", dib.number_of_sides)

	testing.expect(t, dib.id == am.disk_image_id)
	testing.expect(t, dib.number_of_tracks == 40)
	testing.expect(t, dib.number_of_sides == 1)

	total_tracks := dib.number_of_tracks * dib.number_of_sides
	testing.expect(t, total_tracks == 40)

	track_size_table := make([]u8, total_tracks, context.temp_allocator)
	os.read(fd, track_size_table[:])
	//fmt.printfln("track_size_table: %#v", track_size_table)
	fmt.print("track_size_table:")
	for i in track_size_table {fmt.printf(" %d", u32(i) * 256)}
	fmt.println()

	/*
	Actual length of track data = (high byte of track length) * 256

	Track length includes the size of the TRACK INFORMATION BLOCK (256 bytes)

	The location of a Track Information Block for a chosen track is found by summing the sizes of all tracks
	up to the chosen track plus the size of the Disc Information Block (&100 bytes).
	The first track is at offset &100 in the disc image.
	*/

	track_table := make([]am.track_information_block, total_tracks, context.temp_allocator)
	ptbuf :: ^[size_of(am.track_information_block)]u8

	buf: [256]u8

	tp: i64 = 256
	os.seek(fd, tp, 0)

	for i in 0 ..< total_tracks {
		fmt.printfln("track %d:", i)
		length_of_track_data := u32(track_size_table[i]) * 256
		fmt.printfln("  length_of_track_data %d:", length_of_track_data)

		os.seek(fd, tp, 0)
		//os.read(fd, ptbuf(ptib)[:])
		os.read(fd, buf[:])
		ptib := am.p_track_information_block(&buf)

		//ptib:= &track_table[i]
		track_table[i] = ptib^

		fmt.printf("  id: \"%s\"", ptib.id)
		fmt.printf(" track_number: %d", ptib.track_number)
		fmt.printf(" side_number: %d", ptib.side_number)
		fmt.printf(" sector_size: %d", ptib.sector_size)
		fmt.printf(" number_of_sectors: %d", ptib.number_of_sectors)
		fmt.printf(" gap_3_length: %d", ptib.gap_3_length)
		fmt.printf(" filler_byte: %d", ptib.filler_byte)
		fmt.println()

		testing.expect(t, ptib.id == am.track_information_block_id)

		tp += i64(length_of_track_data)
	}

}

@(test)
load_snapshot :: proc(t: ^testing.T) {
	path := fp.clean("../../../examples/amstrad/data/pinup.sna", context.temp_allocator)
	fmt.printfln("reading %s", path)

	ss: am.snapshot
	ram: z80.bank64kb
	err := am.load_snapshot(path, &ss, ram[:])
	assert(err == 0)
	ps := &ss

	{
		json_path :: "snapshot.json"

		builder := strings.builder_make()
		defer strings.builder_destroy(&builder)

		mo: json.Marshal_Options = {
			pretty         = true,
			use_enum_names = true,
		}
		err := json.marshal_to_builder(&builder, ss, &mo)
		assert(err == json.Marshal_Data_Error.None)
		if len(builder.buf) != 0 {
			json_data := builder.buf[:]
			fmt.printfln("%s", json_data)
			fmt.printfln("Writing: %s", json_path)
			ok := os.write_entire_file(json_path, json_data)
			if !ok {fmt.eprintln("Unable to write file")}
		}
	}

	//ps := am.psnapshot(&buf[0])
	expect_value(t, string(ps.id[:]), am.snapshot_id)
	expect_value(t, ps.version, 3)
	// o.expect_value(t, ps.R, 0x32)
	expect_value(t, ps.I, 0)
	expect_value(t, ps.IFF0, 1)
	expect_value(t, ps.IFF1, 1)
	// o.expect_value(t, ps.IX, 0xBFFE)
	// o.expect_value(t, ps.IY, 0x0000)
	// o.expect_value(t, ps.SP, 0xBFE2)
	// o.expect_value(t, ps.PC, 0x1CE3)
	o.expect_value(t, ps.interrupt_mode, 1)
	o.expect_value(t, ps.memory_dump_size, 64)
	o.expect_value(t, ps.cpc_type, 2)
	o.expect_value(t, ps.pen, 15)
	//o.expect_value(t, ps.multi_conf, 0x89)
	o.expect_value(t, ps.ram_conf, 0)
	o.expect_value(t, ps.crtc_sel, 13)
	o.expect_value(t, ps.current_rom, 0)
	o.expect_value(t, ps.PPI_ctrl, 0x82)

	fmt.printfln("id:               \"%s\"", ps.id)
	fmt.printfln("version:          % 5d", ps.version)
	fmt.printfln("regs:             %v", ps.regs)
	fmt.printfln("R:                % 5d", ps.R)
	fmt.printfln("I:                % 5d", ps.I)
	fmt.printfln("IFF0:             % 5d", ps.IFF0)
	fmt.printfln("IFF1:             % 5d", ps.IFF1)
	fmt.printfln("IX:               0x%4X", ps.IX)
	fmt.printfln("IY:               0x%4X", ps.IY)
	fmt.printfln("SP:               0x%4X", ps.SP)
	fmt.printfln("PC:               0x%4X", ps.PC)
	fmt.printfln("int _mode:        % 5d", ps.interrupt_mode)
	fmt.printfln("alt_regs:         %v", ps.regs)
	fmt.printfln("pen:              % 5d", ps.pen)
	fmt.printfln("palette:          %v", ps.palette)
	fmt.printfln("multi_conf(12):   0b%8b", ps.multi_conf)
	fmt.printfln("ram_conf(13):     0b%8b", ps.ram_conf)
	fmt.printfln("crtc_sel(14):     % 5d", ps.crtc_sel)
	fmt.printfln("crtc_data(15):    %v", ps.crtc_data)
	fmt.printfln("crtc_sel(16):     % 5d", ps.current_rom)
	fmt.printfln("memory_dump_size: % 5d", ps.memory_dump_size)
	fmt.printfln("cpc_type:         %v (%d)", ps.cpc_type, ps.cpc_type)
	fmt.printfln("interrupt_number: % 5d", ps.interrupt_number)
	fmt.printfln("multimode_bytes:  %v", ps.multimode_bytes)
	fmt.printfln("fdd m.d.s.:       % 5d", ps.fdd_motor_drive_state)
	fmt.printfln("fdd c.p.t.:       %v", ps.fdd_current_physical_track)
	fmt.printfln("printer_data:     % 5d", ps.printer_data)
	fmt.printfln("crtc_type:        %v", ps.crtc_type)

	// fmt.printfln("version:          % 5d", buf[0x10])
	// fmt.printfln("memory_dump_size: % 5d", buf[0x6B])
	// fmt.printfln("memory_dump_size: % 5d", buf[0x6C])
	// fmt.printfln("cpc_type:         % 5d", buf[0x6D])
	// fmt.printfln("int _mode:        % 5d", buf[0x25])
	// fmt.printfln("pen:              % 5d", buf[0x2E])
	// fmt.printfln("ram_conf:         0b%8b", buf[0x41])

	// o._expect_value(t, ps.version, buf[0x10])
	// o._expect_value(t, ps.R, buf[0x19])
	// o._expect_value(t, ps.I, buf[0x1A])
	// o._expect_value(t, ps.IFF0, buf[0x1B])
	// o._expect_value(t, ps.IFF1, buf[0x1C])
	// o.expect_value(t, ps.interrupt_mode, buf[0x25])

	//ram: z80.bank64kb
	//os.read(fd, ram[:])

	os.write_entire_file("snapshot_ram_dump.dat", ram[:])
}

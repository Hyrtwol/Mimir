# Odin

First go at Odin.

## Odin command line tool

odin is a tool for managing Odin source code

### Commands

```txt
Usage:
	odin command [arguments]
Commands:
	build             compile directory of .odin files, as an executable.
	                  one must contain the program's entry point, all must be in the same package.
	run               same as 'build', but also then runs the newly compiled executable.
	check             parse, and type check a directory of .odin files
	strip-semicolon   parse, type check, and remove unneeded semicolons from the entire program
	test              build and runs procedures with the attribute @(test) in the initial package
	doc               generate documentation on a directory of .odin files
	version           print version
	report            print information useful to reporting a bug
```

### Build

```txt
Usage:
	odin build [arguments]

	build   Compile directory of .odin files as an executable.
		One must contain the program's entry point, all must be in the same package.
		Use `-file` to build a single file instead.
		Examples:
			odin build .                    # Build package in current directory
			odin build <dir>                # Build package in <dir>
			odin build filename.odin -file  # Build single-file package, must contain entry point.

	Flags

	-file
		Tells `odin build` to treat the given file as a self-contained package.
		This means that `<dir>/a.odin` won't have access to `<dir>/b.odin`'s contents.

	-out:<filepath>
		Set the file name of the outputted executable
		Example: -out:foo.exe

	-o:<string>
		Set the optimization mode for compilation
		Accepted values: minimal, size, speed, none
		Example: -o:speed

	-show-timings
		Shows basic overview of the timings of different stages within the compiler in milliseconds

	-show-more-timings
		Shows an advanced overview of the timings of different stages within the compiler in milliseconds

	-export-timings:<format>
		Export timings to one of a few formats. Requires `-show-timings` or `-show-more-timings`
		Available options:
			-export-timings:json        Export compile time stats to JSON
			-export-timings:csv         Export compile time stats to CSV

	-export-timings-file:<filename>
		Specify the filename for `-export-timings`
		Example: -export-timings-file:timings.json

	-thread-count:<integer>
		Override the number of threads the compiler will use to compile with
		Example: -thread-count:2

	-keep-temp-files
		Keeps the temporary files generated during compilation

	-collection:<name>=<filepath>
		Defines a library collection used for imports
		Example: -collection:shared=dir/to/shared
		Usage in Code:
			import "shared:foo"

	-define:<name>=<value>
		Defines a scalar boolean, integer or string as global constant
		Example: -define:SPAM=123
		To use:  #config(SPAM, default_value)

	-build-mode:<mode>
		Sets the build mode
		Available options:
			-build-mode:exe       Build as an executable
			-build-mode:dll       Build as a dynamically linked library
			-build-mode:shared    Build as a dynamically linked library
			-build-mode:obj       Build as an object file
			-build-mode:object    Build as an object file
			-build-mode:assembly  Build as an assembly file
			-build-mode:assembler Build as an assembly file
			-build-mode:asm       Build as an assembly file
			-build-mode:llvm-ir   Build as an LLVM IR file
			-build-mode:llvm      Build as an LLVM IR file

	-target:<string>
		Sets the target for the executable to be built in

	-debug
		Enabled debug information, and defines the global constant ODIN_DEBUG to be 'true'

	-disable-assert
		Disable the code generation of the built-in run-time 'assert' procedure, and defines the global constant ODIN_DISABLE_ASSERT to be 'true'

	-no-bounds-check
		Disables bounds checking program wide

	-no-crt
		Disables automatic linking with the C Run Time

	-no-thread-local
		Ignore @thread_local attribute, effectively treating the program as if it is single-threaded

	-lld
		Use the LLD linker rather than the default

	-use-separate-modules
	[EXPERIMENTAL]
		The backend generates multiple build units which are then linked together
		Normally, a single build unit is generated for a standard project

	-no-threaded-checker
		Disabled multithreading in the semantic checker stage

	-vet
		Do extra checks on the code
		Extra checks include:
			Variable shadowing within procedures
			Unused declarations

	-vet-extra
		Do even more checks than standard vet on the code
		To treat the extra warnings as errors, use -warnings-as-errors

	-ignore-unknown-attributes
		Ignores unknown attributes
		This can be used with metaprogramming tools

	-no-entry-point
		Removes default requirement of an entry point (e.g. main procedure)

	-minimum-os-version:<string>
		Sets the minimum OS version targeted by the application
		e.g. -minimum-os-version:12.0.0
		(Only used when target is Darwin)

	-extra-linker-flags:<string>
		Adds extra linker specific flags in a string

	-extra-assembler-flags:<string>
		Adds extra assembler specific flags in a string

	-microarch:<string>
		Specifies the specific micro-architecture for the build in a string
		Examples:
			-microarch:sandybridge
			-microarch:native

	-reloc-mode:<string>
		Specifies the reloc mode
		Options:
			default
			static
			pic
			dynamic-no-pic

	-disable-red-zone
		Disable red zone on a supported freestanding target

	-dynamic-map-calls
		Use dynamic map calls to minimize code generation at the cost of runtime execution

	-disallow-do
		Disallows the 'do' keyword in the project

	-default-to-nil-allocator
		Sets the default allocator to be the nil_allocator, an allocator which does nothing

	-strict-style
		Errs on unneeded tokens, such as unneeded semicolons

	-strict-style-init-only
		Errs on unneeded tokens, such as unneeded semicolons, only on the initial project

	-ignore-warnings
		Ignores warning messages

	-warnings-as-errors
		Treats warning messages as error messages

	-terse-errors
		Prints a terse error message without showing the code on that line and the location in that line

	-error-pos-style:<string>
		Options are 'unix', 'odin' and 'default' (odin)
		'odin'    file/path(45:3)
		'unix'    file/path:45:3:

	-max-error-count:<integer>
		Set the maximum number of errors that can be displayed before the compiler terminates
		Must be an integer >0
		If not set, the default max error count is 36

	-foreign-error-procedures
		States that the error procedures used in the runtime are defined in a separate translation unit

	-ignore-vs-search
		[Windows only]
		Ignores the Visual Studio search for library paths

	-resource:<filepath>
		[Windows only]
		Defines the resource file for the executable
		Example: -resource:path/to/file.rc

	-pdb-name:<filepath>
		[Windows only]
		Defines the generated PDB name when -debug is enabled
		Example: -pdb-name:different.pdb

	-subsystem:<option>
		[Windows only]
		Defines the subsystem for the application
		Available options:
			console
			windows
```

## VSCode setup

* <https://code.visualstudio.com/docs/editor/variables-reference>

## Notes

C:\Program Files\Microsoft Visual Studio\2022\Community\SDK\ScopeCppSDK\vc15\SDK\include\um
C:\Program Files\Microsoft Visual Studio\2022\Community\SDK\ScopeCppSDK\vc15\SDK\include\um\WinUser.h
C:\Program Files\Microsoft Visual Studio\2022\Community\SDK\ScopeCppSDK\vc15\SDK\include\um\mmeapi.h

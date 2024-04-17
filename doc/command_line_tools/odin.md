# Odin

odin version dev-2024-04:37084a82e

## Commands

```txt
odin is a tool for managing Odin source code.
Usage:
	odin command [arguments]
Commands:
	build             Compiles directory of .odin files, as an executable.
	                  One must contain the program's entry point, all must be in the same package.
	run               Same as 'build', but also then runs the newly compiled executable.
	check             Parses, and type checks a directory of .odin files.
	strip-semicolon   Parses, type checks, and removes unneeded semicolons from the entire program.
	test              Builds and runs procedures with the attribute @(test) in the initial package.
	doc               Generates documentation on a directory of .odin files.
	version           Prints version.
	report            Prints information useful to reporting a bug.
	root              Prints the root path where Odin looks for the builtin collections.

For further details on a command, invoke command help:
	e.g. `odin build -help` or `odin help build`
```

## Build

```txt
odin is a tool for managing Odin source code.
Usage:
	odin build [arguments]

	build   Compiles directory of .odin files as an executable.
		One must contain the program's entry point, all must be in the same package.
		Use `-file` to build a single file instead.
		Examples:
			odin build .                     Builds package in current directory.
			odin build <dir>                 Builds package in <dir>.
			odin build filename.odin -file   Builds single-file package, must contain entry point.

	Flags

	-file
		Tells `odin build` to treat the given file as a self-contained package.
		This means that `<dir>/a.odin` won't have access to `<dir>/b.odin`'s contents.

	-out:<filepath>
		Sets the file name of the outputted executable.
		Example: -out:foo.exe

	-o:<string>
		Sets the optimization mode for compilation.
		Available options:
			-o:none
			-o:minimal
			-o:size
			-o:speed
			-o:aggressive
		The default is -o:minimal.

	-show-timings
		Shows basic overview of the timings of different stages within the compiler in milliseconds.

	-show-more-timings
		Shows an advanced overview of the timings of different stages within the compiler in milliseconds.

	-show-system-calls
		Prints the whole command and arguments for calls to external tools like linker and assembler.

	-export-timings:<format>
		Exports timings to one of a few formats. Requires `-show-timings` or `-show-more-timings`.
		Available options:
			-export-timings:json   Exports compile time stats to JSON.
			-export-timings:csv    Exports compile time stats to CSV.

	-export-timings-file:<filename>
		Specifies the filename for `-export-timings`.
		Example: -export-timings-file:timings.json

	-thread-count:<integer>
		Overrides the number of threads the compiler will use to compile with.
		Example: -thread-count:2

	-keep-temp-files
		Keeps the temporary files generated during compilation.

	-collection:<name>=<filepath>
		Defines a library collection used for imports.
		Example: -collection:shared=dir/to/shared
		Usage in Code:
			import "shared:foo"

	-define:<name>=<value>
		Defines a scalar boolean, integer or string as global constant.
		Example: -define:SPAM=123
		Usage in code:
			#config(SPAM, default_value)

	-build-mode:<mode>
		Sets the build mode.
		Available options:
			-build-mode:exe         Builds as an executable.
			-build-mode:dll         Builds as a dynamically linked library.
			-build-mode:shared      Builds as a dynamically linked library.
			-build-mode:obj         Builds as an object file.
			-build-mode:object      Builds as an object file.
			-build-mode:assembly    Builds as an assembly file.
			-build-mode:assembler   Builds as an assembly file.
			-build-mode:asm         Builds as an assembly file.
			-build-mode:llvm-ir     Builds as an LLVM IR file.
			-build-mode:llvm        Builds as an LLVM IR file.

	-target:<string>
		Sets the target for the executable to be built in.

	-debug
		Enables debug information, and defines the global constant ODIN_DEBUG to be 'true'.

	-disable-assert
		Disables the code generation of the built-in run-time 'assert' procedure, and defines the global constant ODIN_DISABLE_ASSERT to be 'true'.

	-no-bounds-check
		Disables bounds checking program wide.

	-no-crt
		Disables automatic linking with the C Run Time.

	-no-thread-local
		Ignores @thread_local attribute, effectively treating the program as if it is single-threaded.

	-lld
		Uses the LLD linker rather than the default.

	-use-separate-modules
	[EXPERIMENTAL]
		The backend generates multiple build units which are then linked together.
		Normally, a single build unit is generated for a standard project.

	-no-threaded-checker
		Disables multithreading in the semantic checker stage.

	-vet
		Does extra checks on the code.
		Extra checks include:
			-vet-unused
			-vet-unused-variables
			-vet-unused-imports
			-vet-shadowing
			-vet-using-stmt

	-vet-unused
		Checks for unused declarations.

	-vet-unused-variables
		Checks for unused variable declarations.

	-vet-unused-imports
		Checks for unused import declarations.

	-vet-shadowing
		Checks for variable shadowing within procedures.

	-vet-using-stmt
		Checks for the use of 'using' as a statement.
		'using' is considered bad practice outside of immediate refactoring.

	-vet-using-param
		Checks for the use of 'using' on procedure parameters.
		'using' is considered bad practice outside of immediate refactoring.

	-vet-style
		Errs on missing trailing commas followed by a newline.
		Errs on deprecated syntax.
		Does not err on unneeded tokens (unlike -strict-style).

	-vet-semicolon
		Errs on unneeded semicolons.

	-ignore-unknown-attributes
		Ignores unknown attributes.
		This can be used with metaprogramming tools.

	-no-entry-point
		Removes default requirement of an entry point (e.g. main procedure).

	-minimum-os-version:<string>
		Sets the minimum OS version targeted by the application.
		Default: -minimum-os-version:11.0.0
		Only used when target is Darwin, if given, linking mismatched versions will emit a warning.

	-extra-linker-flags:<string>
		Adds extra linker specific flags in a string.

	-extra-assembler-flags:<string>
		Adds extra assembler specific flags in a string.

	-microarch:<string>
		Specifies the specific micro-architecture for the build in a string.
		Examples:
			-microarch:sandybridge
			-microarch:native
			-microarch:? for a list

	-reloc-mode:<string>
		Specifies the reloc mode.
		Available options:
			-reloc-mode:default
			-reloc-mode:static
			-reloc-mode:pic
			-reloc-mode:dynamic-no-pic

	-disable-red-zone
		Disables red zone on a supported freestanding target.

	-dynamic-map-calls
		Uses dynamic map calls to minimize code generation at the cost of runtime execution.

	-disallow-do
		Disallows the 'do' keyword in the project.

	-default-to-nil-allocator
		Sets the default allocator to be the nil_allocator, an allocator which does nothing.

	-strict-style
		Errs on unneeded tokens, such as unneeded semicolons.
		Errs on missing trailing commas followed by a newline.
		Errs on deprecated syntax.

	-ignore-warnings
		Ignores warning messages.

	-warnings-as-errors
		Treats warning messages as error messages.

	-terse-errors
		Prints a terse error message without showing the code on that line and the location in that line.

	-json-errors
		Prints the error messages as json to stderr.

	-error-pos-style:<string>
		Available options:
			-error-pos-style:unix      file/path:45:3:
			-error-pos-style:odin      file/path(45:3)
			-error-pos-style:default   (Defaults to 'odin'.)

	-max-error-count:<integer>
		Sets the maximum number of errors that can be displayed before the compiler terminates.
		Must be an integer >0.
		If not set, the default max error count is 36.

	-min-link-libs
		If set, the number of linked libraries will be minimized to prevent duplications.
		This is useful for so called "dumb" linkers compared to "smart" linkers.

	-foreign-error-procedures
		States that the error procedures used in the runtime are defined in a separate translation unit.

	-obfuscate-source-code-locations
		Obfuscate the file and procedure strings, and line and column numbers, stored with a 'runtime.Source_Code_Location' value.

	-sanitize:<string>
		Enables sanitization analysis.
		Available options:
			-sanitize:address
			-sanitize:memory
			-sanitize:thread
		NOTE: This flag can be used multiple times.

	-ignore-vs-search
		[Windows only]
		Ignores the Visual Studio search for library paths.

	-resource:<filepath>
		[Windows only]
		Defines the resource file for the executable.
		Example: -resource:path/to/file.rc

	-pdb-name:<filepath>
		[Windows only]
		Defines the generated PDB name when -debug is enabled.
		Example: -pdb-name:different.pdb

	-subsystem:<option>
		[Windows only]
		Defines the subsystem for the application.
		Available options:
			-subsystem:console
			-subsystem:windows

```

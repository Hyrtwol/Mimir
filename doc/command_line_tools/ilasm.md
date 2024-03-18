# ilasm

```txt

.NET IL Assembler version 8.0.0
Copyright (c) Microsoft Corporation.  All rights reserved.



Usage: ilasm [Options] <sourcefile> [Options]

Options:
/NOLOGO         Don't type the logo
/QUIET          Don't report assembly progress
/NOAUTOINHERIT  Disable inheriting from System.Object by default
/DLL            Compile to .dll
/EXE            Compile to .exe (default)
/PDB            Create the PDB file without enabling debug info tracking
/APPCONTAINER   Create an AppContainer exe or dll
/DEBUG          Disable JIT optimization, create PDB file, use sequence points from PDB
/DEBUG=IMPL     Disable JIT optimization, create PDB file, use implicit sequence points
/DEBUG=OPT      Enable JIT optimization, create PDB file, use implicit sequence points
/OPTIMIZE       Optimize long instructions to short
/FOLD           Fold the identical method bodies into one
/CLOCK          Measure and report compilation times
/OUTPUT=<targetfile>    Compile to file with specified name 
			(user must provide extension, if any)
/KEY=<keyfile>      Compile with strong signature 
			(<keyfile> contains private key)
/KEY=@<keysource>   Compile with strong signature 
			(<keysource> is the private key source name)
/INCLUDE=<path>     Set path to search for #include'd files
/SUBSYSTEM=<int>    Set Subsystem value in the NT Optional header
/SSVER=<int>.<int>  Set Subsystem version number in the NT Optional header
/FLAGS=<int>        Set CLR ImageFlags value in the CLR header
/ALIGNMENT=<int>    Set FileAlignment value in the NT Optional header
/BASE=<int>     Set ImageBase value in the NT Optional header (max 2GB for 32-bit images)
/STACK=<int>    Set SizeOfStackReserve value in the NT Optional header
/MDV=<version_string>   Set Metadata version string
/MSV=<int>.<int>   Set Metadata stream version (<major>.<minor>)
/PE64           Create a 64bit image (PE32+)
/HIGHENTROPYVA  Set High Entropy Virtual Address capable PE32+ images (default for /APPCONTAINER)
/NOCORSTUB      Suppress generation of CORExeMain stub
/STRIPRELOC     Indicate that no base relocations are needed
/X64            Target processor: 64bit AMD processor
/ARM            Target processor: ARM (AArch32) processor
/ARM64          Target processor: ARM64 (AArch64) processor
/32BITPREFERRED Create a 32BitPreferred image (PE32)

Key may be '-' or '/'
Options are recognized by first 3 characters (except ARM/ARM64)
Default source file extension is .il

Target defaults:
/PE64      => /PE64 /X64
/X64       => /PE64 /X64
/ARM64     => /PE64 /ARM64

```


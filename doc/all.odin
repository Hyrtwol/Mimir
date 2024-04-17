package all

// Imports every package
// This is useful for knowing what exists and producing documentation with `odin doc`

import coreclr         "shared:coreclr"
import flac            "shared:flac"
import fmodex          "shared:fmodex"
import lightwave       "shared:newtek_lightwave"
import newton_dynamics "shared:newton_dynamics"
import ounit           "shared:ounit"
import wasmtime        "shared:wasmtime"
import xatlas          "shared:xatlas"
import xterm           "shared:xterm"
import z80             "shared:z80"

import canvas          "libs:tlc/canvas"
import csharp          "libs:csharp"
//import fft             "libs:fft"
import win32app        "libs:tlc/win32app"

main :: proc(){}

_ :: csharp

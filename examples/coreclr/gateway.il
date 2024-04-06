
//  .NET IL Disassembler.  Version 8.0.0



// Metadata version: v4.0.30319
.assembly extern System.Runtime
{
  .publickeytoken = (B0 3F 5F 7F 11 D5 0A 3A )                         // .?_....:
  .ver 8:0:0:0
}
.assembly extern System.Linq
{
  .publickeytoken = (B0 3F 5F 7F 11 D5 0A 3A )                         // .?_....:
  .ver 8:0:0:0
}
.assembly extern System.Console
{
  .publickeytoken = (B0 3F 5F 7F 11 D5 0A 3A )                         // .?_....:
  .ver 8:0:0:0
}
.assembly gateway
{
  .custom instance void [System.Runtime]System.Runtime.CompilerServices.CompilationRelaxationsAttribute::.ctor(int32) = ( 01 00 08 00 00 00 00 00 ) 
  .custom instance void [System.Runtime]System.Runtime.CompilerServices.RuntimeCompatibilityAttribute::.ctor() = ( 01 00 01 00 54 02 16 57 72 61 70 4E 6F 6E 45 78   // ....T..WrapNonEx
                                                                                                                   63 65 70 74 69 6F 6E 54 68 72 6F 77 73 01 )       // ceptionThrows.

  // --- The following custom attribute is added automatically, do not uncomment -------
  //  .custom instance void [System.Runtime]System.Diagnostics.DebuggableAttribute::.ctor(valuetype [System.Runtime]System.Diagnostics.DebuggableAttribute/DebuggingModes) = ( 01 00 07 01 00 00 00 00 ) 

  .custom instance void [System.Runtime]System.Runtime.Versioning.TargetFrameworkAttribute::.ctor(string) = ( 01 00 18 2E 4E 45 54 43 6F 72 65 41 70 70 2C 56   // ....NETCoreApp,V
                                                                                                              65 72 73 69 6F 6E 3D 76 38 2E 30 01 00 54 0E 14   // ersion=v8.0..T..
                                                                                                              46 72 61 6D 65 77 6F 72 6B 44 69 73 70 6C 61 79   // FrameworkDisplay
                                                                                                              4E 61 6D 65 08 2E 4E 45 54 20 38 2E 30 )          // Name..NET 8.0
  .custom instance void [System.Runtime]System.Reflection.AssemblyCompanyAttribute::.ctor(string) = ( 01 00 07 67 61 74 65 77 61 79 00 00 )             // ...gateway..
  .custom instance void [System.Runtime]System.Reflection.AssemblyConfigurationAttribute::.ctor(string) = ( 01 00 05 44 65 62 75 67 00 00 )                   // ...Debug..
  .custom instance void [System.Runtime]System.Reflection.AssemblyFileVersionAttribute::.ctor(string) = ( 01 00 07 31 2E 30 2E 30 2E 30 00 00 )             // ...1.0.0.0..
  .custom instance void [System.Runtime]System.Reflection.AssemblyInformationalVersionAttribute::.ctor(string) = ( 01 00 2E 31 2E 30 2E 30 2B 34 62 65 64 35 35 33   // ...1.0.0+4bed553
                                                                                                                   38 35 65 39 61 32 30 35 66 35 66 32 61 39 32 37   // 85e9a205f5f2a927
                                                                                                                   35 32 37 39 36 64 62 39 66 37 33 32 38 61 30 32   // 52796db9f7328a02
                                                                                                                   65 00 00 )                                        // e..
  .custom instance void [System.Runtime]System.Reflection.AssemblyProductAttribute::.ctor(string) = ( 01 00 07 67 61 74 65 77 61 79 00 00 )             // ...gateway..
  .custom instance void [System.Runtime]System.Reflection.AssemblyTitleAttribute::.ctor(string) = ( 01 00 07 67 61 74 65 77 61 79 00 00 )             // ...gateway..
  .permissionset reqmin
             = {[System.Runtime]System.Security.Permissions.SecurityPermissionAttribute = {property bool 'SkipVerification' = bool(true)}}
  .hash algorithm 0x00008004
  .ver 1:0:0:0
}
.module gateway.dll
// MVID: {8f232ceb-33bb-4658-9777-c1e599a76d17}
.custom instance void [System.Runtime]System.Security.UnverifiableCodeAttribute::.ctor() = ( 01 00 00 00 ) 
.custom instance void [System.Runtime]System.Runtime.CompilerServices.RefSafetyRulesAttribute::.ctor(int32) = ( 01 00 0B 00 00 00 00 00 ) 
.imagebase 0x10000000
.file alignment 0x00000200
.stackreserve 0x00100000
.subsystem 0x0003       // WINDOWS_CUI
.corflags 0x00000001    //  ILONLY
// Image base: 0x000001E120D70000


// =============== CLASS MEMBERS DECLARATION ===================

.class public auto ansi sealed UnmanagedCallbackDelegate
       extends [System.Runtime]System.MulticastDelegate
{
  .method public hidebysig specialname rtspecialname 
          instance void  .ctor(object 'object',
                               native int 'method') runtime managed
  {
  } // end of method UnmanagedCallbackDelegate::.ctor

  .method public hidebysig newslot virtual 
          instance bool  Invoke(string funcName,
                                string jsonArgs) runtime managed
  {
  } // end of method UnmanagedCallbackDelegate::Invoke

  .method public hidebysig newslot virtual 
          instance class [System.Runtime]System.IAsyncResult 
          BeginInvoke(string funcName,
                      string jsonArgs,
                      class [System.Runtime]System.AsyncCallback callback,
                      object 'object') runtime managed
  {
  } // end of method UnmanagedCallbackDelegate::BeginInvoke

  .method public hidebysig newslot virtual 
          instance bool  EndInvoke(class [System.Runtime]System.IAsyncResult result) runtime managed
  {
  } // end of method UnmanagedCallbackDelegate::EndInvoke

} // end of class UnmanagedCallbackDelegate

.class public abstract auto ansi sealed beforefieldinit Gateway
       extends [System.Runtime]System.Object
{
  .method public hidebysig static string 
          Bootstrap() cil managed
  {
    // Code size       11 (0xb)
    .maxstack  1
    .locals init (string V_0)
    IL_0000:  nop
    IL_0001:  ldstr      "Bootstrap!"
    IL_0006:  stloc.0
    IL_0007:  br.s       IL_0009

    IL_0009:  ldloc.0
    IL_000a:  ret
  } // end of method Gateway::Bootstrap

  .method public hidebysig static float64 
          Plus(float64 x,
               float64 y) cil managed
  {
    // Code size       9 (0x9)
    .maxstack  2
    .locals init (float64 V_0)
    IL_0000:  nop
    IL_0001:  ldarg.0
    IL_0002:  ldarg.1
    IL_0003:  add
    IL_0004:  stloc.0
    IL_0005:  br.s       IL_0007

    IL_0007:  ldloc.0
    IL_0008:  ret
  } // end of method Gateway::Plus

  .method public hidebysig static float64 
          Sum(float64* x,
              int32 n) cil managed
  {
    // Code size       45 (0x2d)
    .maxstack  4
    .locals init (float64 V_0,
             int32 V_1,
             bool V_2,
             float64 V_3)
    IL_0000:  nop
    IL_0001:  ldc.r8     0.0
    IL_000a:  stloc.0
    IL_000b:  ldc.i4.0
    IL_000c:  stloc.1
    IL_000d:  br.s       IL_001f

    IL_000f:  nop
    IL_0010:  ldloc.0
    IL_0011:  ldarg.0
    IL_0012:  ldloc.1
    IL_0013:  conv.i
    IL_0014:  ldc.i4.8
    IL_0015:  mul
    IL_0016:  add
    IL_0017:  ldind.r8
    IL_0018:  add
    IL_0019:  stloc.0
    IL_001a:  nop
    IL_001b:  ldloc.1
    IL_001c:  ldc.i4.1
    IL_001d:  add
    IL_001e:  stloc.1
    IL_001f:  ldloc.1
    IL_0020:  ldarg.1
    IL_0021:  clt
    IL_0023:  stloc.2
    IL_0024:  ldloc.2
    IL_0025:  brtrue.s   IL_000f

    IL_0027:  ldloc.0
    IL_0028:  stloc.3
    IL_0029:  br.s       IL_002b

    IL_002b:  ldloc.3
    IL_002c:  ret
  } // end of method Gateway::Sum

  .method public hidebysig static float64 
          Sum2(float64* x,
               int32 n) cil managed
  {
    // Code size       27 (0x1b)
    .maxstack  3
    .locals init (valuetype [System.Runtime]System.Span`1<float64> V_0,
             float64 V_1)
    IL_0000:  nop
    IL_0001:  ldloca.s   V_0
    IL_0003:  ldarg.0
    IL_0004:  ldarg.1
    IL_0005:  call       instance void valuetype [System.Runtime]System.Span`1<float64>::.ctor(void*,
                                                                                               int32)
    IL_000a:  ldloca.s   V_0
    IL_000c:  call       instance !0[] valuetype [System.Runtime]System.Span`1<float64>::ToArray()
    IL_0011:  call       float64 [System.Linq]System.Linq.Enumerable::Sum(class [System.Runtime]System.Collections.Generic.IEnumerable`1<float64>)
    IL_0016:  stloc.1
    IL_0017:  br.s       IL_0019

    IL_0019:  ldloc.1
    IL_001a:  ret
  } // end of method Gateway::Sum2

  .method public hidebysig static string 
          marshal( lpstr) 
          ManagedDirectMethod(string  marshal( lpstr) funcName,
                              string  marshal( lpstr) jsonArgs,
                              class UnmanagedCallbackDelegate dlgUnmanagedCallback) cil managed
  {
    // Code size       263 (0x107)
    .maxstack  3
    .locals init (string V_0,
             valuetype [System.Runtime]System.Runtime.CompilerServices.DefaultInterpolatedStringHandler V_1,
             valuetype [System.Runtime]System.Nullable`1<bool> V_2,
             valuetype [System.Runtime]System.Nullable`1<bool> V_3,
             class [System.Runtime]System.Exception V_4,
             string V_5)
    IL_0000:  nop
    IL_0001:  ldloca.s   V_1
    IL_0003:  ldc.i4.s   43
    IL_0005:  ldc.i4.2
    IL_0006:  call       instance void [System.Runtime]System.Runtime.CompilerServices.DefaultInterpolatedStringHandler::.ctor(int32,
                                                                                                                               int32)
    IL_000b:  ldloca.s   V_1
    IL_000d:  ldstr      "ManagedDirectMethod(funcName: "
    IL_0012:  call       instance void [System.Runtime]System.Runtime.CompilerServices.DefaultInterpolatedStringHandler::AppendLiteral(string)
    IL_0017:  nop
    IL_0018:  ldloca.s   V_1
    IL_001a:  ldarg.0
    IL_001b:  call       instance void [System.Runtime]System.Runtime.CompilerServices.DefaultInterpolatedStringHandler::AppendFormatted(string)
    IL_0020:  nop
    IL_0021:  ldloca.s   V_1
    IL_0023:  ldstr      ", jsonArgs: "
    IL_0028:  call       instance void [System.Runtime]System.Runtime.CompilerServices.DefaultInterpolatedStringHandler::AppendLiteral(string)
    IL_002d:  nop
    IL_002e:  ldloca.s   V_1
    IL_0030:  ldarg.1
    IL_0031:  call       instance void [System.Runtime]System.Runtime.CompilerServices.DefaultInterpolatedStringHandler::AppendFormatted(string)
    IL_0036:  nop
    IL_0037:  ldloca.s   V_1
    IL_0039:  ldstr      ")"
    IL_003e:  call       instance void [System.Runtime]System.Runtime.CompilerServices.DefaultInterpolatedStringHandler::AppendLiteral(string)
    IL_0043:  nop
    IL_0044:  ldloca.s   V_1
    IL_0046:  call       instance string [System.Runtime]System.Runtime.CompilerServices.DefaultInterpolatedStringHandler::ToStringAndClear()
    IL_004b:  call       void [System.Console]System.Console::WriteLine(string)
    IL_0050:  nop
    IL_0051:  ldnull
    IL_0052:  stloc.0
    .try
    {
      IL_0053:  nop
      IL_0054:  ldarg.2
      IL_0055:  brtrue.s   IL_0062

      IL_0057:  ldloca.s   V_3
      IL_0059:  initobj    valuetype [System.Runtime]System.Nullable`1<bool>
      IL_005f:  ldloc.3
      IL_0060:  br.s       IL_006f

      IL_0062:  ldarg.2
      IL_0063:  ldarg.0
      IL_0064:  ldarg.1
      IL_0065:  callvirt   instance bool UnmanagedCallbackDelegate::Invoke(string,
                                                                           string)
      IL_006a:  newobj     instance void valuetype [System.Runtime]System.Nullable`1<bool>::.ctor(!0)
      IL_006f:  stloc.2
      IL_0070:  ldc.i4.4
      IL_0071:  ldc.i4.1
      IL_0072:  newobj     instance void [System.Runtime]System.Runtime.CompilerServices.DefaultInterpolatedStringHandler::.ctor(int32,
                                                                                                                                 int32)
      IL_0077:  stloc.1
      IL_0078:  ldloca.s   V_1
      IL_007a:  ldstr      "res="
      IL_007f:  call       instance void [System.Runtime]System.Runtime.CompilerServices.DefaultInterpolatedStringHandler::AppendLiteral(string)
      IL_0084:  nop
      IL_0085:  ldloca.s   V_1
      IL_0087:  ldloc.2
      IL_0088:  call       instance void [System.Runtime]System.Runtime.CompilerServices.DefaultInterpolatedStringHandler::AppendFormatted<valuetype [System.Runtime]System.Nullable`1<bool>>(!!0)
      IL_008d:  nop
      IL_008e:  ldloca.s   V_1
      IL_0090:  call       instance string [System.Runtime]System.Runtime.CompilerServices.DefaultInterpolatedStringHandler::ToStringAndClear()
      IL_0095:  stloc.0
      IL_0096:  nop
      IL_0097:  leave.s    IL_00ff

    }  // end .try
    catch [System.Runtime]System.Exception 
    {
      IL_0099:  stloc.s    V_4
      IL_009b:  nop
      IL_009c:  ldloca.s   V_1
      IL_009e:  ldc.i4.s   20
      IL_00a0:  ldc.i4.3
      IL_00a1:  call       instance void [System.Runtime]System.Runtime.CompilerServices.DefaultInterpolatedStringHandler::.ctor(int32,
                                                                                                                                 int32)
      IL_00a6:  ldloca.s   V_1
      IL_00a8:  ldstr      "ERROR in \""
      IL_00ad:  call       instance void [System.Runtime]System.Runtime.CompilerServices.DefaultInterpolatedStringHandler::AppendLiteral(string)
      IL_00b2:  nop
      IL_00b3:  ldloca.s   V_1
      IL_00b5:  ldarg.0
      IL_00b6:  call       instance void [System.Runtime]System.Runtime.CompilerServices.DefaultInterpolatedStringHandler::AppendFormatted(string)
      IL_00bb:  nop
      IL_00bc:  ldloca.s   V_1
      IL_00be:  ldstr      "\" invoke:"
      IL_00c3:  call       instance void [System.Runtime]System.Runtime.CompilerServices.DefaultInterpolatedStringHandler::AppendLiteral(string)
      IL_00c8:  nop
      IL_00c9:  ldloca.s   V_1
      IL_00cb:  call       string [System.Runtime]System.Environment::get_NewLine()
      IL_00d0:  call       instance void [System.Runtime]System.Runtime.CompilerServices.DefaultInterpolatedStringHandler::AppendFormatted(string)
      IL_00d5:  nop
      IL_00d6:  ldloca.s   V_1
      IL_00d8:  ldstr      " "
      IL_00dd:  call       instance void [System.Runtime]System.Runtime.CompilerServices.DefaultInterpolatedStringHandler::AppendLiteral(string)
      IL_00e2:  nop
      IL_00e3:  ldloca.s   V_1
      IL_00e5:  ldloc.s    V_4
      IL_00e7:  call       instance void [System.Runtime]System.Runtime.CompilerServices.DefaultInterpolatedStringHandler::AppendFormatted<class [System.Runtime]System.Exception>(!!0)
      IL_00ec:  nop
      IL_00ed:  ldloca.s   V_1
      IL_00ef:  call       instance string [System.Runtime]System.Runtime.CompilerServices.DefaultInterpolatedStringHandler::ToStringAndClear()
      IL_00f4:  stloc.0
      IL_00f5:  ldloc.0
      IL_00f6:  call       void [System.Console]System.Console::WriteLine(string)
      IL_00fb:  nop
      IL_00fc:  nop
      IL_00fd:  leave.s    IL_00ff

    }  // end handler
    IL_00ff:  ldloc.0
    IL_0100:  stloc.s    V_5
    IL_0102:  br.s       IL_0104

    IL_0104:  ldloc.s    V_5
    IL_0106:  ret
  } // end of method Gateway::ManagedDirectMethod

} // end of class Gateway


// =============================================================

// *********** DISASSEMBLY COMPLETE ***********************
// WARNING: Created Win32 resource file gateway.res


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
  .custom instance void [System.Runtime]System.Reflection.AssemblyInformationalVersionAttribute::.ctor(string) = ( 01 00 2E 31 2E 30 2E 30 2B 39 36 65 64 65 33 35   // ...1.0.0+96ede35
                                                                                                                   66 65 62 38 63 66 63 66 65 36 61 32 34 33 37 38   // feb8cfcfe6a24378
                                                                                                                   65 30 66 65 66 39 62 62 38 64 33 65 64 34 36 36   // e0fef9bb8d3ed466
                                                                                                                   32 00 00 )                                        // 2..
  .custom instance void [System.Runtime]System.Reflection.AssemblyProductAttribute::.ctor(string) = ( 01 00 07 67 61 74 65 77 61 79 00 00 )             // ...gateway..
  .custom instance void [System.Runtime]System.Reflection.AssemblyTitleAttribute::.ctor(string) = ( 01 00 07 67 61 74 65 77 61 79 00 00 )             // ...gateway..
  .permissionset reqmin
             = {[System.Runtime]System.Security.Permissions.SecurityPermissionAttribute = {property bool 'SkipVerification' = bool(true)}}
  .hash algorithm 0x00008004
  .ver 1:0:0:0
}
.module gateway.dll
// MVID: {f2b9521b-2b09-423f-9681-c835c6b7ad12}
.custom instance void [System.Runtime]System.Security.UnverifiableCodeAttribute::.ctor() = ( 01 00 00 00 )
.custom instance void [System.Runtime]System.Runtime.CompilerServices.RefSafetyRulesAttribute::.ctor(int32) = ( 01 00 0B 00 00 00 00 00 )
.imagebase 0x10000000
.file alignment 0x00000200
.stackreserve 0x00100000
.subsystem 0x0003       // WINDOWS_CUI
.corflags 0x00000001    //  ILONLY
// Image base: 0x0000024111F30000


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
    // Code size       21 (0x15)
    .maxstack  8
    IL_0000:  ldtoken    Gateway
    IL_0005:  call       class [System.Runtime]System.Type [System.Runtime]System.Type::GetTypeFromHandle(valuetype [System.Runtime]System.RuntimeTypeHandle)
    IL_000a:  callvirt   instance class [System.Runtime]System.Reflection.Assembly [System.Runtime]System.Type::get_Assembly()
    IL_000f:  callvirt   instance string [System.Runtime]System.Reflection.Assembly::get_Location()
    IL_0014:  ret
  } // end of method Gateway::Bootstrap

  .method public hidebysig static float64
          Plus(float64 x,
               float64 y) cil managed
  {
    // Code size       4 (0x4)
    .maxstack  8
    IL_0000:  ldarg.0
    IL_0001:  ldarg.1
    IL_0002:  add
    IL_0003:  ret
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
                              class UnmanagedCallbackDelegate unmanagedCallback) cil managed
  {
    // Code size       213 (0xd5)
    .maxstack  4
    .locals init (string V_0,
             valuetype [System.Runtime]System.Nullable`1<bool> V_1,
             valuetype [System.Runtime]System.Nullable`1<bool> V_2,
             valuetype [System.Runtime]System.Runtime.CompilerServices.DefaultInterpolatedStringHandler V_3,
             class [System.Runtime]System.Exception V_4,
             string V_5)
    IL_0000:  nop
    IL_0001:  ldstr      "C#>> "
    IL_0006:  ldarg.0
    IL_0007:  ldstr      ", "
    IL_000c:  ldarg.1
    IL_000d:  call       string [System.Runtime]System.String::Concat(string,
                                                                      string,
                                                                      string,
                                                                      string)
    IL_0012:  call       void [System.Console]System.Console::WriteLine(string)
    IL_0017:  nop
    IL_0018:  ldnull
    IL_0019:  stloc.0
    .try
    {
      IL_001a:  nop
      IL_001b:  ldarg.2
      IL_001c:  brtrue.s   IL_0029

      IL_001e:  ldloca.s   V_2
      IL_0020:  initobj    valuetype [System.Runtime]System.Nullable`1<bool>
      IL_0026:  ldloc.2
      IL_0027:  br.s       IL_0036

      IL_0029:  ldarg.2
      IL_002a:  ldarg.0
      IL_002b:  ldarg.1
      IL_002c:  callvirt   instance bool UnmanagedCallbackDelegate::Invoke(string,
                                                                           string)
      IL_0031:  newobj     instance void valuetype [System.Runtime]System.Nullable`1<bool>::.ctor(!0)
      IL_0036:  stloc.1
      IL_0037:  ldc.i4.s   13
      IL_0039:  ldc.i4.1
      IL_003a:  newobj     instance void [System.Runtime]System.Runtime.CompilerServices.DefaultInterpolatedStringHandler::.ctor(int32,
                                                                                                                                 int32)
      IL_003f:  stloc.3
      IL_0040:  ldloca.s   V_3
      IL_0042:  ldstr      "Invoke was \""
      IL_0047:  call       instance void [System.Runtime]System.Runtime.CompilerServices.DefaultInterpolatedStringHandler::AppendLiteral(string)
      IL_004c:  nop
      IL_004d:  ldloca.s   V_3
      IL_004f:  ldloc.1
      IL_0050:  call       instance void [System.Runtime]System.Runtime.CompilerServices.DefaultInterpolatedStringHandler::AppendFormatted<valuetype [System.Runtime]System.Nullable`1<bool>>(!!0)
      IL_0055:  nop
      IL_0056:  ldloca.s   V_3
      IL_0058:  ldstr      "\""
      IL_005d:  call       instance void [System.Runtime]System.Runtime.CompilerServices.DefaultInterpolatedStringHandler::AppendLiteral(string)
      IL_0062:  nop
      IL_0063:  ldloca.s   V_3
      IL_0065:  call       instance string [System.Runtime]System.Runtime.CompilerServices.DefaultInterpolatedStringHandler::ToStringAndClear()
      IL_006a:  stloc.0
      IL_006b:  nop
      IL_006c:  leave.s    IL_00cd

    }  // end .try
    catch [System.Runtime]System.Exception
    {
      IL_006e:  stloc.s    V_4
      IL_0070:  nop
      IL_0071:  ldloca.s   V_3
      IL_0073:  ldc.i4.s   20
      IL_0075:  ldc.i4.3
      IL_0076:  call       instance void [System.Runtime]System.Runtime.CompilerServices.DefaultInterpolatedStringHandler::.ctor(int32,
                                                                                                                                 int32)
      IL_007b:  ldloca.s   V_3
      IL_007d:  ldstr      "ERROR in \""
      IL_0082:  call       instance void [System.Runtime]System.Runtime.CompilerServices.DefaultInterpolatedStringHandler::AppendLiteral(string)
      IL_0087:  nop
      IL_0088:  ldloca.s   V_3
      IL_008a:  ldarg.0
      IL_008b:  call       instance void [System.Runtime]System.Runtime.CompilerServices.DefaultInterpolatedStringHandler::AppendFormatted(string)
      IL_0090:  nop
      IL_0091:  ldloca.s   V_3
      IL_0093:  ldstr      "\" invoke:"
      IL_0098:  call       instance void [System.Runtime]System.Runtime.CompilerServices.DefaultInterpolatedStringHandler::AppendLiteral(string)
      IL_009d:  nop
      IL_009e:  ldloca.s   V_3
      IL_00a0:  call       string [System.Runtime]System.Environment::get_NewLine()
      IL_00a5:  call       instance void [System.Runtime]System.Runtime.CompilerServices.DefaultInterpolatedStringHandler::AppendFormatted(string)
      IL_00aa:  nop
      IL_00ab:  ldloca.s   V_3
      IL_00ad:  ldstr      " "
      IL_00b2:  call       instance void [System.Runtime]System.Runtime.CompilerServices.DefaultInterpolatedStringHandler::AppendLiteral(string)
      IL_00b7:  nop
      IL_00b8:  ldloca.s   V_3
      IL_00ba:  ldloc.s    V_4
      IL_00bc:  call       instance void [System.Runtime]System.Runtime.CompilerServices.DefaultInterpolatedStringHandler::AppendFormatted<class [System.Runtime]System.Exception>(!!0)
      IL_00c1:  nop
      IL_00c2:  ldloca.s   V_3
      IL_00c4:  call       instance string [System.Runtime]System.Runtime.CompilerServices.DefaultInterpolatedStringHandler::ToStringAndClear()
      IL_00c9:  stloc.0
      IL_00ca:  nop
      IL_00cb:  leave.s    IL_00cd

    }  // end handler
    IL_00cd:  ldloc.0
    IL_00ce:  stloc.s    V_5
    IL_00d0:  br.s       IL_00d2

    IL_00d2:  ldloc.s    V_5
    IL_00d4:  ret
  } // end of method Gateway::ManagedDirectMethod

} // end of class Gateway


// =============================================================

// *********** DISASSEMBLY COMPLETE ***********************
// WARNING: Created Win32 resource file gateway.res

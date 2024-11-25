package csharp

import "core:io"
import "core:bytes"
import "core:strings"

/*
https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/builtin-types/integral-numeric-types

C#         Odin       C#           C#
*/
sbyte	:: i8     	; SByte		:: sbyte
byte	:: u8     	; Byte		:: byte
short	:: i16    	; Int16		:: short
ushort	:: u16    	; UInt16	:: ushort
int		:: i32    	; Int32		:: int
uint	:: u32    	; UInt32	:: uint
long	:: i64    	; Int64		:: long
ulong	:: u64    	; UInt64	:: ulong
nint	:: rawptr 	; IntPtr	:: nint
nuint	:: uintptr	; UIntPtr	:: nuint
float	:: f32    	; Single	:: float
double	:: f64    	; Double	:: double
bool    :: b8     	; Bool		:: bool
char	:: u16    	; Char		:: char
string	:: [^]char	; String	:: string

/*
C#             Odin
*/
Stream         :: io.Stream
BinaryReader   :: bytes.Reader
//BinaryWriter :: bytes.Writer // where did the writer go?
StreamReader   :: strings.Reader
//StreamWriter :: strings.Writer // where did the writer go?
StringBuilder  :: strings.Builder

//builder := strings.builder_make()
//defer strings.builder_destroy(&builder)

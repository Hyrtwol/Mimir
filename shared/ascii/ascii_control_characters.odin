package ascii

/*
\' – single quote, needed for character literals
\" – double quote, needed for string literals
\\ – backslash
\0 – Unicode character 0
\a – Alert(character 7)
\b – Backspace(character 8)
\f – Form feed(character 12)
\n – New line(character 10)
\r – Carriage return (character 13)
\t – Horizontal tab(character 9)
\v – Vertical quote(character 11)
\uxxxx – Unicode escape sequence for character with hex value xxxx
\xn[n][n][n] – Unicode escape sequence for character with hex value nnnn(variable length version of \uxxxx)

See http://ascii.cl/control-characters.htm
*/
control_characters :: enum u8 {
     //   0 Null                  '\0'
    NUL = '\x00',
     //   1 Start of Heading              Communication Control
    SOH = '\x01',
     //   2 Start of Text                 Communication Control
    STX = '\x02',
     //   3 End of Text                   Communication Control
    ETX = '\x03',
     //   4 End of Transmission           Communication Control
    EOT = '\x04',
     //   5 Enquiry                       Communication Control
    ENQ = '\x05',
     //   6 Acknowledge                   Communication Control
    ACK = '\x06',
     //   7 Bell                  '\a'
    BEL = '\x07',
     //   8 Backspace             '\b'    Format Effector
    BS  = '\x08',
     //   9 Horizontal Tabulation '\t'    Format Effector
    TAB = '\x09',
     //  10 Line Feed             '\n'    Format Effector
    LF  = '\x0A',
     //  11 Vertical Tabulation   '\v'    Format Effector
    VT  = '\x0B',
     //  12 Form Feed             '\f'    Format Effector
    FF  = '\x0C',
     //  13 Carriage Return       '\r'    Format Effector
    CR  = '\x0D',
     //  14 Shift Out
    SO  = '\x0E',
     //  15 Shift In
    SI  = '\x0F',
     //  16 Data Link Escape              Communication Control
    DLE = '\x10',
     //  17 Device Control 1 (Border)
    DC1 = '\x11',
     //  18 Device Control 2 (Paper)
    DC2 = '\x12',
     //  19 Device Control 3 (Pen)
    DC3 = '\x13',
     //  20 Device Control 4
    DC4 = '\x14',
     //  21 Negative Acknowledge          Communication Control
    NAK = '\x15',
     //  22 Synchronous Idle              Communication Control
    SYN = '\x16',
     //  23 End of Transmission Block     Communication Control
    ETB = '\x17',
     //  24 Cancel
    CAN = '\x18',
     //  25 End of Medium
    EM  = '\x19',
     //  26 Substitute
    SUB = '\x1A',
     //  27 Escape
    ESC = '\x1B',
     //  28 File Separator                Information Separator
    FS  = '\x1C',
     //  29 Group Separator               Information Separator
    GS  = '\x1D',
     //  30 Record Separator              Information Separator
    RS  = '\x1E',
     //  31 Unit Separator                Information Separator
    US  = '\x1F',
     // 127 Delete
    DEL = '\x7F',

    // public static bool IsEndOfLineChar(this char ch) => (ch == '\r') || (ch == '\n');
    // public static bool IsEndOfLineChar(this int ch) => (ch == '\r') || (ch == '\n');
}

/*newline_style :: enum {
	CRLF,
	LF,
}
newline_style_config : newline_style : .CRLF*/

when ODIN_OS == .Windows {
	newline := "\n"
} else {
	newline := "\r\n"
}

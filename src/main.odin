#+feature dynamic-literals
package hexdump

import "core:fmt"
import "core:io"
import "core:math"
import "core:os"
import "core:sys/posix"
import "core:terminal/ansi"
import "core:unicode"

import c "colors"

SCRATCH_BUFFER_SIZE :: #config(SCRATCH_BUFFER_SIZE, 1024)

handle_color_mapping_error :: proc(mapping_error: c.Error) {
  switch parse_error in mapping_error {
  case c.Parse_Error:
    c.eprint_ansi_code(ansi.CSI, ansi.FG_RED, ansi.SGR)
    fmt.eprintln("Error while parsing color mapping: ")
    c.eprint_ansi_code(ansi.CSI, ansi.RESET, ansi.SGR)
    switch err_detail in parse_error.detail {
    case c.Unexpected_End_Of_String:
      fmt.eprintln("Unexpected end of string (expected a key=value declaration)")
    case c.Invalid_Key:
      fmt.eprintfln("'%s' is not a valid key (expects one of [afhosz])", err_detail.key)
    case c.Invalid_Value:
      fmt.eprintf("'%s' is not a valid value. ", err_detail.key)
      switch value_err in err_detail.reason {
      case c.Empty_Value:
        fmt.eprintln("Value may not be empty")
      case c.Invalid_Hex_Length:
        fmt.eprintfln(
          "Hexadecimal value must be 6 digit long (RGB, 1 byte each), not %i",
          value_err.length,
        )
      case c.Invalid_Hex_Number:
        fmt.eprintfln("Not an hexadecimal number: %s", value_err.number)
      case c.Unexpected_Character:
        fmt.eprintfln(
          "Unexpected character '%v', expected a semicolon-delimited string of numbers.",
          value_err.char,
        )
      case:
        fmt.eprintln("What is this?")
      }
    case c.Unexpected_Character:
      fmt.eprintfln("Unexpected character: %v (wanted =)", err_detail.char)
    }
    fmt.eprintfln("\t%s", parse_error.full_string)
    c.eprint_ansi_code(ansi.CSI, ansi.FG_RED, ansi.SGR)
    fmt.print("\t")
    for _ in 0 ..< parse_error.location {
      fmt.print('-')
    }
    fmt.println('^')
    c.eprint_ansi_code(ansi.CSI, ansi.RESET, ansi.SGR)
    os.exit(1)

  case c.None:
  // good
  }
}

main :: proc() {
  opts, file := parse_arguments()

  buf: [SCRATCH_BUFFER_SIZE]u8

  // Should we use color at all?
  output_on_tty := bool(posix.isatty(posix.STDOUT_FILENO))
  no_color_value, _ := os.lookup_env_buf(buf[:], "NO_COLOR")
  no_color := no_color_value != ""

  c.should_use_color =
    !no_color &&
    ((!output_on_tty && opts.color == Argument_Color.always) ||
        (output_on_tty && opts.color != Argument_Color.never))

  // Setup optional color mapping
  if (c.should_use_color) {
    if opts.color_mapping != "" {
      mapping_error := c.color_mapping_setup(opts.color_mapping)
      handle_color_mapping_error(mapping_error)
    }

    color_mapping_value, color_mapping_error := os.lookup_env_buf(buf[:], "HEXDUMP_COLOR_MAPPING")
    #partial switch err in color_mapping_error {
    case io.Error:
      #partial switch err {
      case .Buffer_Full:
        c.print_ansi_code(ansi.CSI, ansi.FG_YELLOW, ansi.SGR)
        fmt.eprintfln(
          "Internal buffer (%i) is too small for the color mapping. Rebuild the program with a greater value of SCRATCH_BUFFER_SIZE.",
          SCRATCH_BUFFER_SIZE,
        )
        c.print_ansi_code(ansi.CSI, ansi.RESET, ansi.SGR)
      }
    }

    if color_mapping_value != "" {
      mapping_error := c.color_mapping_setup(color_mapping_value)
      handle_color_mapping_error(mapping_error)
    }

    c.default_color_setup()
  }


  first_byte := 0

  for first_byte < len(file) {
    last_byte := math.min(first_byte + opts.width, len(file))

    line := file[first_byte:last_byte]

    c.print_ansi_code(ansi.CSI, c.COLOR_ADDRESS.value, ansi.SGR)
    fmt.printf("%08X ", first_byte)
    last := c.Colorable_Type.NONE
    for char in line {
      last = c.print_character_colored(char, last, proc(char: byte) {
        fmt.printf("%02X ", char)
      })
    }
    fill_spaces(last_byte, first_byte + opts.width, "   ")

    for char in line {
      last = c.print_character_colored(char, last, proc(char: byte) {
        if char < unicode.MAX_ASCII &&
           unicode.is_print(rune(char)) &&
           !unicode.is_space(rune(char)) {
          fmt.print(rune(char))
        } else {
          fmt.print('.')
        }
      })
    }
    fill_spaces(last_byte, first_byte + opts.width, " ")

    fmt.println(ansi.CSI + ansi.RESET + ansi.SGR)

    first_byte += opts.width
  }

  defer delete(file)

}

fill_spaces :: proc(last_byte: int, target_byte: int, content: string) {
  if (last_byte < target_byte) {
    for i in 0 ..< (target_byte - last_byte) {
      fmt.printf(content)
    }
  }
}

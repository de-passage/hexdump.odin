#+feature dynamic-literals
package hexdump

import "core:os"
import "core:sys/posix"
import "core:terminal/ansi"
import "core:unicode"
import "core:math"
import "core:fmt"
import "core:io"

import c "colors"

SCRATCH_BUFFER_SIZE :: #config(SCRATCH_BUFFER_SIZE, 1024)

main :: proc() {
  opts, file := parse_arguments()

  buf : [SCRATCH_BUFFER_SIZE]u8

  // Should we use color at all?
  output_on_tty := bool(posix.isatty(posix.STDOUT_FILENO))
  no_color_value, _ := os.lookup_env_buf(buf[:], "NO_COLOR")
  no_color := no_color_value != ""

  c.should_use_color = !no_color &&
  (   (!output_on_tty && opts.color == Argument_Color.always)
      || (output_on_tty && opts.color != Argument_Color.never)
  )

  // Setup optional color mapping
  if (c.should_use_color) {
    if opts.color_mapping != "" {
      c.color_mapping_setup(opts.color_mapping)
    }

    color_mapping_value, color_mapping_error := os.lookup_env_buf(buf[:], "HEXDUMP_COLOR_MAPPING")
    #partial switch err in color_mapping_error {
      case io.Error:
        #partial switch err {
        case .Buffer_Full:
          fmt.eprintfln("Internal buffer (%i) is too small for the color mapping. Rebuild the program with a greater value of SCRATCH_BUFFER_SIZE.", SCRATCH_BUFFER_SIZE)
        }
    }

    if color_mapping_value != "" {
      c.color_mapping_setup(color_mapping_value)
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
    fill_spaces(last_byte, first_byte + opts.width, "   ");

    for char in line {
      last = c.print_character_colored(char, last, proc(char: byte) {
        if char < unicode.MAX_ASCII && unicode.is_print(rune(char)) && !unicode.is_space(rune(char)) {
          fmt.print(rune(char))
        } else {
          fmt.print('.')
        }
      })
    }
    fill_spaces(last_byte, first_byte + opts.width, " ");

    fmt.println(ansi.CSI+ansi.RESET+ansi.SGR)

    first_byte += opts.width
  }

  defer delete(file)

}

fill_spaces :: proc(
  last_byte: int,
  target_byte : int,
  content : string
) {
  if (last_byte < target_byte) {
    for i in 0..<(target_byte - last_byte) {
      fmt.printf(content);
    }
  }
}

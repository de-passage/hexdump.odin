#+feature dynamic-literals
package hexdump

import "core:os"
import "core:sys/posix"
import "core:terminal/ansi"
import "core:unicode"
import "core:math"
import "core:fmt"
import "core:io"

SCRATCH_BUFFER_SIZE :: #config(SCRATCH_BUFFER_SIZE, 1024)

print_character_colored :: proc(char: byte, last: Colorable_Type, print: proc(char: byte)) -> Colorable_Type {
  print_character_with_color :: proc (char: byte, print: proc(char: byte), last: Colorable_Type, target: Colorable_Type, color: string) -> Colorable_Type {
    if last != target && should_use_color {
        print_ansi_code(ansi.CSI + ansi.RESET + ansi.SGR + ansi.CSI, color, ansi.SGR)
    }
    print(char)
    return target
  }
  switch char {
    case 0:
      return print_character_with_color(char, print, last, Colorable_Type.ZERO, COLOR_ZERO)
    case 1..=8: // control codes
      return print_character_with_color(char, print, last, Colorable_Type.OTHER, COLOR_OTHER)
    case 9..=13:
      return print_character_with_color(char, print, last, Colorable_Type.SPACE, COLOR_SPACE)
    case 14..=19:
      return print_character_with_color(char, print, last, Colorable_Type.OTHER, COLOR_OTHER)
    case 20:
      return print_character_with_color(char, print, last, Colorable_Type.SPACE, COLOR_SPACE)
    case 21..=126:
      return print_character_with_color(char, print, last, Colorable_Type.ASCII, COLOR_ASCII)
    case 255:
      return print_character_with_color(char, print, last, Colorable_Type.FF, COLOR_FF)
    case:
      return print_character_with_color(char, print, last, Colorable_Type.OTHER, COLOR_OTHER)
  }
}


main :: proc() {
  opts, file := parse_arguments()

  buf : [SCRATCH_BUFFER_SIZE]u8

  // Should we use color at all?
  output_on_tty := bool(posix.isatty(posix.STDOUT_FILENO))
  no_color_value, _ := os.lookup_env_buf(buf[:], "NO_COLOR")
  no_color := no_color_value != ""

  should_use_color = !no_color &&
  (   (!output_on_tty && opts.color == Argument_Color.always)
      || (output_on_tty && opts.color != Argument_Color.never)
  )

  // Setup optional color mapping
  if (should_use_color) {
    if opts.color_mapping != "" {
      color_mapping_setup(opts.color_mapping)
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
      color_mapping_setup(color_mapping_value)
    }
  }


  first_byte := 0

  for first_byte < len(file) {
    last_byte := math.min(first_byte + opts.width, len(file))

    line := file[first_byte:last_byte]

    print_ansi_code(ansi.CSI, COLOR_ADDRESS, ansi.SGR)
    fmt.printf("%08X ", first_byte)
    last := Colorable_Type.NONE
    for char in line {
      last = print_character_colored(char, last, proc(char: byte) {
        fmt.printf("%02X ", char)
      })
    }
    fill_spaces(last_byte, first_byte + opts.width, "   ");

    for char in line {
      last = print_character_colored(char, last, proc(char: byte) {
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

#+feature dynamic-literals
package hexdump

import "core:os"
import "core:sys/posix"
import "core:terminal/ansi"
import "core:unicode"
import "core:math"
import "core:fmt"

should_use_color : bool

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

Colorable_Type :: enum {
  NONE,
  ASCII,
  SPACE,
  OTHER,
  ZERO,
  FF
}

COLOR_ZERO :: ";90;90;90"
COLOR_OTHER :: ";210;210;210"
COLOR_SPACE :: ";10;200;200"
COLOR_ASCII :: ";99;168;129"
COLOR_FF :: ";242;84;10"

print_ansi_code :: proc(code: string) {
  if should_use_color {
    fmt.print(code)
  }
}

print_character_colored :: proc(char: byte, last: Colorable_Type, print: proc(char: byte)) -> Colorable_Type {
  print_character_with_color :: proc (char: byte, print: proc(char: byte), last: Colorable_Type, target: Colorable_Type, color: string) -> Colorable_Type {
    if last != target && should_use_color {
        fmt.print(ansi.CSI + ansi.RESET + ansi.SGR + ansi.CSI + ansi.FG_COLOR_24_BIT)
        fmt.print(color)
        fmt.print(ansi.SGR)
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

  output_on_tty := bool(posix.isatty(posix.STDOUT_FILENO))
  buf : [512]u8
  no_color_value, _ := os.lookup_env_buf(buf[:], "NO_COLOR")
  no_color := no_color_value != ""
  should_use_color = !no_color &&
  (   (!output_on_tty && opts.color == Argument_Color.always)
      || (output_on_tty && opts.color != Argument_Color.never)
  )

  first_byte := 0

  for first_byte < len(file) {
    last_byte := math.min(first_byte + opts.width, len(file))

    line := file[first_byte:last_byte]

    print_ansi_code(ansi.CSI + ansi.FG_COLOR_24_BIT + ";214;197;2" + ansi.SGR)
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

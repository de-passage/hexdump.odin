package hexdump

import "core:unicode"
import "core:math"
import "core:terminal/ansi"
import "core:fmt"

import c "colors"

decode_generic_buffer :: proc(buffer: []byte, width: int) {
  first_byte := 0

  for first_byte < len(buffer) {
    last_byte := math.min(first_byte + width, len(buffer))

    line := buffer[first_byte:last_byte]

    c.print_ansi_code(ansi.CSI, c.COLOR_ADDRESS.value, ansi.SGR)
    fmt.printf("%08X ", first_byte)
    last := c.Colorable_Type.NONE
    for char in line {
      last = c.print_character_colored(char, last, proc(char: byte) {
        fmt.printf("%02X ", char)
      })
    }
    fill_spaces(last_byte, first_byte + width, "   ")

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
    fill_spaces(last_byte, first_byte + width, " ")

    fmt.println(ansi.CSI + ansi.RESET + ansi.SGR)

    first_byte += width
  }
}

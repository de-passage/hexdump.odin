#+feature dynamic-literals
package hexdump

import "core:unicode"
import "core:math"
import "core:fmt"

main :: proc() {
  opts, file := parse_arguments()

  first_byte := 0

  for first_byte < len(file) {
    last_byte := math.min(first_byte + opts.width, len(file))

    line := file[first_byte:last_byte]

    fmt.printf("%08X ", first_byte)
    for char in line {
      fmt.printf("%02X ", char)
    }
    if (last_byte < first_byte + opts.width) {
      for i in 0..<(first_byte + opts.width - last_byte) {
        fmt.printf("   ");
      }
    }

    for char in line {
      if char < 0x7F && unicode.is_print(rune(char)) {
        fmt.print(rune(char))
      } else {
        fmt.print('.')
      }
    }
    if (last_byte < first_byte + opts.width) {
      for i in 0..<(first_byte + opts.width - last_byte) {
        fmt.printf(" ");
      }
    }

    fmt.println()

    first_byte += opts.width
  }

  defer delete(file)

}

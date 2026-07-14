#+feature dynamic-literals
package test

import "core:unicode"
import "core:math"
import "base:runtime"
import "core:fmt"
import "core:os"

main :: proc() {
  if len(os.args) != 2 {
    fmt.eprintln("Missing file name");
    os.exit(1)
  }

  file, ok := os.read_entire_file(os.args[1], context.allocator)
  if ok != os.ERROR_NONE {
    fmt.eprintln("Failed to open ", os.args[1])
    os.exit(1)
  }

  first_byte := 0

  for first_byte < len(file) {
    last_byte := math.min(first_byte+16, len(file))

    line := file[first_byte:last_byte]

    fmt.printf("%08X ", first_byte)
    for char in line {
      fmt.printf("%02X ", char)
    }
    if (last_byte < first_byte + 16) {
      for i in 0..<(first_byte + 16 - last_byte) {
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
    if (last_byte < first_byte + 16) {
      for i in 0..<(first_byte + 16 - last_byte) {
        fmt.printf(" ");
      }
    }

    fmt.println()

    first_byte += 16
  }

  defer delete(file)

}

#+feature dynamic-literals
package test

import "core:flags"
import "core:unicode"
import "core:math"
import "base:runtime"
import "core:fmt"
import "core:os"

main :: proc() {
  Options :: struct {
    width: int `usage:"Number of bytes to print on a single line`,
    filename: string `args:"required,pos=0"`,
  }
  opts : Options
  style : flags.Parsing_Style = .Unix

  opts.width = 16
  error := flags.parse(&opts, os.args, style)

  if len(opts.filename) == 0 {
    fmt.eprintln("Missing file name");
    os.exit(1)
  }

  file, ok := os.read_entire_file(opts.filename, context.allocator)
  if ok != os.ERROR_NONE {
    fmt.eprintln("Failed to open ", opts.filename)
    os.exit(1)
  }

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

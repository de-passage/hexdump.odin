#+feature dynamic-literals
package hexdump

import "core:flags"
import "core:fmt"
import "core:io"
import "core:math"
import "core:os"
import "core:sys/posix"
import "core:terminal/ansi"
import "core:unicode"

import "cli"
import c "colors"
import e "elf"

SCRATCH_BUFFER_SIZE :: #config(SCRATCH_BUFFER_SIZE, 1024)

main :: proc() {
  opts, err := cli.parse_arguments(os.args)
  handle_cli_error(err, opts.program_name)

  file, ok := os.read_entire_file(opts.target_file, context.allocator)
  if ok != os.ERROR_NONE {
    fmt.eprintfln("Failed to open '%s'", opts.target_file)
    os.exit(1)
  }
  defer delete(file)

  formatters := new(map[typeid]fmt.User_Formatter)
  defer free(formatters)
  fmt.set_user_formatters(formatters)
  e.register_custom_formatters()

  buf: [SCRATCH_BUFFER_SIZE]u8

  // Should we use color at all?
  output_on_tty := bool(posix.isatty(posix.STDOUT_FILENO))
  no_color_value, _ := os.lookup_env_buf(buf[:], "NO_COLOR")
  no_color := no_color_value != ""

  c.should_use_color =
    !no_color &&
    ((!output_on_tty && opts.color == cli.Argument_Color.always) ||
        (output_on_tty && opts.color != cli.Argument_Color.never))

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

  switch opts.format {
  case .none:
    if opts.range.end > 0 {
      decode_generic_file(file[opts.range.start:min(opts.range.end, u64(len(file)))], opts.width)
    } else {
      decode_generic_file(file, opts.width)
    }
  case .elf:
    handle_elf_decoding_error(e.decode_elf_file(file))
  }
}

fill_spaces :: proc(last_byte: int, target_byte: int, content: string) {
  if (last_byte < target_byte) {
    for i in 0 ..< (target_byte - last_byte) {
      fmt.printf(content)
    }
  }
}

decode_generic_file :: proc(file: []byte, width: int) {
  first_byte := 0

  for first_byte < len(file) {
    last_byte := math.min(first_byte + width, len(file))

    line := file[first_byte:last_byte]

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

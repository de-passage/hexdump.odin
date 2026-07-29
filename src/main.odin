#+feature dynamic-literals
package hexdump

import "core:fmt"
import "core:io"
import "core:os"
import "core:sys/posix"
import "core:terminal/ansi"

import "cli"
import c "colors"
import e "elf"

SCRATCH_BUFFER_SIZE :: #config(SCRATCH_BUFFER_SIZE, 1024)
buf: [SCRATCH_BUFFER_SIZE]u8

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

  setup_colors(opts)

  switch opts.format {
  case .none:
    if opts.range.end > 0 {
      decode_generic_buffer(file[opts.range.start:min(opts.range.end, u64(len(file)))], opts.width)
    } else {
      decode_generic_buffer(file, opts.width)
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

setup_colors :: proc(opts: cli.Options) {
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
}

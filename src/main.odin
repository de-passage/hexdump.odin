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

import c "colors"
import e "elf"

SCRATCH_BUFFER_SIZE :: #config(SCRATCH_BUFFER_SIZE, 1024)

handle_cli_error :: proc(error: Cli_Error, program_name: string) {
  switch err in error {
  case nil:
    return
  case flags.Error:
    switch e in err {
    case flags.Parse_Error:
      fmt.eprintln(e.message)
    case flags.Validation_Error:
      fmt.eprintln(e.message)
    case flags.Help_Request:
      print_usage(program_name)
      os.exit(0)
    case flags.Open_File_Error:
      fmt.eprintfln("Failed to open '%s'", e.filename)
    }
  case Empty_File_Name:
    print_usage(program_name, out = os.stderr)
  case Incompatible_Options:
    fmt.eprintln(err.reason)
  }
  os.exit(1)
}

handle_color_mapping_error :: proc(mapping_error: c.Error) {
  switch parse_error in mapping_error {
  case nil:
    return
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
  }
}

handle_elf_decoding_error :: proc(elf_error: e.Error) {
  switch err in elf_error {
  case nil:
    return
  case e.Invalid_Elf_Endianess:
    fmt.eprintfln("Invalid ELF class: %v", err.value)
  case e.Conversion_Failed:
    fmt.eprintln("Conversion failed")
  case e.Wrong_Magic:
    fmt.eprintln("Wrong magic byte, is this really an ELF file?")
  case e.Header_Too_Small:
    fmt.eprintfln(
      "Header size too small (%i) for %v. Header size should be at least %i",
      err.length,
      err.class,
      err.required,
    )
  case e.Invalid_Elf_Class:
    fmt.eprintfln("Invalid elf class (%i).", err.value)
  }
  os.exit(1)
}

main :: proc() {
  opts, err := parse_arguments()
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

  switch opts.format {
  case File_Format.none:
    if opts.range.end > 0 {
      decode_generic_file(file[opts.range.start:min(opts.range.end, u64(len(file)))], opts.width)
    } else {
      decode_generic_file(file, opts.width)
    }
  case File_Format.elf:
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

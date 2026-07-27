package hexdump

import "core:fmt"
import "core:os"
import "core:flags"
import "core:terminal/ansi"

import c "colors"
import e "elf"
import "cli"

handle_cli_error :: proc(error: cli.Cli_Error, program_name: string) {
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
      cli.print_usage(program_name)
      os.exit(0)
    case flags.Open_File_Error:
      fmt.eprintfln("Failed to open '%s'", e.filename)
    }
  case cli.Empty_File_Name:
    cli.print_usage(program_name, out = os.stderr)
  case cli.Incompatible_Options:
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

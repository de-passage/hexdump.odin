package hexdump

import "core:flags"
import "base:runtime"
import "core:os"
import "core:fmt"

Options :: struct {
  width: int `usage:"Number of bytes to print on a single line`,
  program_name: string `args:"pos=0"`,
  target_file: string `args:"pos=1" usage:"File to analyse"`,
  color: Argument_Color `usage:"Enable color or not"`,
  color_mapping: string `usage:"Customize color"`,
}

Argument_Color :: enum {
  auto,
  never,
  always,
}

print_usage :: proc(program_name: string) {
    fmt.printfln("Usage:\n" +
      "\t%s FILE [--width WIDTH] [--color auto|always|never] [--color_mapping MAPPING]",
      program_name)
}

parse_arguments :: proc() -> (opts : Options, file : []byte) {
  style : flags.Parsing_Style = .Unix

  opts.width = 16
  error := flags.parse(&opts, os.args, style)

  switch e in error {
    case flags.Parse_Error:
      fmt.eprintln(e.message)
      os.exit(1)
    case flags.Validation_Error:
      fmt.eprintln(e.message)
      os.exit(1)
    case flags.Help_Request:
      print_usage(opts.program_name)
      os.exit(0)
    case flags.Open_File_Error:
      fmt.eprintfln("Failed to open '%s'", e.filename)
      os.exit(1)
  }

  if (opts.target_file == "") {
    print_usage(opts.program_name)
    os.exit(1)
  }

  ok : os.Error
  file, ok = os.read_entire_file(opts.target_file, context.allocator)
  if ok != os.ERROR_NONE {
    fmt.eprintfln("Failed to open '%s'", opts.target_file)
    os.exit(1)
  }

  return
}

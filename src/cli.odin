package hexdump

import "core:flags"
import "base:runtime"
import "core:os"
import "core:fmt"

Options :: struct {
  width: int `usage:"Number of bytes to print on a single line`,
  program_name: string `args:"pos=0"`,
  target_file: string `args:"pos=1" usage:"File to analyse"`,
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
      os.exit(0)
    case flags.Open_File_Error:
      fmt.eprintln("Failed to open: ", e.filename)
      os.exit(1)
  }

  ok : os.Error
  file, ok = os.read_entire_file(opts.target_file, context.allocator)
  if ok != os.ERROR_NONE {
    fmt.eprintln("Failed to open ", opts.target_file)
    os.exit(1)
  }

  return
}

package hexdump

import "base:runtime"
import "core:flags"
import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"

Options :: struct {
  width:         int `usage:"Number of bytes to print on a single line`,
  program_name:  string `args:"pos=0"`,
  target_file:   string `args:"pos=1" usage:"File to analyse"`,
  color:         Argument_Color `usage:"Enable color or not"`,
  color_mapping: string `usage:"Customize color"`,
  format:        File_Format `usage:"Output format"`,
  range:         Address_Range `usage:"start:end"`,
}

File_Format :: enum {
  none,
  elf,
}

Argument_Color :: enum {
  auto,
  never,
  always,
}

Address_Range :: struct {
  start: u64,
  end:   u64,
}

print_usage :: proc(program_name: string) {
  fmt.printfln(
    "Usage:\n" + "\t%s FILE [--width WIDTH] [--color auto|always|never] [--color_mapping MAPPING]",
    program_name,
  )
}

parse_arguments :: proc() -> (opts: Options, file: []byte) {
  style: flags.Parsing_Style = .Unix
  flags.register_type_setter(cli_parser)

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

  if opts.range.end != 0 && opts.format != .none {
    fmt.eprintfln("Range is only available for default format")
    os.exit(1)
  }

  ok: os.Error
  file, ok = os.read_entire_file(opts.target_file, context.allocator)
  if ok != os.ERROR_NONE {
    fmt.eprintfln("Failed to open '%s'", opts.target_file)
    os.exit(1)
  }

  return
}

parse_num :: proc(source: string, target: ^u64) -> (ok: bool) {
  if source == "" {
    target^ = 0
    ok = true
  } else {
    target^, ok = strconv.parse_u64(source)
  }
  return
}

parse_range :: proc(range: ^Address_Range, unparsed_value: string) -> (error: string) {
  length := len(unparsed_value)
  delim := strings.index_byte(unparsed_value, ':')
  if (delim < 0) {
    delim = strings.index_byte(unparsed_value, '+')
    if (delim < 0) {
      error = "Expected a range in the form \"start:end\" or \"start+offset\""
      return
    }
  }

  if !parse_num(unparsed_value[:delim], &range.start) {
    error = "Range lower bound is not a number "
    return
  }
  if !parse_num(unparsed_value[delim + 1:], &range.end) {
    error = "Range upper bound is not a number"
    return
  }

  if unparsed_value[delim] == '+' {
    range.end += range.start
  } else if range.end == 0 {
    range.end = max(u64)
  } else if range.end <= range.start {
    error = "Range upper bound should be strictly greater than lower bound"
  }
  return
}

cli_parser :: proc(
  data: rawptr,
  id: typeid,
  unparsed_value: string,
  args_tag: string,
) -> (
  error: string,
  handled: bool,
  alloc_error: runtime.Allocator_Error,
) {
  if id == Address_Range {
    handled = true
    range := cast(^Address_Range)data
    error = parse_range(range, unparsed_value)
    return
  }
  return
}

package cli

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
  section:       Maybe(u64) `usage:"What section in an ELF file"`,
  segment:       Maybe(u64) `usage:"What segment in an ELF file"`,
  dump:          bool `usage:"Show hexdump in ELF decoding mode"`,
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

Cli_Error :: union {
  flags.Error,
  Empty_File_Name,
  Incompatible_Options,
}
Empty_File_Name :: struct {}
Incompatible_Options :: struct {
  reason: string,
}

print_usage :: proc(program_name: string, out: ^os.File = os.stdout) {
  fmt.fprintfln(
    out,
    "Usage:\n" + "\t%s FILE [--width WIDTH] [--color auto|always|never] [--color_mapping MAPPING]",
    program_name,
  )
}

parse_arguments :: proc(args: []string) -> (opts: Options, err: Cli_Error) {
  style: flags.Parsing_Style = .Unix
  flags.register_type_setter(cli_parser)

  opts.width = 16
  parse_err := flags.parse(&opts, args, style)
  if parse_err != nil {
    err = parse_err
    return
  }

  if (opts.target_file == "") {
    err = Empty_File_Name{}
    return
  }

  if opts.format != .none {
    if opts.range.end != 0 {
      err = Incompatible_Options{"--range is only available for default format (--format=none)"}
    }
  }
  if opts.format != .elf {
    if opts.segment != nil {
      err = Incompatible_Options{"--segment is only available for ELF format (--format=elf)"}
    }
    if opts.section != nil {
      err = Incompatible_Options{"--section is only available for ELF format (--format=elf)"}
    }
  }
  if err != nil {
    return
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
  } else if id == Maybe(u64) {
    handled = true
    maybe := cast(^Maybe(u64))data
    ok: bool = ---
    maybe^, ok = strconv.parse_u64(unparsed_value)
    if !ok {
      error = "Failed to parse integer"
    }
    return
  }
  return
}

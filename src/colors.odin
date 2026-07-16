package hexdump

import "core:os"
import "core:terminal/ansi"
import "core:fmt"

should_use_color : bool

Colorable_Type :: enum {
  NONE,
  ASCII,
  SPACE,
  OTHER,
  ZERO,
  FF
}

DEFAULT_COLOR_ZERO :: ansi.FG_COLOR_24_BIT + ";90;90;90"
DEFAULT_COLOR_OTHER :: ansi.FG_COLOR_24_BIT + ";210;210;210"
DEFAULT_COLOR_SPACE :: ansi.FG_COLOR_24_BIT + ";10;200;200"
DEFAULT_COLOR_ASCII :: ansi.FG_COLOR_24_BIT + ";99;168;129"
DEFAULT_COLOR_FF :: ansi.FG_COLOR_24_BIT + ";242;84;10"
DEFAULT_COLOR_ADDRESS :: ansi.FG_COLOR_24_BIT + ";214;197;2"

COLOR_ZERO : string = DEFAULT_COLOR_ZERO
COLOR_OTHER : string = DEFAULT_COLOR_OTHER
COLOR_SPACE : string = DEFAULT_COLOR_SPACE
COLOR_ASCII : string = DEFAULT_COLOR_ASCII
COLOR_FF : string = DEFAULT_COLOR_FF
COLOR_ADDRESS : string = DEFAULT_COLOR_ADDRESS

print_ansi_code :: proc(args:..any, sep := "") {
  if should_use_color {
    fmt.print(..args, sep = "", flush = true)
  }
}

color_mapping_setup :: proc(mapping : string) {
  length := len(mapping)
  start := 0
  for idx := 0; idx < length; idx += 1 {
    if mapping[idx] == '=' {
      key := mapping[start:idx]
      switch key {
        case "z":
          COLOR_ZERO, idx = parse_value(mapping, length, idx + 1)
        case "s":
          COLOR_SPACE, idx = parse_value(mapping, length, idx + 1)
        case "a":
          COLOR_ASCII, idx = parse_value(mapping, length, idx + 1)
        case "o":
          COLOR_OTHER, idx = parse_value(mapping, length, idx + 1)
        case "f":
          COLOR_FF, idx = parse_value(mapping, length, idx + 1)
        case "h":
          COLOR_ADDRESS, idx = parse_value(mapping, length, idx + 1)
        case:
          fmt.eprintfln("Invalid color format key: %s", key)
          os.exit(1)
      }
      start = idx + 1
    }
  }
}

@(private)
parse_value :: proc(mapping : string, length: int, start : int) -> (value: string, new_idx: int) {
  for idx := start ; idx < length; idx += 1 {
    if mapping[idx] == ',' {
      return mapping[start:idx], idx
    }
  }

  return mapping[start:], length
}

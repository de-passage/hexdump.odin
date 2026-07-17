package hexdump

import "core:strconv"
import "core:strings"
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

Color :: struct {
  data : [16]u8,
  value: string,
}

copy_color_string :: proc (color: ^Color, value: string) {
  n := copy(color.data[:], value)
  color.value = string(color.data[:n])
}

set_rgb :: proc(color: ^Color, r, g, b: u8) {
  color.value = fmt.bprintf(color.data[:], "38;2;%i;%i;%i", r, g, b)
}

make_color :: proc(r,g,b:u8) -> Color {
  c : Color
  set_rgb(&c, r, g, b)
  return c
}

DEFAULT_COLOR_ZERO :: ansi.FG_COLOR_24_BIT + ";90;90;90"
DEFAULT_COLOR_OTHER :: ansi.FG_COLOR_24_BIT + ";210;210;210"
DEFAULT_COLOR_SPACE :: ansi.FG_COLOR_24_BIT + ";10;200;200"
DEFAULT_COLOR_ASCII :: ansi.FG_COLOR_24_BIT + ";99;168;129"
DEFAULT_COLOR_FF :: ansi.FG_COLOR_24_BIT + ";242;84;10"
DEFAULT_COLOR_ADDRESS :: ansi.FG_COLOR_24_BIT + ";214;197;2"

COLOR_ZERO : Color
COLOR_OTHER : Color
COLOR_SPACE : Color
COLOR_ASCII : Color
COLOR_FF : Color
COLOR_ADDRESS : Color

init_color :: proc(color: ^Color, value: string) {
  if color.value == "" {
    copy_color_string(color, value)
  }
}

default_color_setup :: proc() {
  init_color(&COLOR_ADDRESS, DEFAULT_COLOR_ADDRESS)
  init_color(&COLOR_ZERO, DEFAULT_COLOR_ZERO)
  init_color(&COLOR_SPACE, DEFAULT_COLOR_SPACE)
  init_color(&COLOR_OTHER, DEFAULT_COLOR_OTHER)
  init_color(&COLOR_ASCII, DEFAULT_COLOR_ASCII)
  init_color(&COLOR_FF, DEFAULT_COLOR_FF)
}

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
          idx = parse_value(&COLOR_ZERO, mapping, length, idx + 1)
        case "s":
          idx = parse_value(&COLOR_SPACE, mapping, length, idx + 1)
        case "a":
          idx = parse_value(&COLOR_ASCII, mapping, length, idx + 1)
        case "o":
          idx = parse_value(&COLOR_OTHER, mapping, length, idx + 1)
        case "f":
          idx = parse_value(&COLOR_FF, mapping, length, idx + 1)
        case "h":
          idx = parse_value(&COLOR_ADDRESS, mapping, length, idx + 1)
        case:
          fmt.eprintfln("Invalid color format key: %s", key)
          os.exit(1)
      }
      start = idx + 1
    }
  }
}

@(private)
parse_value :: proc(color: ^Color, mapping : string, length: int, start : int, allocator := context.allocator) -> (idx: int) {
  color_string : string
  for idx = start; idx < length; idx += 1 {
    if mapping[idx] == ',' {
      color_string = mapping[start:idx];
      break
    }
  }

  if idx == length {
     color_string = mapping[start:];
  }

  if len(color_string) > 0 {

    if color_string[0] == '#' {

      if len(color_string) != 7 {

        fmt.eprintfln("Invalid color format key: %s", color_string)
        os.exit(1)
      }

      r,g,b : int
      ok : bool
      r, ok = strconv.parse_int(color_string[1:3], 16)
      if !ok {
        fmt.eprintfln("Invalid color format key: %s", color_string)
        os.exit(1)
      }

      g, ok = strconv.parse_int(color_string[3:5], 16)
      if !ok {
        fmt.eprintfln("Invalid color format key: %s", color_string)
        os.exit(1)
      }

      b, ok = strconv.parse_int(color_string[5:], 16)
      if !ok {
        fmt.eprintfln("Invalid color format key: %s", color_string)
        os.exit(1)
      }
      set_rgb(color, u8(r), u8(g), u8(b))

    } else {
      switch color_string {
      case "black":
        copy_color_string(color, "30")
      case "red":
        copy_color_string(color, "31")
      case "green":
        copy_color_string(color, "32")
      case "yellow":
        copy_color_string(color, "33")
      case "blue":
        copy_color_string(color, "34")
      case "magenta":
        copy_color_string(color, "35")
      case "cyan":
        copy_color_string(color, "36")
      case "white":
        copy_color_string(color, "37")
      case:
        copy_color_string(color, color_string);

      }
    }
  }

  return
}

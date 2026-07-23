package elf

import "core:fmt"

format_Program_Header_Type :: proc(fi: ^fmt.Info, arg: any, verb: rune) -> bool {
  data := (cast(^Program_Header_Type)arg.data)^
  switch data {
  case .PT_NULL:
    fmt.fmt_string(fi, "NULL", 's')
    return true
  case .PT_LOAD:
    fmt.fmt_string(fi, "LOAD", 's')
    return true
  case .PT_DYNAMIC:
    fmt.fmt_string(fi, "DYNAMIC", 's')
    return true
  case .PT_INTERP:
    fmt.fmt_string(fi, "INTERP", 's')
    return true
  case .PT_NOTE:
    fmt.fmt_string(fi, "NOTE", 's')
    return true
  case .PT_SHLIB:
    fmt.fmt_string(fi, "SHLIB", 's')
    return true
  case .PT_PHDR:
    fmt.fmt_string(fi, "PHDR", 's')
    return true
  case .PT_TLS:
    fmt.fmt_string(fi, "TLS", 's')
    return true
  case .PT_LOOS, .PT_HIOS:
    fmt.fmt_string(fi, "OS", 's')
    return true
  case .PT_LOPROC, .PT_HIPROC:
    fmt.fmt_string(fi, "PROC", 's')
    return true
  case:
    val := int(data)
    if val >= int(Program_Header_Type.PT_LOOS) && val <= int(Program_Header_Type.PT_HIOS) {
      fmt.fmt_string(fi, "[OS]", 's')
    } else if val >= int(Program_Header_Type.PT_LOPROC) && val <= int(Program_Header_Type.PT_HIPROC) {
      fmt.fmt_string(fi, "[PROC]", 's')
    } else {
      fmt.fmt_string(fi, "UNKNOWN", 's')
    }
  }
  return true
}

register_custom_formatters :: proc() {
  fmt.register_user_formatter(typeid_of(Program_Header_Type), format_Program_Header_Type)
}

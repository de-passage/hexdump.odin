package elf

import "core:fmt"

format_Program_Header_Type :: proc(fi: ^fmt.Info, arg: any, verb: rune) {
  switch (cast(^Program_Header_Type)arg.data)^ {
  case .PT_NULL:
    fmt.fmt_string(fi, "Program header table entry unused.", 's')
  case .PT_LOAD:
    fmt.fmt_string(fi, "Loadable segment.", 's')
  case .PT_DYNAMIC:
    fmt.fmt_string(fi, "Dynamic linking information.", 's')
  case .PT_INTERP:
    fmt.fmt_string(fi, "Interpreter information.", 's')
  case .PT_NOTE:
    fmt.fmt_string(fi, "Auxiliary information.", 's')
  case .PT_SHLIB:
    fmt.fmt_string(fi, "Reserved.", 's')
  case .PT_PHDR:
    fmt.fmt_string(fi, "Segment containing program header table itself.", 's')
  case .PT_TLS:
    fmt.fmt_string(fi, "Thread-Local Storage template.", 's')
  case .PT_LOOS..=.PT_HIOS:
    fmt.fmt_string(fi, "Operating system specific.", 's')
  case .PT_LOPROC..=.PT_HIPROC:
    fmt.fmt_string(fi, "Processor specific.", 's')
  }
}

register_custom_formatters :: proc() {
  fmt.register_user_formatter(typeid_of(Program_Header_Type), format_Program_Header_Type)
}

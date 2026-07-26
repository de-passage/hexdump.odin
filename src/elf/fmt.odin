package elf

import "core:fmt"
import "core:reflect"

format_Program_Header_Type :: proc(fi: ^fmt.Info, arg: any, verb: rune) -> bool {
  data := (cast(^Program_Header_Type)arg.data)^
  switch data {
  case .PT_NULL:
    fmt.fmt_string(fi, "NULL", 's')
  case .PT_LOAD:
    fmt.fmt_string(fi, "LOAD", 's')
  case .PT_DYNAMIC:
    fmt.fmt_string(fi, "DYNAMIC", 's')
  case .PT_INTERP:
    fmt.fmt_string(fi, "INTERP", 's')
  case .PT_NOTE:
    fmt.fmt_string(fi, "NOTE", 's')
  case .PT_SHLIB:
    fmt.fmt_string(fi, "SHLIB", 's')
  case .PT_PHDR:
    fmt.fmt_string(fi, "PHDR", 's')
  case .PT_TLS:
    fmt.fmt_string(fi, "TLS", 's')
  case .PT_LOOS, .PT_HIOS:
    fmt.fmt_string(fi, "OS", 's')
  case .PT_LOPROC, .PT_HIPROC:
    fmt.fmt_string(fi, "PROC", 's')
  case:
    val := int(data)
    if val >= int(Program_Header_Type.PT_LOOS) && val <= int(Program_Header_Type.PT_HIOS) {
      fmt.fmt_string(fi, "[OS]", 's')
    } else if val >= int(Program_Header_Type.PT_LOPROC) &&
       val <= int(Program_Header_Type.PT_HIPROC) {
      fmt.fmt_string(fi, "[PROC]", 's')
    } else {
      fmt.fmt_string(fi, "UNKNOWN", 's')
    }
  }
  return true
}

format_Section_Header_Flags :: proc(fi: ^fmt.Info, arg: any, verb: rune) -> bool {
  data := (cast(^Section_Header_Flags)arg.data)^
  first := true
  for v in reflect.enum_fields_zipped(Section_Header_Flags) {

    if reflect.Type_Info_Enum_Value(data) & v.value == v.value {
      if !first {
        fmt.fmt_string(fi, ", ", 's')
      } else {
        first = false
      }
      fmt.fmt_string(fi, v.name[4:], 's')
    }
  }
  if first {
    fmt.fmt_string(fi, "NONE", 's')
  }
  return true
}

format_Section_Header_Type :: proc(fi: ^fmt.Info, arg: any, verb: rune) -> bool {
  data := (cast(^Section_Header_Type)arg.data)^
  switch data {
  case .SHT_NULL:
    // Section header table entry unused
    fmt.fmt_string(fi, "NULL", 's')
  case .SHT_PROGBITS:
    // Program data
    fmt.fmt_string(fi, "PROGBITS", 's')
  case .SHT_SYMTAB:
    // Symbol table
    fmt.fmt_string(fi, "SYMTAB", 's')
  case .SHT_STRTAB:
    // String table
    fmt.fmt_string(fi, "STRTAB", 's')
  case .SHT_RELA:
    // Relocation entries with addends
    fmt.fmt_string(fi, "RELA", 's')
  case .SHT_HASH:
    // Symbol hash table
    fmt.fmt_string(fi, "HASH", 's')
  case .SHT_DYNAMIC:
    // Dynamic linking information
    fmt.fmt_string(fi, "DYNAMIC", 's')
  case .SHT_NOTE:
    // Notes
    fmt.fmt_string(fi, "NOTE", 's')
  case .SHT_NOBITS:
    // Program space with no data (bss)
    fmt.fmt_string(fi, "NOBITS", 's')
  case .SHT_REL:
    // Relocation entries, no addends
    fmt.fmt_string(fi, "REL", 's')
  case .SHT_SHLIB:
    // Reserved
    fmt.fmt_string(fi, "SHLIB", 's')
  case .SHT_DYNSYM:
    // Dynamic linker symbol table
    fmt.fmt_string(fi, "DYNSYM", 's')
  case .SHT_INIT_ARRAY:
    // Array of constructors
    fmt.fmt_string(fi, "INIT_ARRAY", 's')
  case .SHT_FINI_ARRAY:
    // Array of destructors
    fmt.fmt_string(fi, "FINI_ARRAY", 's')
  case .SHT_PREINIT_ARRAY:
    // Array of pre-constructors
    fmt.fmt_string(fi, "PREINIT_ARRAY", 's')
  case .SHT_GROUP:
    // Section group
    fmt.fmt_string(fi, "GROUP", 's')
  case .SHT_SYMTAB_SHNDX:
    // Extended section indices
    fmt.fmt_string(fi, "SYMTAB_SHNDX", 's')
  case .SHT_NUM:
    // Number of defined types.
    fmt.fmt_string(fi, "NUM", 's')
  case .SHT_LOOS:
    // Start OS-specific.
    fmt.fmt_string(fi, "OS", 's')
  case:
    if data > .SHT_LOOS {
      fmt.fmt_string(fi, "OS", 's')
    } else {
      fmt.fmt_string(fi, "UNKNOWN", 's')
    }
  }
  return true
}

register_custom_formatters :: proc() {
  fmt.register_user_formatter(typeid_of(Program_Header_Type), format_Program_Header_Type)
  fmt.register_user_formatter(typeid_of(Section_Header_Flags), format_Section_Header_Flags)
  fmt.register_user_formatter(typeid_of(Section_Header_Type), format_Section_Header_Type)
}

package hexdump

import "core:fmt"
import "core:math"
import "core:terminal/ansi"
import "core:unicode"

import c "colors"
import e "elf"

Error :: union {
  Invalid_Section,
  e.Error,
}
Invalid_Section :: struct {
  requested: u64,
  max:       u64,
}

decode_generic_buffer :: proc(buffer: []byte, width: int) {
  first_byte := 0

  for first_byte < len(buffer) {
    last_byte := math.min(first_byte + width, len(buffer))

    line := buffer[first_byte:last_byte]

    c.print_ansi_code(ansi.CSI, c.COLOR_ADDRESS.value, ansi.SGR)
    fmt.printf("%08X ", first_byte)
    last := c.Colorable_Type.NONE
    for char in line {
      last = c.print_character_colored(char, last, proc(char: byte) {
        fmt.printf("%02X ", char)
      })
    }
    fill_spaces(last_byte, first_byte + width, "   ")

    for char in line {
      last = c.print_character_colored(char, last, proc(char: byte) {
        if char < unicode.MAX_ASCII &&
           unicode.is_print(rune(char)) &&
           !unicode.is_space(rune(char)) {
          fmt.print(rune(char))
        } else {
          fmt.print('.')
        }
      })
    }
    fill_spaces(last_byte, first_byte + width, " ")

    fmt.println(ansi.CSI + ansi.RESET + ansi.SGR)

    first_byte += width
  }
}

show_program_header :: proc(
  file: []byte,
  header: e.Elf_Header,
  program_header: e.Program_Header,
) -> (
  err: e.Error,
) {

  fmt.println("\tType:", program_header.type)
  fmt.println("\tFlags:", program_header.flags)
  fmt.printfln(
    "\tFile offset: 0x%08X\tsize: 0x%08X",
    program_header.offset,
    program_header.file_segment_size,
  )
  fmt.printfln(
    "\tMem  offset: 0x%08X\tsize: 0x%08X",
    program_header.virtual_address,
    program_header.memory_segment_size,
  )
  fmt.printfln("\tAlignment: 0x%X", program_header.alignment)
  if program_header.type == .PT_INTERP {
    start := program_header.offset
    end := start + program_header.file_segment_size - 1 // 0-delimited string
    fmt.printfln("\t%s", file[start:end])
  }

  return
}

show_elf_header :: proc(header: e.Elf_Header) {
  fmt.println("Header content:")
  fmt.println("\tElf:", header.class)
  fmt.println("\tType:", header.type)
  fmt.println("\tEndianness:", header.endianness)
  fmt.println("\tArch:", header.machine)
  fmt.println("\tABI:", header.abi)
  fmt.println("\tSize:", header.size)
  fmt.printfln("\tEntry point: 0x%08X", header.entry_point)
  fmt.printfln("\tProgram Header: 0x%08X", header.program_header_offset)
  fmt.println("\t\tProgram Header Size:", header.program_header_size)
  fmt.println("\t\tProgram Header Table Size:", header.program_header_table_size)
  fmt.printfln("\tSection Header: 0x%08X", header.section_header_offset)
  fmt.println("\t\tProgram Section Size:", header.section_header_size)
  fmt.println("\t\tProgram Section Table Size:", header.section_header_table_size)
  fmt.println("\t\tSection Name Index:", header.section_name_index)
  fmt.printfln("\tFlags: %X", header.flags)
}

show_section_header :: proc(section_header: e.Section_Header, section_name_strings: []byte) {
  fmt.printf("\tName offset: 0x%X", section_header.name)
  section_name := find_section_name(section_name_strings, section_header.name)
  if section_name != "" {
    fmt.printfln(" (%s)", section_name)
  } else {
    fmt.println()
  }
  fmt.println("\tType:", section_header.type)
  fmt.println("\tFlags:", section_header.flags)
  fmt.printfln("\tMemory Address: 0x%08X", section_header.virtual_address)
  fmt.printfln("\tFile Address: 0x%08X", section_header.file_offset)
  fmt.printfln("\tSize: 0x%X", section_header.size)
  fmt.printfln("\tLink: 0x%X", section_header.link)
  fmt.printfln("\tInfo: 0x%X", section_header.info)
  fmt.printfln("\tAlignment: 0x%X", section_header.alignment)
  fmt.printfln("\tEntry size: 0x%X", section_header.entry_size)
}

Should_Dump :: struct {
  width: int,
}

decode_elf_file :: proc(file: []byte, dump: Maybe(Should_Dump) = nil) -> (err: e.Error) {
  header := e.decode_elf_header(file) or_return

  show_elf_header(header)
  dump_if_needed(file[:header.size], dump)
  fmt.println()

  start_of_program_header := header.program_header_offset

  for x in 0 ..< header.program_header_table_size {

    fmt.printfln("Segment [%i]", x)
    program_header := e.decode_program_header(
      file[start_of_program_header:],
      header.endianness,
      header.class,
    ) or_return
    show_program_header(file, header, program_header)
    dump_if_needed(
      file[start_of_program_header:start_of_program_header + u64(header.program_header_size)],
      dump,
    )

    start_of_program_header += u64(header.program_header_size)
  }
  fmt.println()

  start_of_sections_table := header.section_header_offset

  section_names := e.decode_section_header(
    file[start_of_sections_table +
    u64(header.section_header_size) * u64(header.section_name_index):],
    header.endianness,
    header.class,
  ) or_return


  section_name_strings := file[section_names.file_offset:section_names.file_offset +
  section_names.size]

  for x in 0 ..< header.section_header_table_size {
    section_header := e.decode_section_header(
      file[start_of_sections_table:],
      header.endianness,
      header.class,
    ) or_return

    fmt.printfln("Section [%i]", x)
    show_section_header(section_header, section_name_strings)
    dump_if_needed(
      file[start_of_sections_table:start_of_sections_table + u64(header.section_header_size)],
      dump,
    )

    start_of_sections_table += u64(header.section_header_size)
  }
  fmt.println()

  return
}

decode_single_section_header :: proc(
  file: []byte,
  section: u64,
  dump: Maybe(Should_Dump),
) -> (
  err: e.Error,
) {
  header := e.decode_elf_header(file) or_return

  section_bytes := e.slice_section_header(header, section, file)
  section_name_strings := e.slice_section_header(header, u64(header.section_name_index), file)
  section_header := e.decode_section_header(section_bytes, header.endianness, header.class) or_return

  show_section_header(section_header, section_name_strings)
  dump_if_needed(section_bytes, dump)

  return
}

dump_if_needed :: proc(file: []byte, dump: Maybe(Should_Dump)) {
  if dump != nil {
    decode_generic_buffer(file, dump.?.width)
  }
}

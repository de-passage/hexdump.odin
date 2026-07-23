package elf

import "core:encoding/endian"
import "core:fmt"
import "core:slice"

decode_elf_file :: proc(file: []byte) -> (err: Error) {
  header: Elf_Header = ---
  header, err = decode_elf_header(file)

  switch e in err {
  case Wrong_Magic, Header_Too_Small, Invalid_Elf_Endianess, Invalid_Elf_Class, Conversion_Failed:
    return
  case None:
  }
  // do something else

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
  fmt.println()

  start_of_program_header := header.program_header_offset

  for x in 0 ..< header.program_header_table_size {
    program_header: Program_Header = ---
    program_header, err = decode_program_header(
      file[start_of_program_header:],
      header.endianness,
      header.class,
    )

    switch e in err {
    case Wrong_Magic,
         Header_Too_Small,
         Invalid_Elf_Endianess,
         Invalid_Elf_Class,
         Conversion_Failed:
      return
    case None:
    }

    fmt.printfln("Segment [%i]", x)
    fmt.println("Type:", program_header.type)

    start_of_program_header += u64(header.program_header_size)
  }

  return None{}
}

@(private)
decode_field :: proc(
  $source: typeid,
  buffer: []byte,
  fill: ^$T,
  offset: ^int,
  endianness: endian.Byte_Order,
  err: ^Error,
) -> (
  ok: bool,
) {
  value: source = ---
  when source == u16 {
    value, ok = endian.get_u16(buffer[offset^:offset^ + 2], endianness)
  } else when source == u32 {
    value, ok = endian.get_u32(buffer[offset^:offset^ + 4], endianness)
  } else when source == u64 {
    value, ok = endian.get_u64(buffer[offset^:offset^ + 8], endianness)
  }
  if !ok {
    err^ = Conversion_Failed{}
    return
  }
  when source != T {
    fill^ = T(value)
  } else {
    fill^ = value
  }
  offset^ += size_of(source)

  return
}

decode_section_header :: proc(
  file: []byte,
  byte_order: endian.Byte_Order,
  class: Elf_Class,
) -> (
  header: Section_Header,
  err: Error,
) {
  length := len(file)
  if class == .Bit_32 && length < 0x28 {
    err = Header_Too_Small{length, .Bit_32}
    return
  } else if length < 0x40 {
    err = Header_Too_Small{length, .Bit_64}
  }
  offset := 0

  if !decode_field(u32, file, &header.name, &offset, byte_order, &err) {
    return
  }
  if !decode_field(u32, file, &header.type, &offset, byte_order, &err) {
    return
  }

  #partial switch class {
  case .Bit_32:
    if !decode_field(u32, file, &header.flags, &offset, byte_order, &err) {
      return
    }
    if !decode_field(u32, file, &header.virtual_address, &offset, byte_order, &err) {
      return
    }
    if !decode_field(u32, file, &header.file_offset, &offset, byte_order, &err) {
      return
    }
    if !decode_field(u32, file, &header.size, &offset, byte_order, &err) {
      return
    }
  case .Bit_64:
    if !decode_field(u64, file, &header.flags, &offset, byte_order, &err) {
      return
    }
    if !decode_field(u64, file, &header.virtual_address, &offset, byte_order, &err) {
      return
    }
    if !decode_field(u64, file, &header.file_offset, &offset, byte_order, &err) {
      return
    }
    if !decode_field(u64, file, &header.size, &offset, byte_order, &err) {
      return
    }
  }

  if !decode_field(u32, file, &header.link, &offset, byte_order, &err) {
    return
  }
  if !decode_field(u32, file, &header.info, &offset, byte_order, &err) {
    return
  }

  #partial switch class {
  case .Bit_32:
    if !decode_field(u32, file, &header.alignment, &offset, byte_order, &err) {
      return
    }
    if !decode_field(u32, file, &header.entry_size, &offset, byte_order, &err) {
      return
    }
  case .Bit_64:
    if !decode_field(u64, file, &header.alignment, &offset, byte_order, &err) {
      return
    }
    if !decode_field(u64, file, &header.entry_size, &offset, byte_order, &err) {
      return
    }
  }

  assert((class == .Bit_32 && offset == 0x28) || offset == 0x40)
  return
}

decode_program_header :: proc(
  file: []byte,
  byte_order: endian.Byte_Order,
  class: Elf_Class,
) -> (
  header: Program_Header,
  err: Error,
) {

  length := len(file)
  if class == .Bit_32 && length < 0x20 {
    err = Header_Too_Small{length, .Bit_32}
    return
  } else if length < 0x38 {
    err = Header_Too_Small{length, .Bit_64}
  }
  offset := 0
  if !decode_field(u32, file, &header.type, &offset, byte_order, &err) {
    return
  }

  #partial switch class {
  case .Bit_32:
    if !decode_field(u32, file, &header.offset, &offset, byte_order, &err) {
      return
    }
    if !decode_field(u32, file, &header.virtual_address, &offset, byte_order, &err) {
      return
    }
    if !decode_field(u32, file, &header.physical_address, &offset, byte_order, &err) {
      return
    }
    if !decode_field(u32, file, &header.file_segment_size, &offset, byte_order, &err) {
      return
    }
    if !decode_field(u32, file, &header.memory_segment_size, &offset, byte_order, &err) {
      return
    }
    if !decode_field(u32, file, &header.flags, &offset, byte_order, &err) {
      return
    }
    if !decode_field(u32, file, &header.alignment, &offset, byte_order, &err) {
      return
    }
  case .Bit_64:
    if !decode_field(u32, file, &header.flags, &offset, byte_order, &err) {
      return
    }
    if !decode_field(u64, file, &header.offset, &offset, byte_order, &err) {
      return
    }
    if !decode_field(u64, file, &header.virtual_address, &offset, byte_order, &err) {
      return
    }
    if !decode_field(u64, file, &header.physical_address, &offset, byte_order, &err) {
      return
    }
    if !decode_field(u64, file, &header.file_segment_size, &offset, byte_order, &err) {
      return
    }
    if !decode_field(u64, file, &header.memory_segment_size, &offset, byte_order, &err) {
      return
    }
    if !decode_field(u64, file, &header.alignment, &offset, byte_order, &err) {
      return
    }
  }

  assert((class == .Bit_32 && offset == 0x20) || offset == 0x38)
  return
}

decode_elf_header :: proc(file: []byte) -> (header: Elf_Header, err: Error) {
  length := len(file)
  if length < 4 || !slice.equal(file[0:4], ([]byte)({0x7f, 'E', 'L', 'F'})) {
    err = Wrong_Magic{}
    return
  }

  if length < 5 {
    err = Header_Too_Small{length, .Invalid}
    return
  }

  header.class = Elf_Class(file[0x04])

  switch header.class {
  case .Bit_64:
    if length < 64 {
      err = Header_Too_Small{length, .Bit_64}
      return
    }
  case .Bit_32:
    if header.class == Elf_Class.Bit_64 && length < 52 {
      err = Header_Too_Small{length, .Bit_32}
      return
    }

  case .Invalid:
    err = Invalid_Elf_Class{u8(header.class)}
    return
  case:
    err = Invalid_Elf_Class{u8(header.class)}
    return
  }

  switch file[0x05] {
  case 1:
    header.endianness = .Little
  case 2:
    header.endianness = .Big
  case:
    err = Invalid_Elf_Endianess{file[0x05]}
    return
  }

  header.version = file[0x06]
  header.abi = Elf_ABI(file[0x07])
  header.abi_version = file[0x08]

  offset: int = 0x10
  if !decode_field(u16, file, &header.type, &offset, header.endianness, &err) {
    return
  }
  if !decode_field(u16, file, &header.machine, &offset, header.endianness, &err) {
    return
  }
  if !decode_field(u32, file, &header.elf_version, &offset, header.endianness, &err) {
    return
  }

  #partial switch header.class {
  case .Bit_32:
    if !decode_field(u32, file, &header.entry_point, &offset, header.endianness, &err) {
      return
    }

    if !decode_field(u32, file, &header.program_header_offset, &offset, header.endianness, &err) {
      return
    }

    if !decode_field(u32, file, &header.section_header_offset, &offset, header.endianness, &err) {
      return
    }

  case .Bit_64:
    if !decode_field(u64, file, &header.entry_point, &offset, header.endianness, &err) {
      return
    }

    if !decode_field(u64, file, &header.program_header_offset, &offset, header.endianness, &err) {
      return
    }

    if !decode_field(u64, file, &header.section_header_offset, &offset, header.endianness, &err) {
      return
    }
  }

  if !decode_field(u32, file, &header.flags, &offset, header.endianness, &err) {
    return
  }

  if !decode_field(u16, file, &header.size, &offset, header.endianness, &err) {
    return
  }

  if !decode_field(u16, file, &header.program_header_size, &offset, header.endianness, &err) {
    return
  }

  if !decode_field(
    u16,
    file,
    &header.program_header_table_size,
    &offset,
    header.endianness,
    &err,
  ) {
    return
  }

  if !decode_field(u16, file, &header.section_header_size, &offset, header.endianness, &err) {
    return
  }

  if !decode_field(
    u16,
    file,
    &header.section_header_table_size,
    &offset,
    header.endianness,
    &err,
  ) {
    return
  }

  if !decode_field(u16, file, &header.section_name_index, &offset, header.endianness, &err) {
    return
  }

  assert((header.class == .Bit_32 && offset == 0x34) || offset == 0x40)

  return
}

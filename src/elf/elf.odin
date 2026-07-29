package elf

import "core:encoding/endian"
import "core:slice"

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
    err = Header_Too_Small{length, .Bit_32, 0x28}
    return
  } else if length < 0x40 {
    err = Header_Too_Small{length, .Bit_64, 0x40}
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
    err = Header_Too_Small{length, .Bit_32, 0x20}
    return
  } else if length < 0x38 {
    err = Header_Too_Small{length, .Bit_64, 0x38}
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
    err = Header_Too_Small{length, .Invalid, 5}
    return
  }

  header.class = Elf_Class(file[0x04])

  switch header.class {
  case .Bit_64:
    if length < 64 {
      err = Header_Too_Small{length, .Bit_64, 64}
      return
    }
  case .Bit_32:
    if header.class == Elf_Class.Bit_64 && length < 52 {
      err = Header_Too_Small{length, .Bit_32, 52}
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

compute_section_header_boundaries :: proc(
  header: Elf_Header,
  section_index: u64,
) -> (
  start: u64,
  end: u64,
) {
  start = header.section_header_offset + u64(header.section_header_size) * section_index
  end = start + u64(header.section_header_size)
  return
}

slice_section_header :: proc(
  header: Elf_Header,
  section_index: u64,
  file: []byte,
) -> (
  section: []byte,
) {
  start, end := compute_section_header_boundaries(header, section_index)
  return file[start:end]
}

compute_program_header_boundaries :: proc(
  header: Elf_Header,
  segment_index: u64,
) -> (
  start: u64,
  end: u64,
) {
  start = header.program_header_offset + u64(header.program_header_size) * segment_index
  end = start + u64(header.section_header_size)
  return
}

slice_program_header :: proc(
  header: Elf_Header,
  segment_index: u64,
  file: []byte,
) -> (
  section: []byte,
) {
  start, end := compute_program_header_boundaries(header, segment_index)
  return file[start:end]
}

slice_section :: proc(section_header: Section_Header, file: []byte) -> (section: []byte) {
  section = file[section_header.file_offset:section_header.file_offset + section_header.size]
  return
}

slice_segment :: proc(program_header: Program_Header, file: []byte) -> (section: []byte) {
  section = file[program_header.offset:program_header.offset + program_header.file_segment_size]
  return
}

package elf

None :: struct {}
Wrong_Magic :: struct {}

Header_Too_Small :: struct {
  length: int,
  class:  Elf_Class,
}

Invalid_Value :: struct {
  value: u8,
}

Invalid_Elf_Class :: distinct Invalid_Value
Invalid_Elf_Endianess :: distinct Invalid_Value

Error :: union {
  None,
  Wrong_Magic,
  Header_Too_Small,
  Invalid_Elf_Class,
  Invalid_Elf_Endianess,
  Conversion_Failed,
}

Conversion_Failed :: struct {}

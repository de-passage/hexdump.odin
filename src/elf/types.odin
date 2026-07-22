package elf

import "core:encoding/endian"

Elf_Header :: struct {
  class:                     Elf_Class,
  endianness:                endian.Byte_Order,
  version:                   u8,
  abi:                       Elf_ABI,
  abi_version:               u8,
  type:                      Elf_Type,
  machine:                   Elf_Arch,
  elf_version:               u32,
  entry_point:               u64,
  program_header_offset:     u64,
  section_header_offset:     u64,
  flags:                     u32,
  size:                      u32,
  program_header_size:       u16,
  program_header_table_size: u16,
  section_header_size:       u16,
  section_header_table_size: u16,
  section_name_index:        u16,
}

Elf_Class :: enum u8 {
  Invalid = 0,
  Bit_32  = 1,
  Bit_64  = 2,
}

Elf_Type :: enum u16 {
  ET_NONE   = 0x00, //Unknown.
  ET_REL    = 0x01, //Relocatable file.
  ET_EXEC   = 0x02, //Executable file.
  ET_DYN    = 0x03, //Shared object.
  ET_CORE   = 0x04, //Core file.
  ET_LOOS   = 0xFE00, // Reserved inclusive range. Operating system specific.
  ET_HIOS   = 0xFEFF, // End of range
  ET_LOPROC = 0xFF00, //Reserved inclusive range. Processor specific.
  ET_HIPROC = 0xFFFF, // End of range
}

Elf_Arch :: enum u16 {
  None                               = 0x00, // No specific instruction set
  AT_T_WE_32100                      = 0x01, // AT&T WE 32100
  SPARC                              = 0x02, // SPARC
  x86                                = 0x03, // x86
  Motorola_68000_M68k                = 0x04, // Motorola 68000 (M68k)
  Motorola_88000_M88k                = 0x05, // Motorola 88000 (M88k)
  Intel_MCU                          = 0x06, // Intel MCU
  Intel_80860                        = 0x07, // Intel 80860
  MIPS                               = 0x08, // MIPS
  IBM_System_370                     = 0x09, // IBM System/370
  MIPS_RS3000_Little_endian          = 0x0A, // MIPS RS3000 Little-endian
  Reserved_Range_Start_1             = 0x0B, // Reserved for future use
  Reserved_Range_End_1               = 0x0E, // Reserved for future use
  Hewlett_Packard_PA_RISC            = 0x0F, // Hewlett-Packard PA-RISC
  Intel_80960                        = 0x13, // Intel 80960
  PowerPC                            = 0x14, // PowerPC
  PowerPC_64_bit                     = 0x15, // PowerPC (64-bit)
  S390                               = 0x16, // S390, including S390x
  IBM_SPU_SPC                        = 0x17, // IBM SPU/SPC
  Reserved_Range_Start_2             = 0x18, // Reserved for future use
  Reserved_Range_End_2               = 0x23, // Reserved for future use
  NEC_V800                           = 0x24, // NEC V800
  Fujitsu_FR20                       = 0x25, // Fujitsu FR20
  TRW_RH_32                          = 0x26, // TRW RH-32
  Motorola_RCE                       = 0x27, // Motorola RCE
  Arm                                = 0x28, // Arm (up to Armv7/AArch32)
  Digital_Alpha                      = 0x29, // Digital Alpha
  SuperH                             = 0x2A, // SuperH
  SPARC_Version_9                    = 0x2B, // SPARC Version 9
  Siemens_TriCore                    = 0x2C, // Siemens TriCore embedded processor
  Argonaut_RISC_Core                 = 0x2D, // Argonaut RISC Core
  Hitachi_H8_300                     = 0x2E, // Hitachi H8/300
  Hitachi_H8_300H                    = 0x2F, // Hitachi H8/300H
  Hitachi_H8S                        = 0x30, // Hitachi H8S
  Hitachi_H8_500                     = 0x31, // Hitachi H8/500
  IA_64                              = 0x32, // IA-64
  Stanford_MIPS_X                    = 0x33, // Stanford MIPS-X
  Motorola_ColdFire                  = 0x34, // Motorola ColdFire
  Motorola_M68HC12                   = 0x35, // Motorola M68HC12
  Fujitsu_MMA_Multimedia_Accelerator = 0x36, // Fujitsu MMA Multimedia Accelerator
  Siemens_PCP                        = 0x37, // Siemens PCP
  Sony_nCPU                          = 0x38, // Sony nCPU embedded RISC processor
  Denso_NDR1                         = 0x39, // Denso NDR1 microprocessor
  Motorola_Star_Core                 = 0x3A, // Motorola Star*Core processor
  Toyota_ME16                        = 0x3B, // Toyota ME16 processor
  STMicroelectronics_ST100           = 0x3C, // STMicroelectronics ST100 processor
  Advanced_Logic_Corp_TinyJ          = 0x3D, // Advanced Logic Corp. TinyJ embedded processor family
  AMD_x86_64                         = 0x3E, // AMD x86-64
  Sony_DSP                           = 0x3F, // Sony DSP Processor
  Digital_Equipment_Corp_PDP_10      = 0x40, // Digital Equipment Corp. PDP-10
  Digital_Equipment_Corp_PDP_11      = 0x41, // Digital Equipment Corp. PDP-11
  Siemens_FX66                       = 0x42, // Siemens FX66 microcontroller
  STMicroelectronics_ST9             = 0x43, // STMicroelectronics ST9+ 8/16-bit microcontroller
  STMicroelectronics_ST7             = 0x44, // STMicroelectronics ST7 8-bit microcontroller
  Motorola_MC68HC16                  = 0x45, // Motorola MC68HC16 Microcontroller
  Motorola_MC68HC11                  = 0x46, // Motorola MC68HC11 Microcontroller
  Motorola_MC68HC08                  = 0x47, // Motorola MC68HC08 Microcontroller
  Motorola_MC68HC05                  = 0x48, // Motorola MC68HC05 Microcontroller
  Silicon_Graphics_SVx               = 0x49, // Silicon Graphics SVx
  STMicroelectronics_ST19            = 0x4A, // STMicroelectronics ST19 8-bit microcontroller
  Digital_VAX                        = 0x4B, // Digital VAX
  Axis_Communications_32             = 0x4C, // Axis Communications 32-bit embedded processor
  Infineon_Technologies_32           = 0x4D, // Infineon Technologies 32-bit embedded processor
  Element_14_64                      = 0x4E, // Element 14 64-bit DSP Processor
  LSI_Logic_16                       = 0x4F, // LSI Logic 16-bit DSP Processor
  TMS320C6000_Family                 = 0x8C, // TMS320C6000 Family
  MCST_Elbrus_e2k                    = 0xAF, // MCST Elbrus e2k
  Arm_64                             = 0xB7, // Arm 64-bits (Armv8/AArch64)
  Zilog_Z80                          = 0xDC, // Zilog Z80
  RISC_V                             = 0xF3, // RISC-V
  Berkeley_Packet_Filter             = 0xF7, // Berkeley Packet Filter
  WDC_65C816                         = 0x101, // WDC 65C816
  LoongArch                          = 0x102, // LoongArch
}

Elf_ABI :: enum u8 {
  System_V                     = 0x00, // System V
  HP_UX                        = 0x01, // HP-UX
  NetBSD                       = 0x02, // NetBSD
  Linux                        = 0x03, // Linux
  GNU_Hurd                     = 0x04, // GNU Hurd
  Solaris                      = 0x06, // Solaris
  AIX_Monterey                 = 0x07, // AIX (Monterey)
  IRIX                         = 0x08, // IRIX
  FreeBSD                      = 0x09, // FreeBSD
  Tru64                        = 0x0A, // Tru64
  Novell_Modesto               = 0x0B, // Novell Modesto
  OpenBSD                      = 0x0C, // OpenBSD
  OpenVMS                      = 0x0D, // OpenVMS
  NonStop_Kernel               = 0x0E, // NonStop Kernel
  AROS                         = 0x0F, // AROS
  FenixOS                      = 0x10, // FenixOS
  Nuxi_CloudABI                = 0x11, // Nuxi CloudABI
  Stratus_Technologies_OpenVOS = 0x12, // Stratus Technologies OpenVOS
}

Program_Header :: struct {

}

package cli

import "core:testing"

@(test)
error_when_no_filename_provided :: proc(t: ^testing.T) {
  opts, err := parse_arguments({"test"})
  testing.expect_value(t, err, Empty_File_Name{})

  opts, err = parse_arguments({"test --format=elf"})
  testing.expect_value(t, err, Empty_File_Name{})
}

@(test)
valid_cases :: proc(t: ^testing.T) {
  opts, err := parse_arguments({"test", "filename"})
  testing.expect_value(t, err, nil)
  testing.expect_value(t, opts.program_name, "test")
  testing.expect_value(t, opts.target_file, "filename")
}

@(test)
single_section :: proc(t: ^testing.T) {
  opts, err := parse_arguments({"test", "filename", "--format=elf", "--section=3"})

  testing.expect_value(t, err, nil)
  testing.expect_value(t, opts.section, 3)
}

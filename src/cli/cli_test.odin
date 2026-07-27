package cli

import "core:testing"

@(test)
error_when_no_filename_provided :: proc(t: ^testing.T) {
  opts, err := parse_arguments({"test"})
  testing.expect(t, err == Empty_File_Name{})

  opts, err = parse_arguments({"test --format=elf"})
  testing.expect(t, err == Empty_File_Name{})
}

@(test)
valid_cases :: proc(t: ^testing.T) {
  opts, err := parse_arguments({"test", "filename"})
  testing.expect(t, err == nil)
  testing.expect(t, opts.program_name == "test")
  testing.expect(t, opts.target_file == "filename")
}



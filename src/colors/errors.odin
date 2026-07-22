package colors

Error :: union {
  None,
  Parse_Error,
}

None :: struct {}

Parse_Error_Detail :: union {
  Invalid_Key,
  Invalid_Value,
  Unexpected_Character,
  Unexpected_End_Of_String,
}

Parse_Error :: struct {
  full_string: string,
  location:    int,
  detail:      Parse_Error_Detail,
}

Invalid_Key :: struct {
  key: string,
}

Invalid_Value_Detail :: union {
  Invalid_Hex_Length,
  Invalid_Hex_Number,
  Unexpected_Character,
  Empty_Value,
}

Empty_Value :: struct {}

Invalid_Hex_Length :: struct {
  length: int,
}

Invalid_Hex_Number :: struct {
  number: string,
}

Invalid_Value :: struct {
  key:    string,
  reason: Invalid_Value_Detail,
}

Unexpected_Character :: struct {
  char: rune,
}

Unexpected_End_Of_String :: struct {}

///|
pub const QOI_MAGIC : Bytes = b"qoif"

///|
pub const QOI_PADDING : Bytes = b"\x00\x00\x00\x00\x00\x00\x00\x01"

///|
pub const QOI_OP_INDEX = 0b00000000 // 0x00 - 0x3f

///|
pub const QOI_OP_DIFF = 0b01000000 // 0x40 - 0x7f

///|
pub const QOI_OP_LUMA = 0b10000000 // 0x80 - 0xbf

///|
pub const QOI_OP_RUN = 0b11000000 // 0xc0 - 0xfd

///|
pub const QOI_OP_RGB = 0xfe // 0xfe

///|
pub const QOI_OP_RGBA = 0xff // 0xff

///|
pub const QOI_MASK_2 = 0b11000000 // 0xc0

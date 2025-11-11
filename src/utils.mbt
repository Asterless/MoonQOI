// Utility functions (big-endian read/write, bytes compare)

///|
/// Read 32-bit big-endian integer from bytes
pub fn read_be32(bytes : Bytes, offset : Int) -> Int {
  let b0 = bytes[offset].to_int()
  let b1 = bytes[offset + 1].to_int()
  let b2 = bytes[offset + 2].to_int()
  let b3 = bytes[offset + 3].to_int()
  (b0 << 24) | (b1 << 16) | (b2 << 8) | b3
}

///|
/// Write 32-bit big-endian integer to bytes buffer
pub fn write_be32(buffer : FixedArray[Byte], offset : Int, value : Int) -> Unit {
  buffer[offset] = (value >> 24).to_byte()
  buffer[offset + 1] = (value >> 16).to_byte()
  buffer[offset + 2] = (value >> 8).to_byte()
  buffer[offset + 3] = value.to_byte()
}

///|
/// Check if two byte slices are equal
pub fn bytes_eq(
  a : Bytes,
  a_start : Int,
  b : Bytes,
  b_start : Int,
  len : Int,
) -> Bool {
  for i in 0..<len {
    if a[a_start + i] != b[b_start + i] {
      break false
    }
  } else {
    true
  }
}

///|
/// Hash function for pixel indexing
pub fn qoi_color_hash(pixel : Pixel) -> Int {
  let r = pixel.r.to_int()
  let g = pixel.g.to_int()
  let b = pixel.b.to_int()
  let a = pixel.a.to_int()
  (r * 3 + g * 5 + b * 7 + a * 11) % 64
}

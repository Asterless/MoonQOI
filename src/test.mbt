// QOI Types and Codec Tests - Focused on testable functionality

///|
test "pixel creation and basic operations" {
  let pixel = Pixel::new(b'\x42', b'\x84', b'\x21', b'\xff')
  assert_eq(pixel.r, b'\x42')
  assert_eq(pixel.g, b'\x84')
  assert_eq(pixel.b, b'\x21')
  assert_eq(pixel.a, b'\xff')

  // Test default pixel
  let default_pixel = Pixel::default()
  assert_eq(default_pixel.r, b'\x00')
  assert_eq(default_pixel.g, b'\x00')
  assert_eq(default_pixel.b, b'\x00')
  assert_eq(default_pixel.a, b'\x00')
}

///|
test "pixel equality and comparison" {
  let pixel1 = Pixel::new(b'\xff', b'\x00', b'\x00', b'\xff')
  let pixel2 = Pixel::new(b'\xff', b'\x00', b'\x00', b'\xff')
  let pixel3 = Pixel::new(b'\x00', b'\xff', b'\x00', b'\xff')
  assert_eq(pixel1, pixel2)
  assert_false(pixel1 == pixel3)
}

///|
test "pixel hash function" {
  let red_pixel = Pixel::new(b'\xff', b'\x00', b'\x00', b'\xff')
  let green_pixel = Pixel::new(b'\x00', b'\xff', b'\x00', b'\xff')
  let blue_pixel = Pixel::new(b'\x00', b'\x00', b'\xff', b'\xff')
  let black_pixel = Pixel::new(b'\x00', b'\x00', b'\x00', b'\xff')
  let red_hash = qoi_color_hash(red_pixel)
  let green_hash = qoi_color_hash(green_pixel)
  let blue_hash = qoi_color_hash(blue_pixel)
  let black_hash = qoi_color_hash(black_pixel)

  // Hash should be in valid range [0, 64)
  assert_true(red_hash >= 0 && red_hash < 64)
  assert_true(green_hash >= 0 && green_hash < 64)
  assert_true(blue_hash >= 0 && blue_hash < 64)
  assert_true(black_hash >= 0 && black_hash < 64)

  // Different pixels should generally have different hashes
  assert_false(red_hash == green_hash)
  assert_false(green_hash == blue_hash)
}

///|
test "array operations with pixels" {
  let pixels = [
    Pixel::new(b'\xff', b'\x00', b'\x00', b'\xff'), // Red
    Pixel::new(b'\x00', b'\xff', b'\x00', b'\xff'), // Green
    Pixel::new(b'\x00', b'\x00', b'\xff', b'\xff'), // Blue
    Pixel::new(b'\xff', b'\xff', b'\xff', b'\xff'), // White
  ]

  // Test basic array properties
  assert_eq(pixels.length(), 4)

  // Test individual pixel access
  assert_eq(pixels[0], Pixel::new(b'\xff', b'\x00', b'\x00', b'\xff'))
  assert_eq(pixels[1], Pixel::new(b'\x00', b'\xff', b'\x00', b'\xff'))
  assert_eq(pixels[2], Pixel::new(b'\x00', b'\x00', b'\xff', b'\xff'))
  assert_eq(pixels[3], Pixel::new(b'\xff', b'\xff', b'\xff', b'\xff'))
}

///|
test "read big-endian 32-bit integer" {
  let bytes = b"\x12\x34\x56\x78"
  let value = read_be32(bytes, 0)
  assert_eq(value, 0x12345678)

  // Test with different values
  let bytes2 = b"\x00\x00\x01\x00"
  let value2 = read_be32(bytes2, 0)
  assert_eq(value2, 0x100) // 256 in decimal

  // Test zero
  let bytes3 = b"\x00\x00\x00\x00"
  let value3 = read_be32(bytes3, 0)
  assert_eq(value3, 0)
}

///|
test "bytes equality check" {
  let bytes1 = b"qoif"
  let bytes2 = b"qoif"
  let bytes3 = b"test"
  assert_true(bytes_eq(bytes1, 0, bytes2, 0, 4))
  assert_false(bytes_eq(bytes1, 0, bytes3, 0, 4))

  // Test partial equality
  let long_bytes = b"qoiftest"
  assert_true(bytes_eq(bytes1, 0, long_bytes, 0, 4)) // First 4 bytes match
  assert_false(bytes_eq(bytes1, 0, long_bytes, 4, 4)) // "qoif" != "test"
}

///|
test "qoi magic and padding constants" {
  assert_eq(QOI_MAGIC.length(), 4)
  assert_eq(QOI_PADDING.length(), 8)

  // Verify magic bytes spell "qoif"
  assert_eq(QOI_MAGIC[0], b'q')
  assert_eq(QOI_MAGIC[1], b'o')
  assert_eq(QOI_MAGIC[2], b'i')
  assert_eq(QOI_MAGIC[3], b'f')

  // Verify padding is 7 zeros + 1
  for i = 0; i < 7; i = i + 1 {
    assert_eq(QOI_PADDING[i], b'\x00')
  }
  assert_eq(QOI_PADDING[7], b'\x01')
}

///|
test "pixel array creation and manipulation" {
  let pixels : Array[Pixel] = []

  // Add some pixels
  pixels.push(Pixel::new(b'\xff', b'\x00', b'\x00', b'\xff'))
  pixels.push(Pixel::new(b'\x00', b'\xff', b'\x00', b'\xff'))
  pixels.push(Pixel::new(b'\x00', b'\x00', b'\xff', b'\xff'))
  assert_eq(pixels.length(), 3)

  // Verify each pixel
  assert_eq(pixels[0].r, b'\xff')
  assert_eq(pixels[0].g, b'\x00')
  assert_eq(pixels[1].r, b'\x00')
  assert_eq(pixels[1].g, b'\xff')
  assert_eq(pixels[2].b, b'\xff')
}

///|
test "repeated pixel creation" {
  // Test creating many identical pixels (useful for run-length encoding)
  let base_pixel = Pixel::new(b'\x42', b'\x42', b'\x42', b'\xff')
  let pixels = Array::make(10, base_pixel)
  assert_eq(pixels.length(), 10)

  // All pixels should be identical
  for i = 0; i < 10; i = i + 1 {
    assert_eq(pixels[i], base_pixel)
    assert_eq(pixels[i].r, b'\x42')
    assert_eq(pixels[i].g, b'\x42')
    assert_eq(pixels[i].b, b'\x42')
    assert_eq(pixels[i].a, b'\xff')
  }
}

///|
test "gradient pixel generation" {
  let pixels : Array[Pixel] = []

  // Create a small gradient
  for i = 0; i < 4; i = i + 1 {
    let intensity = (i * 85).land(0xFF).to_byte() // 0, 85, 170, 255
    pixels.push(Pixel::new(intensity, intensity, intensity, b'\xff'))
  }
  assert_eq(pixels.length(), 4)

  // Check gradient values
  assert_eq(pixels[0].r, b'\x00') // Black
  assert_eq(pixels[1].r, b'\x55') // Dark gray
  assert_eq(pixels[2].r, b'\xaa') // Light gray  
  assert_eq(pixels[3].r, b'\xff') // White
}

///|
test "byte arithmetic and conversion" {
  // Test byte to int conversion
  let byte_val = b'\x42'
  let int_val = byte_val.to_int()
  assert_eq(int_val, 66)

  // Test int to byte conversion
  let back_to_byte = int_val.to_byte()
  assert_eq(back_to_byte, b'\x42')

  // Test with mask operations
  let masked = (255).land(0xFF).to_byte()
  assert_eq(masked, b'\xff')
}

///|
test "bitwise operations for QOI opcodes" {
  // Test operations similar to what QOI codec uses
  let opcode = 0xfe
  let run_opcode = 0xc0
  let mask = 0b11000000
  assert_eq(opcode & mask, 0xc0)
  assert_eq(run_opcode & mask, 0xc0)

  // Test bit shifting
  let value = 0x12
  assert_eq(value << 4, 0x120)
  assert_eq(value >> 2, 0x04)
}

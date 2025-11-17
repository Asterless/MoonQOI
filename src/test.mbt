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

///|
test "encode and decode roundtrip" {
  let pixels = [
    Pixel::new(b'\xff', b'\x00', b'\x00', b'\xff'), // Red
    Pixel::new(b'\xff', b'\x00', b'\x00', b'\xff'), // Red
    Pixel::new(b'\x00', b'\xff', b'\x00', b'\xff'), // Green
    Pixel::new(b'\x00', b'\x00', b'\xff', b'\xff'), // Blue
    Pixel::new(b'\x00', b'\x00', b'\xff', b'\xfe'), // Blue with different alpha
  ]
  let original_image = Image::new(5, 1, RGBA, SRGBLinearAlpha, pixels)

  // Encode and decode
  let encoded_data = encode(original_image)
  let decoded_image = decode(encoded_data)

  // Verify integrity
  assert_eq(original_image.width, decoded_image.width)
  assert_eq(original_image.height, decoded_image.height)
  assert_eq(original_image.channels, decoded_image.channels)
  assert_eq(original_image.colorspace, decoded_image.colorspace)
  assert_eq(pixels.length(), decoded_image.pixels.length())
  for i = 0; i < pixels.length(); i = i + 1 {
    assert_eq(pixels[i], decoded_image.pixels[i])
  }
}

///|
test "encode and decode roundtrip - additional case" {
  let pixels = [
    Pixel::new(b'\x00', b'\x00', b'\x00', b'\xff'), // Black
    Pixel::new(b'\xff', b'\xff', b'\xff', b'\xff'), // White
  ]
  let original_image = Image::new(2, 1, RGBA, SRGBLinearAlpha, pixels)

  // Encode and decode
  let encoded_data = encode(original_image)
  let decoded_image = decode(encoded_data)

  // Verify integrity
  assert_eq(original_image.width, decoded_image.width)
  assert_eq(original_image.height, decoded_image.height)
  assert_eq(original_image.channels, decoded_image.channels)
  assert_eq(original_image.colorspace, decoded_image.colorspace)
  assert_eq(pixels.length(), decoded_image.pixels.length())
  for i = 0; i < pixels.length(); i = i + 1 {
    assert_eq(pixels[i], decoded_image.pixels[i])
  }
}

///|
test "decode with invalid header (too short)" {
  let data = b"qoif" // Too short, needs to be at least 14 bytes
  let _ = decode(data) catch {
    ImageError(msg) => {
      assert_eq(msg, "Data too short to be a valid QOI image")
      return
    }
  }
  fail("fail")
}

///|
test "decode with invalid magic bytes" {
  // A valid header with incorrect magic bytes
  let data = b"bad!\x00\x00\x00\x01\x00\x00\x00\x01\x04\x00"
  let _ = decode(data) catch {
    ImageError(msg) => {
      assert_eq(msg, "Invalid magic bytes")
      return
    }
  }
  fail("fail")
}

///|
test "decode with zero dimensions" {
  // Header with 0 width
  let data = b"qoif\x00\x00\x00\x00\x00\x00\x00\x01\x04\x00"
  let _ = decode(data) catch {
    ImageError(msg) => {
      assert_eq(msg, "Invalid header: zero dimensions")
      return
    }
  }
  fail("fail")
}

///|
test "decode with unexpected end of file" {
  // Header says 1 pixel, but no pixel data
  let data = b"qoif\x00\x00\x00\x01\x00\x00\x00\x01\x04\x00"
  let _ = decode(data) catch {
    ImageError(msg) => {
      assert_eq(msg, "Unexpected end of file")
      return
    }
  }
  fail("fail")
}

///|
test "decode with invalid channel count" {
  // Header with invalid channel value (e.g., 5)
  let data = b"qoif\x00\x00\x00\x01\x00\x00\x00\x01\x05\x00"
  let _ = decode(data) catch {
    ImageError(msg) => {
      assert_eq(msg, "Invalid channel count")
      return
    }
  }
  fail("fail")
}

///|
test "decode with invalid colorspace" {
  // Header with invalid colorspace value (e.g., 2)
  let data = b"qoif\x00\x00\x00\x01\x00\x00\x00\x01\x04\x02"
  let _ = decode(data) catch {
    ImageError(msg) => {
      assert_eq(msg, "Invalid colorspace")
      return
    }
  }
  fail("fail")
}

///|
test "decode with unexpected end of file in RGB" {
  // Header for 1 pixel, but RGB data is incomplete
  let data = b"qoif\x00\x00\x00\x01\x00\x00\x00\x01\x04\x00\xfe\x12\x34" // Missing one byte for RGB
  let _ = decode(data) catch {
    ImageError(msg) => {
      assert_eq(msg, "Unexpected end of file in RGB")
      return
    }
  }
  fail("fail")
}

///|
test "decode with unexpected end of file in RGBA" {
  // Header for 1 pixel, but RGBA data is incomplete
  let data = b"qoif\x00\x00\x00\x01\x00\x00\x00\x01\x04\x00\xff\x12\x34\x56" // Missing one byte for RGBA
  let _ = decode(data) catch {
    ImageError(msg) => {
      assert_eq(msg, "Unexpected end of file in RGBA")
      return
    }
  }
  fail("fail")
}

///|
test "decode with unexpected end of file in LUMA" {
  // Header for 1 pixel, but LUMA data is incomplete
  let data = b"qoif\x00\x00\x00\x01\x00\x00\x00\x01\x04\x00\x8f" // Missing second byte for LUMA
  let _ = decode(data) catch {
    ImageError(msg) => {
      assert_eq(msg, "Unexpected end of file in LUMA")
      return
    }
  }
  fail("fail")
}

///|
test "encode run-length edge cases" {
  // This test verifies the correct encoding of QOI_OP_RUN,
  // especially for the maximum run length (62) and for runs
  // that are at the end of the pixel stream. It targets the
  // bug where `run` was used instead of `run - 1`.

  // 1. Create a sequence with a run of 62 identical pixels
  let pixels_max_run : Array[Pixel] = []
  let red = Pixel::new(b'\xff', b'\x00', b'\x00', b'\xff')
  for i = 0; i < 62; i = i + 1 {
    pixels_max_run.push(red)
  }
  // Add a different pixel to terminate the run
  pixels_max_run.push(Pixel::new(b'\x00', b'\xff', b'\x00', b'\xff'))
  let image_max_run = Image::new(
    pixels_max_run.length(),
    1,
    RGBA,
    SRGBLinearAlpha,
    pixels_max_run,
  )
  // Encode and decode, then verify
  let decoded_max_run = decode(encode(image_max_run))
  assert_eq(image_max_run, decoded_max_run)

  // 2. Create a sequence that ends with a run
  let pixels_end_run : Array[Pixel] = [
    Pixel::new(b'\x00', b'\x00', b'\xff', b'\xff'), // Blue
  ]
  let white = Pixel::new(b'\xff', b'\xff', b'\xff', b'\xff')
  for i = 0; i < 5; i = i + 1 {
    pixels_end_run.push(white) // 5 white pixels at the end
  }
  let image_end_run = Image::new(
    pixels_end_run.length(),
    1,
    RGBA,
    SRGBLinearAlpha,
    pixels_end_run,
  )
  // Encode and decode, then verify
  let decoded_end_run = decode(encode(image_end_run))
  assert_eq(image_end_run, decoded_end_run)
}

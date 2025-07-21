// QOI decoder and encoder implementation

// QOI format constants

///|
pub const QOI_MAGIC : Bytes = b"qoif"

///|
pub const QOI_PADDING : Bytes = b"\x00\x00\x00\x00\x00\x00\x00\x01"

// QOI opcodes

///|
const QOI_OP_INDEX = 0b00000000 // 0x00 - 0x3f

///|
const QOI_OP_DIFF = 0b01000000 // 0x40 - 0x7f

///|
const QOI_OP_LUMA = 0b10000000 // 0x80 - 0xbf

///|
const QOI_OP_RUN = 0b11000000 // 0xc0 - 0xfd

///|
const QOI_OP_RGB = 0xfe // 0xfe

///|
const QOI_OP_RGBA = 0xff // 0xff

///|
const QOI_MASK_2 = 0b11000000 // 0xc0

///| Hash function for pixel indexing
pub fn qoi_color_hash(pixel : Pixel) -> Int {
  let r = pixel.r.to_int()
  let g = pixel.g.to_int()
  let b = pixel.b.to_int()
  let a = pixel.a.to_int()
  (r * 3 + g * 5 + b * 7 + a * 11) % 64
}

///| Read 32-bit big-endian integer from bytes
pub fn read_be32(bytes : Bytes, offset : Int) -> Int {
  let b0 = bytes[offset].to_int()
  let b1 = bytes[offset + 1].to_int()
  let b2 = bytes[offset + 2].to_int()
  let b3 = bytes[offset + 3].to_int()
  (b0 << 24) | (b1 << 16) | (b2 << 8) | b3
}

///| Write 32-bit big-endian integer to bytes buffer
pub fn write_be32(buffer : FixedArray[Byte], offset : Int, value : Int) -> Unit {
  buffer[offset] = (value >> 24).to_byte()
  buffer[offset + 1] = (value >> 16).to_byte()
  buffer[offset + 2] = (value >> 8).to_byte()
  buffer[offset + 3] = value.to_byte()
}

///| Check if two byte slices are equal
pub fn bytes_eq(
  a : Bytes,
  a_start : Int,
  b : Bytes,
  b_start : Int,
  len : Int
) -> Bool {
  for i in 0..<len {
    if a[a_start + i] != b[b_start + i] {
      break false
    }
  } else {
    true
  }
}

///| QOI decoder
pub fn decode(data : Bytes) -> Image {
  if data.length() < 14 {
    abort("Invalid header: file too short")
  }

  // Check magic
  if not(bytes_eq(data, 0, QOI_MAGIC, 0, 4)) {
    abort("Invalid magic bytes")
  }

  // Read header
  let width = read_be32(data, 4)
  let height = read_be32(data, 8)
  let channels_byte = data[12].to_int()
  let colorspace_byte = data[13].to_int()
  if width == 0 || height == 0 {
    abort("Invalid header: zero dimensions")
  }
  let channels = match channels_byte {
    3 => RGB
    4 => RGBA
    _ => abort("Invalid channel count")
  }
  let colorspace = match colorspace_byte {
    0 => SRGBLinearAlpha
    1 => AllLinear
    _ => abort("Invalid colorspace")
  }
  let pixels_count = width * height
  let pixels : Array[Pixel] = []
  let index : FixedArray[Pixel] = FixedArray::make(64, Pixel::default())
  let mut pos = 14
  let mut pixel = Pixel::new(b'\x00', b'\x00', b'\x00', b'\xff')
  let mut run = 0
  while pixels.length() < pixels_count {
    if pos >= data.length() {
      abort("Unexpected end of file")
    }
    if run > 0 {
      pixels.push(pixel)
      run = run - 1
    } else {
      let b1 = data[pos].to_int()
      pos = pos + 1
      if b1 == QOI_OP_RGB {
        // RGB
        if pos + 2 >= data.length() {
          abort("Unexpected end of file in RGB")
        }
        pixel = Pixel::new(data[pos], data[pos + 1], data[pos + 2], pixel.a)
        pos = pos + 3
      } else if b1 == QOI_OP_RGBA {
        // RGBA
        if pos + 3 >= data.length() {
          abort("Unexpected end of file in RGBA")
        }
        pixel = Pixel::new(
          data[pos],
          data[pos + 1],
          data[pos + 2],
          data[pos + 3],
        )
        pos = pos + 4
      } else if (b1 & QOI_MASK_2) == QOI_OP_INDEX {
        // INDEX
        let idx = b1
        pixel = index[idx]
      } else if (b1 & QOI_MASK_2) == QOI_OP_DIFF {
        // DIFF
        let dr = ((b1 >> 4) & 0x03) - 2
        let dg = ((b1 >> 2) & 0x03) - 2
        let db = (b1 & 0x03) - 2
        let new_r = (pixel.r.to_int() + dr).land(0xFF).to_byte()
        let new_g = (pixel.g.to_int() + dg).land(0xFF).to_byte()
        let new_b = (pixel.b.to_int() + db).land(0xFF).to_byte()
        pixel = Pixel::new(new_r, new_g, new_b, pixel.a)
      } else if (b1 & QOI_MASK_2) == QOI_OP_LUMA {
        // LUMA
        if pos >= data.length() {
          abort("Unexpected end of file in LUMA")
        }
        let b2 = data[pos].to_int()
        pos = pos + 1
        let dg = (b1 & 0x3f) - 32
        let dr = dg + ((b2 >> 4) & 0x0f) - 8
        let db = dg + (b2 & 0x0f) - 8
        let new_r = (pixel.r.to_int() + dr).land(0xFF).to_byte()
        let new_g = (pixel.g.to_int() + dg).land(0xFF).to_byte()
        let new_b = (pixel.b.to_int() + db).land(0xFF).to_byte()
        pixel = Pixel::new(new_r, new_g, new_b, pixel.a)
      } else if (b1 & QOI_MASK_2) == QOI_OP_RUN {
        // RUN
        run = b1 & 0x3f
      } else {
        abort("Unknown opcode")
      }
      index[qoi_color_hash(pixel)] = pixel
      pixels.push(pixel)
    }
  }
  if pixels.length() != pixels_count {
    abort("Pixel count mismatch")
  }
  Image::new(width, height, channels, colorspace, pixels)
}

///| QOI encoder
pub fn encode(image : Image) -> Bytes {
  let buffer : Array[Byte] = []

  // Write header
  for i = 0; i < QOI_MAGIC.length(); i = i + 1 {
    buffer.push(QOI_MAGIC[i])
  }

  // Write dimensions and format info
  let width_bytes = [
    (image.width >> 24).land(0xFF).to_byte(),
    (image.width >> 16).land(0xFF).to_byte(),
    (image.width >> 8).land(0xFF).to_byte(),
    image.width.land(0xFF).to_byte(),
  ]
  let height_bytes = [
    (image.height >> 24).land(0xFF).to_byte(),
    (image.height >> 16).land(0xFF).to_byte(),
    (image.height >> 8).land(0xFF).to_byte(),
    image.height.land(0xFF).to_byte(),
  ]
  for byte in width_bytes {
    buffer.push(byte)
  }
  for byte in height_bytes {
    buffer.push(byte)
  }
  let channels_byte = match image.channels {
    RGB => b'\x03'
    RGBA => b'\x04'
  }
  buffer.push(channels_byte)
  let colorspace_byte = match image.colorspace {
    SRGBLinearAlpha => b'\x00'
    AllLinear => b'\x01'
  }
  buffer.push(colorspace_byte)

  // Encode pixels
  let index : FixedArray[Pixel] = FixedArray::make(64, Pixel::default())
  let mut prev_pixel = Pixel::new(b'\x00', b'\x00', b'\x00', b'\xff')
  let mut run = 0
  for i = 0; i < image.pixels.length(); i = i + 1 {
    let pixel = image.pixels[i]
    if pixel == prev_pixel {
      run = run + 1
      if run == 62 || i == image.pixels.length() - 1 {
        buffer.push((QOI_OP_RUN | run).to_byte())
        run = 0
      }
    } else {
      if run > 0 {
        buffer.push((QOI_OP_RUN | run).to_byte())
        run = 0
      }
      let index_pos = qoi_color_hash(pixel)
      if index[index_pos] == pixel {
        // INDEX
        buffer.push(index_pos.to_byte())
      } else {
        index[index_pos] = pixel
        if pixel.a == prev_pixel.a {
          let dr = pixel.r.to_int() - prev_pixel.r.to_int()
          let dg = pixel.g.to_int() - prev_pixel.g.to_int()
          let db = pixel.b.to_int() - prev_pixel.b.to_int()
          if dr >= -2 && dr <= 1 && dg >= -2 && dg <= 1 && db >= -2 && db <= 1 {
            // DIFF
            buffer.push(
              (QOI_OP_DIFF | ((dr + 2) << 4) | ((dg + 2) << 2) | (db + 2)).to_byte(),
            )
          } else {
            let dr_dg = dr - dg
            let db_dg = db - dg
            if dr_dg >= -8 &&
              dr_dg <= 7 &&
              dg >= -32 &&
              dg <= 31 &&
              db_dg >= -8 &&
              db_dg <= 7 {
              // LUMA
              buffer.push((QOI_OP_LUMA | (dg + 32)).to_byte())
              buffer.push((((dr_dg + 8) << 4) | (db_dg + 8)).to_byte())
            } else {
              // RGB
              buffer.push(QOI_OP_RGB.to_byte())
              buffer.push(pixel.r)
              buffer.push(pixel.g)
              buffer.push(pixel.b)
            }
          }
        } else {
          // RGBA
          buffer.push(QOI_OP_RGBA.to_byte())
          buffer.push(pixel.r)
          buffer.push(pixel.g)
          buffer.push(pixel.b)
          buffer.push(pixel.a)
        }
      }
      prev_pixel = pixel
    }
  }

  // Write padding
  for i in 0..<QOI_PADDING.length() {
    buffer.push(QOI_PADDING[i])
  }

  // Convert to bytes
  Bytes::from_array(buffer)
}

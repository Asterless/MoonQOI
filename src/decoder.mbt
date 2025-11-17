// QOI decoder (uses qoi_constants.mbt and qoi_utils.mbt)

///|
/// QOI decoder
pub fn decode(data : Bytes) -> Image raise ImageError {
  if data.length() < 14 {
    raise ImageError("Data too short to be a valid QOI image")
  }

  // Check magic
  if not(bytes_eq(data, 0, QOI_MAGIC, 0, 4)) {
    raise ImageError("Invalid magic bytes")
  }

  // Read header
  let width = read_be32(data, 4)
  let height = read_be32(data, 8)
  let channels_byte = data[12].to_int()
  let colorspace_byte = data[13].to_int()
  if width == 0 || height == 0 {
    raise ImageError("Invalid header: zero dimensions")
  }
  let channels = match channels_byte {
    3 => RGB
    4 => RGBA
    _ => raise ImageError("Invalid channel count")
  }
  let colorspace = match colorspace_byte {
    0 => SRGBLinearAlpha
    1 => AllLinear
    _ => raise ImageError("Invalid colorspace")
  }
  let pixels_count = width * height
  let pixels : Array[Pixel] = []
  let index : FixedArray[Pixel] = FixedArray::make(64, Pixel::default())
  let mut pos = 14
  let mut pixel = Pixel::new(b'\x00', b'\x00', b'\x00', b'\xff')
  let mut run = 0
  while pixels.length() < pixels_count {
    if pos >= data.length() {
      raise ImageError("Unexpected end of file")
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
          raise ImageError("Unexpected end of file in RGB")
        }
        pixel = Pixel::new(data[pos], data[pos + 1], data[pos + 2], pixel.a)
        pos = pos + 3
      } else if b1 == QOI_OP_RGBA {
        // RGBA
        if pos + 3 >= data.length() {
          raise ImageError("Unexpected end of file in RGBA")
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
          raise ImageError("Unexpected end of file in LUMA")
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
        raise ImageError("Unknown opcode")
      }
      index[qoi_color_hash(pixel)] = pixel
      pixels.push(pixel)
    }
  }
  if pixels.length() != pixels_count {
    raise ImageError("Pixel count mismatch")
  }
  Image::new(width, height, channels, colorspace, pixels)
}

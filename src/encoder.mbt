// QOI encoder

///|
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

// QOI Library Usage Examples

///| Create a simple red square image and encode it  
pub fn example_red_square() -> Unit {
  let red = @lib.Pixel::new(b'\xff', b'\x00', b'\x00', b'\xff')
  let pixels : Array[@lib.Pixel] = []
  for _i = 0; _i < 16; _i = _i + 1 {
    pixels.push(red)
  }
  println("Created \{pixels.length()} red pixels for 4x4 image")
}

///| Create a gradient image
pub fn example_gradient() -> Unit {
  let pixels : Array[@lib.Pixel] = []

  // Create a 16x16 gradient from black to white
  for y = 0; y < 16; y = y + 1 {
    for x = 0; x < 16; x = x + 1 {
      let intensity = ((x + y) * 255 / 30).land(0xFF).to_byte()
      pixels.push(@lib.Pixel::new(intensity, intensity, intensity, b'\xff'))
    }
  }
  println("Created \{pixels.length()} gradient pixels for 16x16 image")
}

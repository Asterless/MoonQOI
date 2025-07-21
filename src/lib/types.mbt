// QOI (Quite OK Image Format) Implementation
// Based on specification: https://qoiformat.org/qoi-specification.pdf

///| QOI image color channels
pub enum Channels {
  RGB // 3 channels
  RGBA // 4 channels
} derive(Show, Eq)

///| QOI image colorspace
pub enum Colorspace {
  SRGBLinearAlpha // 0 = sRGB with linear alpha
  AllLinear // 1 = all channels linear
} derive(Show, Eq)

///| RGBA pixel
pub struct Pixel {
  r : Byte
  g : Byte
  b : Byte
  a : Byte
} derive(Show, Eq, Default)

///| Create a new pixel
pub fn Pixel::new(r : Byte, g : Byte, b : Byte, a : Byte) -> Pixel {
  { r, g, b, a }
}

///| QOI image structure
pub struct Image {
  width : Int
  height : Int
  channels : Channels
  colorspace : Colorspace
  pixels : Array[Pixel]
} derive(Show)

///| Create a new image
pub fn Image::new(
  width : Int,
  height : Int,
  channels : Channels,
  colorspace : Colorspace,
  pixels : Array[Pixel]
) -> Image {
  { width, height, channels, colorspace, pixels }
}

///| QOI decoder/encoder errors
pub enum QOIError {
  InvalidMagic
  InvalidHeader
  InvalidData(String)
  UnexpectedEOF
  TooManyPixels
  InsufficientPixels
  InvalidChannel
  InvalidColorspace
} derive(Show)

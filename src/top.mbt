// QOI (Quite OK Image Format) Library Entry Point

///| Decode QOI format bytes into an Image

///| Returns Result containing Image on success or QOIError on failure
pub fn decode(data : Bytes) -> Result[@lib.Image, @lib.QOIError] {
  @lib.decode(data)
}

///| Encode an Image into QOI format bytes

///| Returns Result containing Bytes on success or QOIError on failure
pub fn encode(image : @lib.Image) -> Result[Bytes, @lib.QOIError] {
  @lib.encode(image)
}

///| Create a new Image
pub fn new_image(
  width : Int,
  height : Int,
  channels : @lib.Channels,
  colorspace : @lib.Colorspace,
  pixels : Array[@lib.Pixel],
) -> @lib.Image {
  @lib.Image::new(width, height, channels, colorspace, pixels)
}

///| Create a new Pixel
pub fn new_pixel(r : Byte, g : Byte, b : Byte, a : Byte) -> @lib.Pixel {
  @lib.Pixel::new(r, g, b, a)
}

///| Export types
pub typealias @lib.Image

///|
pub typealias @lib.Pixel

///|
pub typealias @lib.Channels

///|
pub typealias @lib.Colorspace

///|
pub typealias @lib.QOIError

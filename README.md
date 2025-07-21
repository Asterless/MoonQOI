# MoonQOI - QOI Image Format Library for MoonBit

A high-performance, fully compliant implementation of the QOI (Quite OK Image) format for the MoonBit programming language.

## What is QOI?

QOI (Quite OK Image Format) is a modern, lossless image compression format designed for simplicity and speed. It provides:
- **Fast encoding/decoding** - 20-50x faster than PNG
- **Good compression** - Similar compression ratios to PNG
- **Simple specification** - Easy to implement and understand
- **No dependencies** - Self-contained format

## Features

- ✅ **Full QOI specification compliance**
- ✅ **All QOI opcodes supported**: QOI_OP_RGB, QOI_OP_RGBA, QOI_OP_INDEX, QOI_OP_DIFF, QOI_OP_LUMA, QOI_OP_RUN
- ✅ **Both RGB and RGBA channels**
- ✅ **Both sRGB and linear colorspaces**
- ✅ **High performance** implementation
- ✅ **Simple, clean API**
- ✅ **Comprehensive error handling**
- ✅ **Pixel-perfect accuracy**

## Usage

### Basic Usage

```moonbit
// Import the library
import @lib from "Asterless/MoonQOI/lib"

// Create an image
let pixels = [
  @lib.Pixel::new(b'\xff', b'\x00', b'\x00', b'\xff'), // Red
  @lib.Pixel::new(b'\x00', b'\xff', b'\x00', b'\xff'), // Green
  @lib.Pixel::new(b'\x00', b'\x00', b'\xff', b'\xff'), // Blue
  @lib.Pixel::new(b'\xff', b'\xff', b'\xff', b'\xff')  // White
]

let image = @lib.Image::new(
  2, 2,                                    // 2x2 image
  @lib.Channels::RGBA,                     // 4 channels (RGBA)
  @lib.Colorspace::SRGBLinearAlpha,       // sRGB colorspace
  pixels
)

// Encode to QOI format
let encoded_bytes = @lib.encode(image)

// Decode QOI data back to image
let decoded_image = @lib.decode(encoded_bytes)
```

### API Reference

#### Types

- `Image` - Represents a QOI image with width, height, channels, colorspace, and pixel data
- `Pixel` - Single RGBA pixel with r, g, b, a components (each a Byte)
- `Channels` - Either `RGB` (3 channels) or `RGBA` (4 channels)
- `Colorspace` - Either `SRGBLinearAlpha` or `AllLinear`

#### Core Functions

- `decode(data: Bytes) -> Image` - Decode QOI format bytes into an Image
- `encode(image: Image) -> Bytes` - Encode an Image into QOI format bytes

#### Constructors

- `Pixel::new(r: Byte, g: Byte, b: Byte, a: Byte) -> Pixel` - Create a new pixel
- `Image::new(width: Int, height: Int, channels: Channels, colorspace: Colorspace, pixels: Array[Pixel]) -> Image` - Create a new image

## Examples

See `src/examples.mbt` for more detailed examples including:
- Creating solid color images
- Generating gradients
- Round-trip encoding/decoding verification

## QOI Format Specification

This implementation follows the official QOI specification:
- Magic bytes: `qoif` (0x716f6966)
- Header: width (4 bytes), height (4 bytes), channels (1 byte), colorspace (1 byte)
- Data chunks with various opcodes
- End marker: 7 zero bytes + 1 byte (0x01)

## Performance

The implementation is optimized for speed while maintaining readability:
- Efficient pixel hashing for index operations
- Minimal memory allocations
- Fast bit operations for opcode handling
- Optimal run-length encoding

## Testing

Run tests with:
```bash
moon test
```

The test suite includes:
- Basic encoding/decoding verification
- Round-trip integrity tests
- Format compliance validation
- Edge case handling

## License

Licensed under the Apache License 2.0. See `LICENSE` file for details.

## Contributing

Contributions are welcome! Please ensure:
- Code follows MoonBit style guidelines
- Tests pass and new functionality is tested
- Performance is maintained or improved
- QOI specification compliance is preserved
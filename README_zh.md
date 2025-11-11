# MoonQOI - MoonBit 的 QOI 图像格式库 | [ENGLISH](README.md)

一个面向 MoonBit 编程语言的高性能、完全兼容 QOI（Quite OK Image）格式的实现。

## 什么是 QOI?

QOI（Quite OK Image Format）是一种现代的无损图像压缩格式，设计目标是简洁与速度。其特点包括：

- **快速编码/解码** - 比 PNG 快 20-50 倍
- **良好的压缩率** - 与 PNG 相近
- **简单的规范** - 易于实现和理解
- **无外部依赖** - 自包含格式

## 特性

- ✅ **完全遵循 QOI 规范**
- ✅ **支持所有 QOI 操作码**：QOI_OP_RGB、QOI_OP_RGBA、QOI_OP_INDEX、QOI_OP_DIFF、QOI_OP_LUMA、QOI_OP_RUN
- ✅ **支持 RGB 与 RGBA 通道**
- ✅ **支持 sRGB 与线性色彩空间**
- ✅ **高性能实现**
- ✅ **简单、干净的 API**
- ✅ **完善的错误处理**
- ✅ **像素级准确性**

## 用法

### 安装

```bash
moon add Asterless/MoonQOI
```

### 基本用法

```moonbit
// Create an image
let pixels = [
  Pixel::new(b'\xff', b'\x00', b'\x00', b'\xff'), // Red
  Pixel::new(b'\x00', b'\xff', b'\x00', b'\xff'), // Green
  Pixel::new(b'\x00', b'\x00', b'\xff', b'\xff'), // Blue
  Pixel::new(b'\xff', b'\xff', b'\xff', b'\xff')  // White
]

let image = Image::new(
  2, 2,                              // 2x2 image
  Channels::RGBA,                    // 4 channels (RGBA)
  Colorspace::SRGBLinearAlpha,       // sRGB colorspace
  pixels
)

// Encode to QOI format
let encoded_bytes = encode(image)

// Decode QOI data back to image
let decoded_image = decode(encoded_bytes)
```

## API 参考

### 类型

- `Image` - 表示一个 QOI 图像，包含宽、高、通道、色彩空间与像素数据
- `Pixel` - 单个 RGBA 像素，包含 r, g, b, a 分量（每个为 Byte）
- `Channels` - `RGB`（3 通道）或 `RGBA`（4 通道）
- `Colorspace` - `SRGBLinearAlpha` 或 `AllLinear`

### 核心函数

- `decode(data: Bytes) -> Image` - 将 QOI 字节解码为 Image
- `encode(image: Image) -> Bytes` - 将 Image 编码为 QOI 字节

### 构造器

- `Pixel::new(r: Byte, g: Byte, b: Byte, a: Byte) -> Pixel` - 创建像素
- `Image::new(width: Int, height: Int, channels: Channels, colorspace: Colorspace, pixels: Array[Pixel]) -> Image` - 创建图像

## 示例

参见 `src/examples.mbt`，其中包含更多示例：

- 生成纯色图像
- 生成渐变
- 编码/解码往返验证

## QOI 文件格式规范

该实现遵循官方 QOI 规范：

- 魔数：`qoif` (0x716f6966)
- 头部：宽（4 字节），高（4 字节），通道（1 字节），色彩空间（1 字节）
- 数据块使用各种操作码
- 结尾标记：7 个 0 字节 + 1 字节（0x01）

## 性能

实现优化以兼顾速度与可读性：

- 高效的像素哈希用于索引操作
- 最小化内存分配
- 对操作码的快速位操作
- 最优的跑长编码实现

## 测试

运行测试：

```bash
moon test
```

测试包含：

- 基本编码/解码验证
- 往返完整性测试
- 格式兼容性验证
- 边界条件处理

## 许可证

本项目使用 Apache License 2.0，详见 `LICENSE` 文件。

## 贡献

欢迎贡献！请确保：

- 代码遵循 MoonBit 风格指南
- 测试通过且为新功能添加测试
- 尽量保持或提升性能
- 保持 QOI 规范兼容性

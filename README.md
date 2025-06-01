# CMPE362: Simplified Video Compression with DCT and Predictive Coding

# Contributers
- Yusuf AKIN, 2021400288 
- Ahmet Salih TURKEL, 2021400120

## Contents

```
├── +basic_compression
│   ├── compress.m
│   ├── decompress.m
│   ├── dump.m
│   ├── dump_size.m
│   └── load.m
├── +improved_compression
│   ├── compress.m
│   ├── decompress.m
│   ├── dump.m
│   ├── dump_size.m
│   ├── fast_compress.m
│   ├── fast_decompress.m
│   └── load.m
├── +utils
│   ├── frame_to_mb.m
│   ├── generate_gop_layout.m
│   ├── inverse_zigzag.m
│   ├── mb_to_frame.m
│   ├── psnr.m
│   ├── run_length_decode.m
│   ├── run_length_encode.m
│   ├── zigzag.m
│   ├── zigzag_rle_decode.m
│   └── zigzag_rle_encode.m
├── README.md
├── analysis
│   ├── algo2_params_analysis.m
│   ├── compress_range.m
│   ├── gop_size_to_compression_analysis.m
│   ├── gop_to_compression_executor.sh
│   └── psnr_analysis.m
├── compress.m
├── decompress.m
├── improved_compress.m
├── improved_decompress.m
├── report.pdf
└── video_data
```

## Setup

### Dependencies

- [Image Processing Toolbox](https://www.mathworks.com/products/image-processing.html)

### Input and Output

Compression scripts (`compress.m`, `improved_compress.m`) expect all image frames to be located in the `video_data` folder:

```
└── video_data
    ├── frame000.jpg
    ├── frame001.jpg
    ├── ...
    └── frame119.jpg
```

The compression result is saved as `result.bin` by default.

Decompression scripts (`decompress.m`, `improved_decompress.m`) expect the `result.bin` file to be in the root directory. The decompressed images are saved in the `./decompressed` folder as PNG files by default.

## Basic Compression Algorithm

```
├── +basic_compression
│   ├── compress.m
│   ├── decompress.m
│   ├── dump.m
│   ├── dump_size.m
│   └── load.m
├── compress.m
└── decompress.m
```

### Parameters

#### `compress.m`

- `GOP_size`: Group of Pictures size (e.g., 30)
- `quantization_matrix`: A default quantization matrix is provided.
- `verbose`: Enabled by default; displays progress bars during processing.

#### `decompress.m`

- `input_path`: Default is `result.bin`, specifies the input file for decompression.
- `verbose`: Enabled by default; displays progress bars during processing.
- `output_folder`: Specifies the folder to save decompressed images.

**Note:** Enabling the `verbose` parameter introduces minor overhead.

## Improved Compression Algorithm

```
├── +improved_compression
│   ├── compress.m
│   ├── decompress.m
│   ├── dump.m
│   ├── dump_size.m
│   ├── fast_compress.m
│   ├── fast_decompress.m
│   └── load.m
├── improved_compress.m
└── improved_decompress.m
```

### Parameters

#### `improved_compress.m`

- `GOP_size`: Group of Pictures size (e.g., 30)
- `num_B`: Number of B-frames between anchor frames. See `utils.generate_gop_layout` for details on GOP layout creation.
- `quantization_matrix`: Two main quantization matrices are provided:
  - `Q0`: Default matrix from the project description.
  - `Q1`: Custom matrix designed to increase quantization coefficients for higher DCT coefficients. Multiple variations of this matrix are included to demonstrate how coarser matrices affect compression.
- `verbose`: Enabled by default; displays progress bars during processing.

#### `decompress.m`

- `input_path`: Default is `result.bin`, specifies the input file for decompression.
- `output_folder`: Specifies the folder to save decompressed images.
- `verbose`: Enabled by default; displays progress bars during processing.

### Implementation Details

Two implementations of compression and decompression are provided under the `improved_compression` package:

- **Default Implementation:** Slower (~20 seconds to compress 120 frames) as it uses `utils.frame_to_mb` and performs operations without vectorization.
- **Fast Implementation:** Faster (~5 seconds to compress 120 frames) as it uses vectorized operations with `blockproc` and `tensorprod`. Compression is applied directly to image frames without relying on utility functions.

See `improved_compression.fast_compress.m` for more details.

**Note:** Enabling the `verbose` parameter introduces minor overhead.

## Utilities and Analysis Scripts

### Utilities

```
└── +utils
    ├── frame_to_mb.m
    ├── generate_gop_layout.m
    ├── inverse_zigzag.m
    ├── mb_to_frame.m
    ├── psnr.m
    ├── run_length_decode.m
    ├── run_length_encode.m
    ├── zigzag.m
    ├── zigzag_rle_decode.m
    └── zigzag_rle_encode.m
```

These utility scripts are used internally and may not be well-documented.

### Analysis Scripts

```
└── analysis
    ├── algo2_params_analysis.m
    ├── compress_range.m
    ├── gop_size_to_compression_analysis.m
    ├── gop_to_compression_executor.sh
    └── psnr_analysis.m
```

These scripts were used to generate report data. Some of them include experimental work and may require adjustments to function properly.

## Known Issues

As the quantization matrices progress from q1 to q7, the compression ratio increases as expected. However, q1 exhibits a very poor PSNR, leading to image corruption, likely due to numerical instability. Interestingly, q5 achieves a better compression ratio than q1 while maintaining higher image quality.

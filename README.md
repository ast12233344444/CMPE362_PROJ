# CMPE362: Simplified Video Compression with DCT and Predictive Coding
##  Contents
```
.
├── +basic_compression
│   ├── compress.m
│   ├── decompress.m
│   ├── dump.m
│   ├── dump_size.m
│   └── load.m
├── +improved_compression
│   ├── compress.m
│   ├── decompress.m
│   ├── dump.m
│   ├── dump_size.m
│   ├── fast_compress.m
│   ├── fast_decompress.m
│   └── load.m
├── +utils
│   ├── frame_to_mb.m
│   ├── generate_gop_layout.m
│   ├── inverse_zigzag.m
│   ├── mb_to_frame.m
│   ├── psnr.m
│   ├── run_length_decode.m
│   ├── run_length_encode.m
│   ├── zigzag.m
│   ├── zigzag_rle_decode.m
│   └── zigzag_rle_encode.m
├── README.md
├── analysis
│   ├── algo2_params_analysis.m
│   ├── compress_range.m
│   ├── gop_size_to_compression_analysis.m
│   ├── gop_to_compression_executor.sh
│   └── psnr_analysis.m
├── compress.m
├── decompress.m
├── improved_compress.m
├── improved_decompress.m
├── report.pdf
└── video_data
```


## Setup

Dependencies: 
- [Image Processing Toolbox](https://www.mathworks.com/products/image-processing.html)

Comression scripts under root path `compress.m`, `improved_compress.m` expect all image frames to be provided under `video_data` folder:

```
└── video_data
    ├── frame000.jpg
    ├── frame001.jpg
    ├──  ...
    └── frame119.jpg
```

The compression result is dumped as `result.bin` by default.

Decompression scripts under root path `decompress.m`, `improved_decompress.m` expect `result.bin` file to be on root path. The decompressed images are by default dumped under `./decompressed` as png image files. 

## Basic Compression Algorithm

```
├── +basic_compression
│   ├── compress.m
│   ├── decompress.m
│   ├── dump.m
│   ├── dump_size.m
│   └── load.m
├── compress.m
└── decompress.m
```
Parameters
- `compress.m`
    - `GOP_size`: GOP size (e.g 30)
    - `quantization_matrix`: a default quantization matrix is provided
    - `verbose`: true by default, it shows progress bars for the process.
- `decompress.m`
    - `input_path`: default is `result.bin`, where to read decompression input
    - `verbose`: true by default, it shows progress bars for the process.
    - `output_folder`: where to dump decompressed images
NOTE: Setting `verbose` parameter to true introduces a minor overhead.

## Improved Compression Algorithm

```
├── +improved_compression
│   ├── compress.m
│   ├── decompress.m
│   ├── dump.m
│   ├── dump_size.m
│   ├── fast_compress.m
│   ├── fast_decompress.m
│   └── load.m
├── improved_compress.m
└── improved_decompress.m
```
Parameters
- `improved_compress.m`
    - `GOP_size`: GOP size (e.g 30)
    - `num_B`: Inter anchor B-frame count, for details on how GOP layout is created see `utils.generate_gop_layout`
    - `quantization_matrix`: Script contains 2 main quantization matrices, Q0 is the one given in the project dectiption. Q1 was created by hand with the simple idea of increasing quantization coeff towords higher dct coeffs. We provide some multiples of this matrix for convenience to deomonstrate how coarser matrices affect the compression.
    - `verbose`: true by default, it shows progress bars for the process.
- `decompress.m`
    - `input_path`: default is `result.bin`, where to read decompression input
    - `output_folder`: where to dump decompressed images
    - `verbose`: true by default, it shows progress bars for the process.

Two implementations of compression/decompresion are provided under `improved_compression` package, `fast_*` ones are just vectorized implementations of default ones. The fast ones require `image-processing-toolkit` function `blockproc`, and uses `tensorprod` to make all `dct` ops vectorized. The basic algorithm is much slows (~20 seconds to compress 120 frames) because it uses `utils.frame_to_mb` and performs all compression operations without vectorization. We don't use those utils in improved algorithm, and apply compression pipepeline directly to image frames (~5 seconds to compress 120 frames). See more details under `improved_compression.fast_compress.m`

NOTE: Setting `verbose` parameter to true introduces a minor overhead.


## Utils && Analysis Scripts

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

These utils are used internally for internal use, they may not be well documented.
```
└── analysis
    ├── algo2_params_analysis.m
    ├── compress_range.m
    ├── gop_size_to_compression_analysis.m
    ├── gop_to_compression_executor.sh
    └── psnr_analysis.m
```
These scripts were used to generate report data, some of them include scratch work and may not work right away.

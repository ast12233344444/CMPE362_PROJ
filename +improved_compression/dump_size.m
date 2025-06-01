% Calculates the total size of compressed data without writing to a file.

% INPUT:
% compressed_data - Struct containing compressed data and metadata.

% OUTPUT:
% compressed_size - Total size of the compressed data (in bytes).

% EXPECTED STRUCT FORMAT FOR compressed_data:
% compressed_data.header:
%   - GOP_size: Integer, size of Group of Pictures.
%   - num_B: Integer, number of B-frames per GOP.
%   - quantization_matrix: Matrix used for quantization.
%   - num_images: Integer, total number of images.
%   - image_size: Array [height, width, channels].
%   - layer_sizes: Array of integers, sizes of compressed layers.
%
% compressed_data.data:
%   - Array of int8, compressed macroblock data.

% PROCESS:
% 1. Sum the sizes of header metadata (e.g., GOP size, quantization matrix, image dimensions).
% 2. Add the size of compressed macroblock data.
% 3. Return the total size in bytes.
function compressed_size = dump_size(compressed_data)
    header = compressed_data.header;
    compressed_size = 0;
    
    compressed_size = compressed_size + 4; % GOP_size (int32)
    compressed_size = compressed_size + 4; % num_B (int32)
    % size of quantization_matrix (int32)
    compressed_size = compressed_size + 4 * numel(size(header.quantization_matrix)); 
    % quantization_matrix (uint8)
    compressed_size = compressed_size + 4 * numel(header.quantization_matrix(:));
    compressed_size = compressed_size + 4; % num_images (int32)
    compressed_size = compressed_size + 4 * numel(header.image_size); % image_size (int32)
    compressed_size = compressed_size + 4 * numel(header.layer_sizes); % layer_sizes (int32)
    
    % size of data matrix (int32)
    compressed_size = compressed_size + 4 * numel(size(compressed_data.data)); 
    compressed_size = compressed_size + numel(compressed_data.data); % data matrix (int8)
end

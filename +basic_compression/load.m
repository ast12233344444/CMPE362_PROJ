% Reads compressed data from a binary file and reconstructs its structure.

% INPUT:
% fname - Name of the input binary file.

% OUTPUT:
% compressed_data - Struct containing compressed data and metadata.

% EXPECTED STRUCT FORMAT FOR compressed_data:
% compressed_data.header:
%   - GOP_size: Integer, size of Group of Pictures.
%   - quantization_matrix: Matrix used for quantization.
%   - num_images: Integer, total number of images.
%   - image_size: Array [height, width, channels].
%   - layer_sizes: Array of integers, sizes of compressed layers.
%
% compressed_data.data:
%   - Array of int8, compressed macroblock data.

% PROCESS:
% 1. Read header metadata (e.g., GOP size, quantization matrix, image dimensions).
% 2. Read compressed macroblock data and reshape it based on metadata.
% 3. Return the reconstructed struct.
function compressed_data = load(fname)
    fid = fopen(fname, 'r');
    
    % Read header information
    GOP_size = fread(fid, 1, 'int32');
    qsize = fread(fid, 2, 'int32');
    quantization_matrix = int32(reshape(fread(fid, prod(qsize), 'uint8'), qsize'));
    
    num_images = fread(fid, 1, 'int32');
    image_size = fread(fid, 3, 'int32');
    layer_sizes = fread(fid, image_size(3), 'int32');

    data_size = fread(fid, 2, 'int32');
    data = fread(fid,prod(data_size), 'int8');

    compressed_data =  struct(...
        "header", struct('GOP_size', GOP_size, ...
                         'quantization_matrix', quantization_matrix, ...
                         'num_images', num_images, ...
                         'image_size', image_size, ...
                         'layer_sizes', layer_sizes ...
                     ), ...
        "data", reshape(data, data_size') ...
    );
    fclose(fid);
end

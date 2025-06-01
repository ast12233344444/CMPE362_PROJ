% Saves compressed data to a binary file.

% INPUTS:
% fname            - Name of the output file.
% compressed_data  - Struct containing compressed data and metadata.

% OUTPUT:
% compressed_size  - Total size of the written data (in bytes).

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
% 1. Write header metadata (e.g., GOP size, quantization matrix, image dimensions).
% 2. Write compressed macroblock data.
% 3. Return the total size of the written data.
function compressed_size = dump(fname,compressed_data)
    fid = fopen(fname, 'w');

    header = compressed_data.header;
    compressed_size = 0;
    compressed_size = compressed_size + fwrite(fid, header.GOP_size, 'int32');
    compressed_size = compressed_size + fwrite(fid, size(header.quantization_matrix), 'int32');
    compressed_size = compressed_size + fwrite(fid, header.quantization_matrix(:), 'uint8');

    compressed_size = compressed_size + fwrite(fid, header.num_images, 'int32');
    compressed_size = compressed_size + fwrite(fid, header.image_size, 'int32');
    compressed_size = compressed_size + fwrite(fid, header.layer_sizes, 'int32');

    compressed_size = compressed_size + fwrite(fid, size(compressed_data.data), 'int32');
    compressed_size = compressed_size + fwrite(fid, compressed_data.data, 'int8');
    fclose(fid);
end

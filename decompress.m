fid = fopen('result.bin', 'r');

GOP_size = fread(fid, 1, 'int32');

qsize = fread(fid, 2, 'int32');
quantization_matrix = double(reshape(fread(fid, prod(qsize), 'uint8'), qsize'));

frames_to_blocks = fread(fid, 3, 'int32')';
block_sizes = fread(fid, 2, 'int32');
layer_sizes = fread(fid, 3, 'int32');

zigzagged_blocks_size = fread(fid, 2, 'int32');

zigzagged_blocks = reshape( ...
    fread(fid, prod(zigzagged_blocks_size), 'int8'), ...
    zigzagged_blocks_size');

fclose(fid);

images = basic_compression.decompress(zigzagged_blocks, layer_sizes, frames_to_blocks, block_sizes, quantization_matrix, GOP_size);
output_folder = 'decompressed';  % folder to save images

% Create the output folder if it doesn't exist
if ~exist(output_folder, 'dir')
    mkdir(output_folder);
end

for k = 1:length(images)
    filename = fullfile(output_folder, sprintf('frame_%03d.png', k));
    imwrite(images{k}, filename);
end


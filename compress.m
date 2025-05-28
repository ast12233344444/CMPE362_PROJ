file = fullfile("./video_data", "*.jpg");
files = dir(file);

quantization_matrix = [
 16 , 11 , 10 , 16 , 24 , 40 , 51 , 61;
 12 , 12 , 14 , 19 , 26 , 58 , 60 , 55;
 14 , 13 , 16 , 24 , 40 , 57 , 69 , 56;
 14 , 17 , 22 , 29 , 51 , 87 , 80 , 62;
 18 , 22 , 37 , 56 , 68 , 109 , 103 , 77;
 24 , 35 , 55 , 64 , 81 , 104 , 113 , 92;
 49 , 64 , 78 , 87 , 103 , 121 , 120 , 101;
 72 , 92 , 95 , 98 , 112 , 100 , 103 , 99;
];

GOP_size = 15;


%Sort filenames alphabetically
[~, idx] = sort({files.name});
files = files(idx);


images = [];
original_size = 0;
% Loop through and read images
for k = 1:length(files)
    filename = files(k).name;
    file = fullfile("./video_data", filename);
    img = imread(file);

    images{end+1} = img;
    original_size = original_size +prod(size(img));
end

[zigzagged_blocks, layer_sizes, frame_to_blocks, block_sizes] = basic_compression.compress(images, quantization_matrix, GOP_size);
fid = fopen('result.bin', 'w');

compressed_size = 0;
compressed_size = compressed_size + fwrite(fid, GOP_size, 'int32');
compressed_size = compressed_size + fwrite(fid, size(quantization_matrix), 'int32');
compressed_size = compressed_size + fwrite(fid, quantization_matrix(:), 'uint8');

compressed_size = compressed_size + fwrite(fid, frame_to_blocks, 'int32');
compressed_size = compressed_size + fwrite(fid, block_sizes, 'int32');
compressed_size = compressed_size + fwrite(fid, layer_sizes, 'int32');

compressed_size = compressed_size + fwrite(fid, size(zigzagged_blocks), 'int32');
compressed_size = compressed_size + fwrite(fid, zigzagged_blocks, 'int8');
fclose(fid);

comp_ratio = double(original_size) / double(compressed_size);

fprintf('compression ratio: %f\n', comp_ratio);

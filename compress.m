set(0, 'DefaultFigureRenderer', 'painters')

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

GOP_size = 30;
verbose = true;


%Sort filenames alphabetically
[~, idx] = sort({files.name});
files = files(idx);


images = [];
original_size = 0;
% Loop through and read images
for k = 1:length(files)
    filename = files(k).name;
    file = fullfile("./video_data", filename);
    img = double(imread(file));

    images{k} = img;
    original_size = original_size + numel(img);
end

tic;
compressed_data = basic_compression.compress(images, quantization_matrix, GOP_size,verbose);
compressed_size = basic_compression.dump('result.bin',compressed_data);
comp_ratio = double(original_size) / double(compressed_size);
elapsed_time = toc;

fprintf('GOP_size: %d, Compression Ratio: %f, Elapsed: %f seconds\n', GOP_size,comp_ratio, elapsed_time);

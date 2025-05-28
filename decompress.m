fid = fopen('result.bin', 'r');

compressed_data = basic_compression.load('result.bin');

images = basic_compression.decompress(compressed_data);
output_folder = 'decompressed';  % folder to save images

% Create the output folder if it doesn't exist
if ~exist(output_folder, 'dir')
    mkdir(output_folder);
end

for k = 1:length(images)
    filename = fullfile(output_folder, sprintf('frame_%03d.png', k));
    imwrite(images{k}, filename);
end


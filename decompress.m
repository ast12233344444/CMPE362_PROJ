set(0, 'DefaultFigureRenderer', 'painters')

input_path = 'result.bin';
output_folder = 'decompressed';  % folder to save images
verbose = true;

compressed_data = basic_compression.load(input_path);
images = basic_compression.decompress(compressed_data, verbose);

% Create the output folder if it doesn't exist
if ~exist(output_folder, 'dir')
    mkdir(output_folder);
end

for k = 1:length(images)
    filename = fullfile(output_folder, sprintf('frame_%03d.png', k));
    imwrite(images{k}, filename);
end


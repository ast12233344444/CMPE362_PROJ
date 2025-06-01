input_path = 'result.bin';
compressed_data = improved_compression.load(input_path);
output_folder = 'decompressed';  % folder to save images
verbose = true;

 
images = improved_compression.fast_decompress(compressed_data,verbose);

if ~exist(output_folder, 'dir')
    mkdir(output_folder);
end

h = waitbar(0,sprintf('Dumping uncompressed frames under `%s`...', output_folder));
for k = 1:length(images)
    filename = fullfile(output_folder, sprintf('frame_%03d.png', k));
    imwrite(images{k}, filename);
    waitbar(k/length(images), h)
end
close(h)

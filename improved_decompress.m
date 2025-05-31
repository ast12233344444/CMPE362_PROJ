compressed_data = improved_compression.load('result.bin');
output_folder = 'decompressed';  % folder to save images

 
images = improved_compression.fast_decompress(compressed_data,true);

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

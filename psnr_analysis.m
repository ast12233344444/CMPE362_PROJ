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

%Sort filenames alphabetically
[~, idx] = sort({files.name});
files = files(idx);

images = [];
original_size = 0;
for k = 1:length(files)
    filename = files(k).name;
    file = fullfile("./video_data", filename);
    img = imread(file);

    images{end+1} = img;
    original_size = original_size +numel(img);
end

GOP_sizes = [1, 15, 30];
psnr_results = cell(1, length(GOP_sizes));

for g = 1:length(GOP_sizes)
    GOP_size = GOP_sizes(g);
    
    % Compress and decompress images
    compressed_data = basic_compression.compress(images, quantization_matrix, GOP_size, true);
    compressed_size = basic_compression.dump_size(compressed_data);
    decompressed_images = basic_compression.decompress(compressed_data);
    
    % Compute PSNR for each frame
    psnr_values = zeros(1, length(images));
    for k = 1:length(images)
        original_frame = images{k};
        decompressed_frame = decompressed_images{k};
        
        psnr_values(k) = utils.psnr(original_frame, decompressed_frame);
    end
    
    psnr_results{g} = psnr_values;

    avg_time = (avg_time*(GOP_size-1) + elapsed_time)/GOP_size;
    
    fprintf('Time for GOP_size %d: %f seconds\n', GOP_size, elapsed_time);
    fprintf('Estimated time left: %f mins\n', avg_time*(length(GOP_sizes)-g)/60);
end

% Plot PSNR curves
figure;
hold on;
colors = ['r', 'g', 'b']; % Colors for different GOP sizes
for g = 1:length(GOP_sizes)
    plot(1:length(images), psnr_results{g}, colors(g), 'DisplayName', sprintf('GOP Size %d', GOP_sizes(g)));
end
hold off;

xlabel('Frame Number');
ylabel('PSNR (dB)');
title('PSNR Curves for Different GOP Sizes');
legend('show');
grid on;

saveas(gcf, "assets/psnr_analysis.png")

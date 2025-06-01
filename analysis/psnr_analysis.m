%% setup
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

Q1 = [ ...
    3  5  7  9 11 13 15 17;
    5  7  9 11 13 15 17 19;
    7  9 11 13 15 17 19 21;
    9 11 13 15 17 19 21 23;
   11 13 15 17 19 21 23 25;
   13 15 17 19 21 23 25 27;
   15 17 19 21 23 25 27 29;
   17 19 21 23 25 27 29 31 ...
];
Q3 = Q1*3;
Q5 = Q1*5;
Q7 = Q1*7;
Q9 = Q1*9;
Q17 = Q1*17;

%Sort filenames alphabetically
[~, idx] = sort({files.name});
files = files(idx);

images = cell(length(files),1);
original_size = 0;
for k = 1:length(files)
    filename = files(k).name;
    file = fullfile("./video_data", filename);
    img = double(imread(file));

    images{k} = img;
    original_size = original_size +numel(img);
end

%% Plot PSNR curves

GOP_sizes = [1, 15, 30];
QS = {Q0, Q0, Q0, Q0};
colors = ['r', 'g', 'b'];

%% improved
GOP_sizes = [3, 15, 30];
num_Bs = [1,3,10];
QS = {Q0, Q0, Q0, Q0};
psnr_results_improved = imroved_algorithm_results(GOP_sizes,num_Bs,images,QS,original_size);

figure;
hold on;
for g = 1:length(GOP_sizes)
    plot(1:length(images), psnr_results_improved{g}, colors(g), 'DisplayName', sprintf('GOP Size %d, Num-B: %d', GOP_sizes(g), num_Bs(g)));
end
hold off;

xlabel('Frame Number');
ylabel('PSNR (dB)');
title('PSNR Curves for Different GOP Layouts');
legend('show', 'location','best');
grid on;

saveas(gcf, "assets/psnr_analysis_improved.png")


GOP_sizes = [15, 15, 15];
num_Bs = [2,2,2];
QS = {Q0, Q3, Q5, Q7};
psnr_results_improved = imroved_algorithm_results(GOP_sizes,num_Bs,images,QS,original_size);

figure;
hold on;
for g = 1:length(GOP_sizes)
    plot(1:length(images), psnr_results_improved{g}, colors(g), 'DisplayName', sprintf('GOP Size %d, Num-B: %d, Quantization: Q%d', GOP_sizes(g), num_Bs(g), g-1));
end
hold off;

xlabel('Frame Number');
ylabel('PSNR (dB)');
title('PSNR Curves for Different Quantization Matrices');
legend('show', 'location','best');
grid on;

saveas(gcf, "assets/psnr_analysis_improved_quantization.png")

%% basic
psnr_results = psnr_results_basic(GOP_sizes,images,QS,original_size);

figure;
hold on;

for g = 1:length(GOP_sizes)
    plot(1:length(images), psnr_results{g}, colors(g), 'DisplayName', sprintf('GOP Size %d', GOP_sizes(g)));
end
hold off;

xlabel('Frame Number');
ylabel('PSNR (dB)');
title('PSNR Curves for Different GOP Sizes');
legend('show', 'location','best');
grid on;

saveas(gcf, "assets/psnr_analysis.png")


%% utils

function psnr_results = psnr_results_basic(GOP_sizes,images,qs,original_size)
    psnr_results = cell(1, length(GOP_sizes));
    
    avg_time = 25; % educated guess
    fprintf('Estimated time left: %.0f secs\n', avg_time*(length(GOP_sizes)));
    for g = 1:length(GOP_sizes)  
        tic;
        GOP_size = GOP_sizes(g);
        Q = qs{g};
    
        % Compress and decompress images
        compressed_data = basic_compression.compress(images, Q, GOP_size, true);
        compressed_size = basic_compression.dump_size(compressed_data);
        decompressed_images = basic_compression.decompress(compressed_data, true);
    
        % Compute PSNR for each frame
        psnr_values = zeros(1, length(images));
        for k = 1:length(images)
            original_frame = images{k};
            decompressed_frame = decompressed_images{k};
    
            psnr_values(k) = utils.psnr(original_frame, decompressed_frame);
        end
    
        psnr_results{g} = psnr_values;
    
        elapsed_time = toc;
        avg_time = (avg_time*(g-1) + elapsed_time)/length(GOP_sizes);
    
    
        
        fprintf('Compression ratio = %f', original_size/compressed_size);
        fprintf('Time for GOP_size %d: %f seconds\n', GOP_size, elapsed_time);
        fprintf('Estimated time left: %.0f secs\n', avg_time*(length(GOP_sizes)-g));
    end
end


function psnr_results = imroved_algorithm_results(GOP_sizes,num_Bs,images,qs,original_size)
    psnr_results = cell(1, length(GOP_sizes));
    avg_time = 10; % educated guess
    fprintf('Estimated time left: %.0f secs\n', avg_time*(length(GOP_sizes)));
    for g = 1:length(GOP_sizes)  
        tic;
        GOP_size = GOP_sizes(g);
        num_B = num_Bs(g);
        Q = qs{g};
    
        % Compress and decompress images
        compressed_data = improved_compression.fast_compress(images, Q, GOP_size, num_B, true);
        compressed_size = improved_compression.dump_size(compressed_data);
        decompressed_images = improved_compression.fast_decompress(compressed_data, true);
    
        % Compute PSNR for each frame
        psnr_values = zeros(1, length(images));
        for k = 1:length(images)
            original_frame = images{k};
            decompressed_frame = decompressed_images{k};
    
            psnr_values(k) = utils.psnr(original_frame, decompressed_frame);
        end
    
        psnr_results{g} = psnr_values;
    
        elapsed_time = toc;
        avg_time = (avg_time*(g-1) + elapsed_time)/length(GOP_sizes);
    
    
        fprintf('Compression ratio = %f', original_size/compressed_size);
        fprintf('Time for GOP_size %d: num_B: %d %f seconds\n', GOP_size, num_B, elapsed_time);
        fprintf('Estimated time left: %.0f secs\n', avg_time*(length(GOP_sizes)-g));
    end
end

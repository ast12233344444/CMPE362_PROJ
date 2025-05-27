file = fullfile("./video_data", "*.jpg")
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
GOP_size = 5

function output = zigzag(input)
    [rows, cols] = size(input);
    if rows ~= cols
        error('Input matrix must be square');
    end

    n = rows;  % size of the matrix
    output = zeros(1, n * n);  % preallocate output vector
    index = 1;

    for s = 1:(2*n - 1)
        if mod(s, 2) == 0
            % Even sum of indices: go bottom to top
            i_start = max(1, s - n + 1);
            i_end = min(s, n);
            for i = i_start:i_end
                j = s - i + 1;
                output(index) = input(i, j);
                index = index + 1;
            end
        else
            % Odd sum of indices: go top to bottom
            i_start = min(s, n);
            i_end = max(1, s - n + 1);
            for i = i_start:-1:i_end
                j = s - i + 1;
                output(index) = input(i, j);
                index = index + 1;
            end
        end
    end
end

function rle = run_length_encode(input)
    if isempty(input)
        rle = [];
        return;
    end

    input = input(:);  % ensure column vector
    n = length(input);

    change_idx = [1; find(diff(input) ~= 0) + 1; n + 1];

    symbols = input(change_idx(1:end-1));
    counts = diff(change_idx);

    rle = [symbols counts];  % Each row is a "tuple": [value, count]
end

function [compressed_data, layer_sizes, frame_to_block, block_size] = compress_data(images, quantization_matrix, GOP_size)
    
    
    mblocks = []
    %convert images to blocks
    for k = 1:length(images)
        if mod(k-1, GOP_size) == 0 
            image = int32(images{k});
            blocks = frame_to_mb(image);
            mblocks{end+1} = blocks;
        else
            image_current = int32(images{k});
            image_prev=  int32(images{k-1});
            diff = image_current - image_prev;
            blocks = frame_to_mb(diff);
            mblocks{end+1} = blocks;
        end
    
    end
        
        
    %convert blocks with DCT
    for k = 1:length(images)
        mblock = mblocks{k}; 
        for i = 1:size(mblock, 1)
            for j = 1:size(mblock, 2)
                block = double(mblock{i, j});
                R = block(:, :, 1);
                G = block(:, :, 2);
                B = block(:, :, 3);
                mblock{i, j} = cat(3, dct2(R), dct2(G), dct2(B));
            end
        end
        mblocks{k} = mblock;
    end
        
    
        
    for k = 1:length(images)
       mblock = mblocks{k};
       for i = 1:size(mblock, 1)
           for j = 1:size(mblock, 2)
               block = mblock{i, j};
               R = block(:, :, 1);
               G = block(:, :, 2);
               B = block(:, :, 3);
               R = R ./ quantization_matrix;
               G = G ./ quantization_matrix;
               B = B ./ quantization_matrix;
               mblock{i, j} = cat(3, R, G, B);
            end
        end
        mblocks{k} = mblock;
    end
    
    Rlayer_cell = {}
    Glayer_cell = {}
    Blayer_cell = {}
    disp("size for mblock:"+ size(mblock));
    for k = 1:length(images)
        mblock = mblocks{k};
        for i = 1:size(mblock, 1)
            for j = 1:size(mblock, 2)
                block = int8(mblock{i,j});
                R = block(:, :, 1);
                G = block(:, :, 2);
                B = block(:, :, 3);
                Rzb = zigzag(R);
                Gzb = zigzag(G);
                Bzb = zigzag(B);
                Rrle = run_length_encode(Rzb);
                Grle = run_length_encode(Gzb);
                Brle = run_length_encode(Bzb);

                
                Rlayer_cell{end+1} = Rrle;
                Glayer_cell{end+1} = Grle;
                Blayer_cell{end+1} = Brle;
            end
        end
    end
    Rlayer = vertcat(Rlayer_cell{:});
    Glayer = vertcat(Glayer_cell{:});
    Blayer = vertcat(Blayer_cell{:});

    Rlayer_size = size(Rlayer, 1)
    Glayer_size = size(Glayer, 1)
    Blayer_size = size(Blayer, 1)

    compressed_data = [ Rlayer; Glayer; Blayer];
    layer_sizes = [Rlayer_size, Glayer_size, Blayer_size];
    [brows, bcols] = size(mblocks{1});
    frame_to_block = [length(images), brows, bcols];
    block_size = [8, 8];
end

% Sort filenames alphabetically
[~, idx] = sort({files.name});
files = files(idx);
    
    
images = []
% Loop through and read images
for k = 1:length(files)
    filename = files(k).name;
    file = fullfile("./video_data", filename);
    img = imread(file);
     
    images{end+1} = img;
    % Do something with img
    fprintf('Read image: %s\n', filename);
end

[zigzagged_blocks, layer_sizes, frame_to_blocks, block_sizes] = compress_data(images, quantization_matrix, GOP_size);
[rows, cols] = size(zigzagged_blocks);
fid = fopen('result.bin', 'w');
fwrite(fid, [rows, cols], 'int32');  % Write size as header
fwrite(fid, frame_to_blocks, 'int32');
fwrite(fid, block_sizes, 'int32');
fwrite(fid, layer_sizes, 'int32');
fwrite(fid, zigzagged_blocks, 'int8');
fclose(fid);

numBytes = numel(zigzagged_blocks);

uncompressed_size = 480 * 360 * 3 * 120;

comp_ratio = double(uncompressed_size) / double(numBytes);

disp(sprintf('compression ratio: %f', comp_ratio))

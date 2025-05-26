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

function compressed_data = compress_data(images, quantization_matrix, GOP_size)
    
    
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
    
    
    compressed_data = {}
    for k = 1:length(images)
        mblock = mblocks{k};
        zigzagged_block = []
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
                maxLength = max([size(Rrle,1), size(Grle,1), size(Brle,1)]);

                Rpad = [Rrle; zeros(maxLength - size(Rrle,1), 2)];
                Gpad = [Grle; zeros(maxLength - size(Grle, 1), 2)];
                Bpad = [Brle; zeros(maxLength - size(Brle, 1), 2)];

                zb = cat(3, Rpad, Gpad, Bpad);
                zigzagged_block = [zigzagged_block; zb];
            end
        end
        compressed_data{end+1} = zigzagged_block;
    end
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

zigzagged_blocks = compress_data(images, quantization_matrix, GOP_size);
fid = fopen('result.bin', 'w');
bytes = getByteStreamFromArray(zigzagged_blocks);
fwrite(fid, bytes, 'uint8');
fclose(fid);

numBytes = numel(bytes);

uncompressed_size = 480 * 360 * 3 * 120;

comp_ratio = double(uncompressed_size) / double(numBytes);

disp(sprintf('compression ratio: %f', comp_ratio))

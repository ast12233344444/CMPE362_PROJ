%load("-mat", "result.bin", "zigzagged_blocks")


fid = fopen('result.bin', 'r');
bytes = fread(fid, '*uint8');
fclose(fid);

zigzagged_blocks = getArrayFromByteStream(bytes);


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

function output = run_length_decode(rle)
    if isempty(rle)
        output = [];
        return;
    end

    % Preallocate output length for efficiency
    total_length = sum(rle(:,2));
    output = zeros(total_length, 1);

    idx = 1;
    for i = 1:size(rle, 1)
        val = rle(i, 1);
        count = rle(i, 2);
        output(idx:idx+count-1) = val;
        idx = idx + count;
    end
end

function output = inverse_zigzag(input)
    n = sqrt(length(input));
    if mod(n,1) ~= 0
        error('Input length is not a perfect square');
    end

    n = int32(n);
    output = zeros(n, n);
    index = 1;

    for s = 1:(2*n - 1)
        if mod(s, 2) == 0
            % Even sum of indices: bottom to top
            i_start = max(1, s - n + 1);
            i_end = min(s, n);
            for i = i_start:i_end
                j = s - i + 1;
                output(i, j) = input(index);
                index = index + 1;
            end
        else
            % Odd sum of indices: top to bottom
            i_start = min(s, n);
            i_end = max(1, s - n + 1);
            for i = i_start:-1:i_end
                j = s - i + 1;
                output(i, j) = input(index);
                index = index + 1;
            end
        end
    end
end

function images = decompress_compressed_data(compressed_data, quantization_matrix, GOP_size)
    mblocks = []
    for k=1:length(compressed_data)
        zigzagged_block = compressed_data{k};
        mblock = [];
        for i = 1:size(zigzagged_block, 1)
            for j = 1:size(zigzagged_block, 2)
                rled_data = zigzagged_block{i, j};
                Rrle = rled_data(:, :, 1);
                Grle = rled_data(:, :, 2);
                Brle = rled_data(:, :, 3);
    
                Rzb = run_length_decode(Rrle);
                Gzb = run_length_decode(Grle);
                Bzb = run_length_decode(Brle);
    
                R = inverse_zigzag(Rzb);
                G = inverse_zigzag(Gzb);
                B = inverse_zigzag(Bzb);
    
                mblock{i, j} =  double(cat(3, R, G, B));
            end
        end
        mblocks{end+1} = mblock;
    end
    
    
    for k = 1:length(mblocks)
       mblock = mblocks{k};
       for i = 1:size(mblock, 1)
           for j = 1:size(mblock, 2)
               block = mblock{i, j};
               R = block(:, :, 1);
               G = block(:, :, 2);
               B = block(:, :, 3);
               R = R .* quantization_matrix;
               G = G .* quantization_matrix;
               B = B .* quantization_matrix;
               mblock{i, j} = cat(3, R, G, B);
            end
        end
        mblocks{k} = mblock;
    end
    
    
    for k = 1:length(mblocks)
        mblock = mblocks{k}; 
        for i = 1:size(mblock, 1)
            for j = 1:size(mblock, 2)
                block = mblock{i, j};
                R = block(:, :, 1);
                G = block(:, :, 2);
                B = block(:, :, 3);
                mblock{i, j} = cat(3, idct2(R), idct2(G), idct2(B));
            end
        end
        mblocks{k} = mblock;
    end
    
    
    images = []
    for k = 1:length(mblocks)   
        if mod(k-1, GOP_size) == 0 
            mblock = mblocks{k};
            image = mb_to_frame(mblock);
            images{end+1} = image;
        else
            mblock = mblocks{k};
            image_prev= images{k-1};
            diff =  mb_to_frame(mblock);
            image_current = image_prev + diff;
            images{end+1} = image_current;
        end
    end
   
    for k = 1:length(mblocks)
        images{k} = uint8(images{k})
    end
end


images = decompress_compressed_data(zigzagged_blocks, quantization_matrix, GOP_size)
output_folder = 'decomp_test';  % folder to save images

% Create the output folder if it doesn't exist
if ~exist(output_folder, 'dir')
    mkdir(output_folder);
end

for k = 1:length(images)
    filename = fullfile(output_folder, sprintf('frame_%03d.png', k));
    imwrite(images{k}, filename);
end


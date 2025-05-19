file = fullfile("./video_data", "*.jpg")
files = dir(file);

% Sort filenames alphabetically
[~, idx] = sort({files.name});
files = files(idx);


images = []
% Loop through and read images
for k = 1:length(files)
    filename = files(k).name;
    file = fullfile("./video_data", filename);
    img = imread(file);
    
    images{end+1} = double(img);
    % Do something with img
    fprintf('Read image: %s\n', filename);
end

mblocks = []
%convert images to blocks
for k = 1:length(files)
    image = images{k};
    blocks = frame_to_mb(image);
    mblocks{end+1} = blocks;
end


%convert blocks with DCT
for k = 1:length(files)
    mblock = mblocks{k}; 
    for i = 1:size(mblock, 1)
        for j = 1:size(mblock, 2)
            block = mblock{i, j};
            R = block(:, :, 1);
            G = block(:, :, 2);
            B = block(:, :, 3);
            mblock{i, j} = cat(3, dct2(R), dct2(G), dct2(B));
        end
    end
    mblocks{k} = mblock;
end

quantization_matrix = [
 16 , 11 , 10 , 16 , 24 , 40 , 51 , 61;
 12 , 12 , 14 , 19 , 26 , 58 , 60 , 55;
 14 , 13 , 16 , 24 , 40 , 57 , 69 , 56;
 14 , 17 , 22 , 29 , 51 , 87 , 80 , 62;
 18 , 22 , 37 , 56 , 68 , 109 , 103 , 77;
 24 , 35 , 55 , 64 , 81 , 104 , 113 , 92;
 49 , 64 , 78 , 87 , 103 , 121 , 120 , 101;
 72 , 92 , 95 , 98 , 112 , 100 , 103 , 99;
 ]

for k = 1:length(files)
    mblock = mblocks{k}
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





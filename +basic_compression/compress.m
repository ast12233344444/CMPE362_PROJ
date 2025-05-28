function [compressed_data, layer_sizes, frame_to_block, block_size] = compress(images, quantization_matrix, GOP_size)
    mblocks = [];
    %convert images to blocks
    for k = 1:length(images)
        if mod(k-1, GOP_size) == 0 
            image = int32(images{k});
            blocks = utils.frame_to_mb(image);
            mblocks{end+1} = blocks;
        else
            image_current = int32(images{k});
            image_prev=  int32(images{k-1});
            diff = image_current - image_prev;
            blocks = utils.frame_to_mb(diff);
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
    
    Rlayer_cell = {};
    Glayer_cell = {};
    Blayer_cell = {};
    disp("size for mblock:"+ size(mblock));
    for k = 1:length(images)
        mblock = mblocks{k};
        for i = 1:size(mblock, 1)
            for j = 1:size(mblock, 2)
                block = int8(mblock{i,j});
                R = block(:, :, 1);
                G = block(:, :, 2);
                B = block(:, :, 3);
                Rzb = utils.zigzag(R);
                Gzb = utils.zigzag(G);
                Bzb = utils.zigzag(B);
                Rrle = utils.run_length_encode(Rzb);
                Grle = utils.run_length_encode(Gzb);
                Brle = utils.run_length_encode(Bzb);

                
                Rlayer_cell{end+1} = Rrle;
                Glayer_cell{end+1} = Grle;
                Blayer_cell{end+1} = Brle;
            end
        end
    end
    Rlayer = vertcat(Rlayer_cell{:});
    Glayer = vertcat(Glayer_cell{:});
    Blayer = vertcat(Blayer_cell{:});

    Rlayer_size = size(Rlayer, 1);
    Glayer_size = size(Glayer, 1);
    Blayer_size = size(Blayer, 1);

    compressed_data = [ Rlayer; Glayer; Blayer];
    layer_sizes = [Rlayer_size, Glayer_size, Blayer_size];
    [brows, bcols] = size(mblocks{1});
    frame_to_block = [length(images), brows, bcols];
    block_size = [8, 8];
end

function images = decompress(compressed_data, layer_sizes, frames_to_blocks, block_sizes, quantization_matrix, GOP_size)
    Rsize = layer_sizes(1);
    Gsize = layer_sizes(2);
    Bsize = layer_sizes(3);
    Rlayer = compressed_data(1:Rsize, :);
    Glayer = compressed_data(Rsize+1:Rsize+Gsize, :);
    Blayer = compressed_data(Rsize+Gsize+1:Rsize+Gsize+Bsize, :);

    Rlayer = utils.run_length_decode(Rlayer);
    Glayer = utils.run_length_decode(Glayer);
    Blayer = utils.run_length_decode(Blayer);

    mblocks = [];
    for k = 1:frames_to_blocks(1)
        mblock = [];
        for i = 1:frames_to_blocks(2)
            for j = 1:frames_to_blocks(3)
                block_no = (k-1) * frames_to_blocks(2) * frames_to_blocks(3) + (i-1) * frames_to_blocks(3) + (j-1);
                block_start = block_no * block_sizes(1) * block_sizes(2) + 1;
                block_end = (block_no + 1) * block_sizes(1) * block_sizes(2);

                Rzb = Rlayer(block_start:block_end);
                Gzb = Glayer(block_start:block_end);
                Bzb = Blayer(block_start:block_end);

                R = utils.inverse_zigzag(Rzb);
                G = utils.inverse_zigzag(Gzb);
                B = utils.inverse_zigzag(Bzb);
    
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
    
    
    images = [];
    for k = 1:length(mblocks)   
        if mod(k-1, GOP_size) == 0 
            mblock = mblocks{k};
            image = utils.mb_to_frame(mblock);
            images{end+1} = image;
        else
            mblock = mblocks{k};
            image_prev= images{k-1};
            diff =  utils.mb_to_frame(mblock);
            image_current = image_prev + diff;
            images{end+1} = image_current;
        end
    end
   
    for k = 1:length(mblocks)
        images{k} = uint8(images{k});
    end
end

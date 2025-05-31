function mblocks = zigzag_rle_decode(compressed_data)
    Rsize = compressed_data.header.layer_sizes(1);
    Gsize = compressed_data.header.layer_sizes(2);
    Bsize = compressed_data.header.layer_sizes(3);
    Rlayer = compressed_data.data(1:Rsize, :);
    Glayer = compressed_data.data(Rsize+1:Rsize+Gsize, :);
    Blayer = compressed_data.data(Rsize+Gsize+1:Rsize+Gsize+Bsize, :);
    
    
    
    num_images = compressed_data.header.num_images;
    image_size = compressed_data.header.image_size;
    
    qsize = size(compressed_data.header.quantization_matrix);
    
    frames_to_blocks = [num_images, image_size(1)/qsize(1), image_size(2)/qsize(2)];
    block_sizes = [qsize(1), qsize(2)];
    
    h1 = waitbar(0, 'Decoding run-length encoded data...');
    Rlayer = utils.run_length_decode(Rlayer);
    waitbar(1/3, h1);
    Glayer = utils.run_length_decode(Glayer);
    waitbar(2/3, h1);
    Blayer = utils.run_length_decode(Blayer);
    waitbar(1, h1);
    close(h1);
    
    mblocks = [];
    num_blocks = frames_to_blocks(1);
    
    h2 = waitbar(0, 'Reconstructing blocks from compressed data...');
    for k = 1:num_blocks
        waitbar(k / num_blocks, h2);
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
    
                mblock{i, j} = double(cat(3, R, G, B));
            end
        end
        mblocks{end+1} = mblock;
    end
    close(h2);
end
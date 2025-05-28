function images = decompress(compressed_data, layer_sizes, frames_to_blocks, block_sizes, quantization_matrix, GOP_size)
    Rsize = layer_sizes(1);
    Gsize = layer_sizes(2);
    Bsize = layer_sizes(3);
    Rlayer = compressed_data(1:Rsize, :);
    Glayer = compressed_data(Rsize+1:Rsize+Gsize, :);
    Blayer = compressed_data(Rsize+Gsize+1:Rsize+Gsize+Bsize, :);

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

    % Progress bar for inverse zigzag and block reconstruction
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

    % Progress bar for dequantization
    h3 = waitbar(0, 'Applying dequantization...');
    for k = 1:length(mblocks)
        waitbar(k / length(mblocks), h3);
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
    close(h3);

    % Progress bar for inverse DCT
    h4 = waitbar(0, 'Applying inverse DCT...');
    for k = 1:length(mblocks)
        waitbar(k / length(mblocks), h4);
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
    close(h4);

    images = [];
    num_images = length(mblocks);

    % Progress bar for reconstructing images
    h5 = waitbar(0, 'Reconstructing images...');
    for k = 1:num_images
        waitbar(k / num_images, h5);
        if mod(k-1, GOP_size) == 0
            mblock = mblocks{k};
            image = utils.mb_to_frame(mblock);
            images{end+1} = image;
        else
            mblock = mblocks{k};
            image_prev = images{k-1};
            diff = utils.mb_to_frame(mblock);
            image_current = image_prev + diff;
            images{end+1} = image_current;
        end
    end
    close(h5);

    % Progress bar for converting images to uint8
    h6 = waitbar(0, 'Converting images to uint8...');
    for k = 1:num_images
        waitbar(k / num_images, h6);
        images{k} = uint8(images{k});
    end
    close(h6);
end

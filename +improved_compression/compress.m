% Function to compress a sequence of images using DCT-based compression with 
% Group of Pictures (GOP) structure. Supports I-frames, P-frames, and B-frames.

% INPUTS:
% images               - Cell array of input images (RGB format).
% quantization_matrix  - Matrix used for quantization during compression.
% GOP_size             - Number of frames in each GOP.
% num_B                - Number of B-frames per GOP.
% verbose              - Boolean flag for progress visualization.

% OUTPUT:
% compressed_data      - Struct containing compressed data and metadata.

% PROCESS:
% 1. Convert images to macroblocks.
% 2. Generate GOP layout (I, P, B frames).
% 3. Compress I-frames using DCT and quantization.
% 4. Compress P-frames using motion prediction from previous anchor frames.
% 5. Compress B-frames using bidirectional motion prediction.
% 6. Reconstruct frames for visualization and encode macroblocks using zigzag RLE.
% 7. Return compressed data with metadata.

% NOTE:
% - Utilizes helper functions from `utils` for macroblock conversion, GOP layout generation, 
%   and zigzag RLE encoding.
% - Verbose mode provides a progress bar for each compression stage.
function [compressed_data] = compress(images, quantization_matrix, GOP_size, num_B, verbose)
    N = length(images);
    mblocks_ = cell(N,1);
    for k = 1:N
        mblocks_{k} = utils.frame_to_mb(images{k});
    end

    num_channels = size(images{1}, 3);

    encoded = cell(num_channels,N);
    reconst = cell(num_channels,N);

    gop_layout = utils.generate_gop_layout(GOP_size, N, num_B);

    anchors = sort([gop_layout.I, gop_layout.P]);

    if verbose
        h = waitbar(0, 'Constructing I-Frames... (1/5)');
        k=1;
    end

    for c = 1:num_channels
        compress = @(mb) round(dct2(mb(:,:,c)) ./ quantization_matrix);
        decompress = @(mbc) round(idct2(mbc .* quantization_matrix));
        for I_ix = gop_layout.I
            encoded{c,I_ix} = cellfun(compress, mblocks_{I_ix}, 'UniformOutput', false);
            reconst{c,I_ix} = cellfun(decompress, encoded{c,I_ix}, 'UniformOutput', false);
            if verbose
                waitbar(k/double(length(gop_layout.I)*num_channels), h)
                k=k+1;
            end
        end
    end

    if verbose
        waitbar(0,h,'Constructing P-Frames... (2/5)')
        k = 1;
    end
    for c = 1:num_channels
        compress = @(prev, cur) round(dct2(cur(:,:,c)-prev) ./ quantization_matrix);
        decompress = @(diff, pred) round(idct2(diff .* quantization_matrix))+pred;
        
        for P_ix = gop_layout.P
            prev_ix = anchors(find(anchors < P_ix, 1, 'last'));
            encoded{c,P_ix} = cellfun(compress, reconst{c, prev_ix}, mblocks_{P_ix}, 'UniformOutput', false);
            reconst{c,P_ix} = cellfun(decompress, encoded{c,P_ix}, reconst{c, prev_ix}, 'UniformOutput', false);
            if verbose
                waitbar(k/double(length(gop_layout.P)*num_channels), h)
                k=k+1;
            end
        end
    end


    if verbose
        waitbar(0,h, 'Constructing B-Frames with temporal alpha... (3/5)');
        k = 1;
    end
    for c = 1:num_channels
        for B_ix = gop_layout.B
            prev_ix = anchors(find(anchors < B_ix, 1, 'last'));
            next_ix = anchors(find(anchors > B_ix, 1, 'first'));

            % normalized temporal weight
            alpha = (B_ix - prev_ix) / (next_ix - prev_ix);
            compress_B = @(prev, nxt, cur) round( dct2( cur(:,:,c) - (alpha*nxt + (1-alpha)*prev ) ) ./ quantization_matrix );

            decompress_B = @(diff, prev, nxt) round( idct2( diff .* quantization_matrix ) ) + (alpha*nxt + (1-alpha)*prev);

            encoded{c,B_ix} = cellfun( compress_B, reconst{c, prev_ix}, reconst{c, next_ix}, mblocks_{B_ix}, 'UniformOutput', false);
            reconst{c,B_ix} = cellfun( decompress_B, encoded{c,B_ix}, reconst{c, prev_ix}, reconst{c, next_ix}, 'UniformOutput', false);

           if verbose
                waitbar(k/double(length(gop_layout.B)*num_channels), h)
                k = k + 1;
            end
        end
    end



    waitbar(0,h, 'Generating compressed frames... (4/5)');
    frames = cell(N, 1);
    mblocks = cell(N,1);
    combine_channels = @(R,G,B) cat(3, R,G,B);
    for k = 1:N
        combined = cellfun(combine_channels, reconst{1,k},reconst{2,k}, reconst{3,k},'UniformOutput', false );
        frames{k} = uint8( min(max(utils.mb_to_frame(combined),0),255) );

        mblocks{k} = cellfun(combine_channels, encoded{1,k},encoded{2,k}, encoded{3,k},'UniformOutput', false );
        
        waitbar(k/N, h)
    end

    [R,G,B] = utils.zigzag_rle_encode(mblocks,true);

    close(h);
    compressed_data =  struct(...
        "header", struct('GOP_size', GOP_size, ...
                         'num_B', num_B, ...
                         'quantization_matrix', quantization_matrix, ...
                         'num_images', N, ...
                         'image_size', size(images{1}), ...
                         'layer_sizes', [size(R, 1), size(G, 1), size(B, 1)] ...
                     ), ...
        "data", [R; G; B]);
end


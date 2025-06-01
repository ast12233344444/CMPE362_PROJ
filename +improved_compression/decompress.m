% Function to decompress a sequence of images from DCT-based compressed data.

% INPUTS:
% compressed_data - Struct containing compressed data and metadata.
% verbose         - Boolean flag for progress visualization.

% OUTPUT:
% images          - Cell array of decompressed images (RGB format).

% PROCESS:
% 1. Decode macroblocks using zigzag RLE.
% 2. Generate GOP layout (I, P, B frames).
% 3. Decompress I-frames using inverse DCT and dequantization.
% 4. Decompress P-frames using motion prediction from previous anchor frames.
% 5. Decompress B-frames using bidirectional motion prediction with temporal weighting.
% 6. Combine channels and reconstruct full images.

% NOTE:
% - Utilizes helper functions from `utils` for macroblock decoding, GOP layout generation, 
%   and frame reconstruction.
% - Verbose mode provides a progress bar for each decompression stage.
function images = decompress(compressed_data, verbose)

    quantization_matrix = double(compressed_data.header.quantization_matrix);
    GOP_size = compressed_data.header.GOP_size;
    num_B = compressed_data.header.num_B;
    N = compressed_data.header.num_images;
    C = compressed_data.header.image_size(3);

    mblocks = utils.zigzag_rle_decode(compressed_data);
    encoded = cell(C,N);
    for c = 1:C
        for n = 1:N
            project_channel = @(mb) mb(:,:,c); 
            encoded{c,n} = cellfun(project_channel, mblocks{n}, "UniformOutput",false);
        end
    end
    
    
    gop_layout = utils.generate_gop_layout(GOP_size,N, num_B);
    anchors = sort([gop_layout.I, gop_layout.P]);
    
    reconst = cell(C,N);
    
    if verbose
        h = waitbar(0, 'Decompressing I-Frames... (1/4)');
        k = 1;
    end

    for c = 1:C
        decompress = @(mbc) round(idct2(mbc .* quantization_matrix));
        for I_ix = gop_layout.I
            reconst{c,I_ix} = cellfun(decompress, encoded{c,I_ix}, 'UniformOutput', false);
            if verbose
                waitbar(k/double(length(gop_layout.I)*C), h)
                k=k+1;
            end    
        end
    end
    
    if verbose
        waitbar(0,h,'Decompressing P-Frames... (2/4)')
        k = 1;
    end
    
    
    for c = 1:C
        decompress = @(diff, pred) round(idct2(diff .* quantization_matrix))+pred;
        
        for P_ix = gop_layout.P
            prev_ix = anchors(find(anchors < P_ix, 1, 'last'));
            reconst{c,P_ix} = cellfun(decompress, encoded{c,P_ix}, reconst{c, prev_ix}, 'UniformOutput', false);
            if verbose
                waitbar(k/double(length(gop_layout.P)*C), h)
                k=k+1;
            end
            
        end
    end
    
    if verbose
        waitbar(0,h, 'Decompressing B-Frames with temporal alpha... (3/4)');
        k = 1;
    end
    for c = 1:C
        for B_ix = gop_layout.B
            prev_ix = anchors(find(anchors < B_ix, 1, 'last'));
            next_ix = anchors(find(anchors > B_ix, 1, 'first'));
    
            % compute normalized temporal weight
            alpha = (B_ix - prev_ix) / (next_ix - prev_ix);
    
            decompress = @(diff, prev, nxt) ...
                round( idct2( diff .* quantization_matrix ) ) + (alpha*nxt + (1-alpha)*prev);
    
            reconst{c,B_ix} = cellfun( ...
                decompress, ...
                encoded{c,B_ix}, ...
                reconst{c, prev_ix}, ...
                reconst{c, next_ix}, ...
                'UniformOutput', false);
            if verbose
                waitbar(k/double(length(gop_layout.B)*C), h)
                k = k + 1;
            end
        end
    end
    
    if verbose
        waitbar(0,h, 'Generating uncompressed frames... (4/4)');      
    end
    images = cell(N, 1);
    combine_channels = @(R,G,B) cat(3, R,G,B);
    for k = 1:N
        combined = cellfun(combine_channels, reconst{1,k},reconst{2,k}, reconst{3,k},'UniformOutput', false );
        images{k} = uint8( min(max(utils.mb_to_frame(combined),0),255) );  
        if verbose
            waitbar(k/N, h)
        end
    end
    if verbose
        close(h);
    end
end

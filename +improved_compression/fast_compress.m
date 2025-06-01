% Compresses a sequence of images using DCT-based compression with GOP structure.

% INPUTS:
% images               - Cell array of input images (RGB format).
% quantization_matrix  - Matrix used for quantization during compression.
% GOP_size             - Number of frames in each GOP.
% num_B                - Number of B-frames per GOP.
% verbose              - Boolean flag for progress visualization.

% OUTPUT:
% compressed_data      - Struct containing compressed data and metadata.

% EXPECTED STRUCT FORMAT FOR compressed_data:
% compressed_data.header:
%   - GOP_size: Integer, size of Group of Pictures.
%   - num_B: Integer, number of B-frames per GOP.
%   - quantization_matrix: Matrix used for quantization.
%   - num_images: Integer, total number of images.
%   - image_size: Array [height, width, channels].
%   - layer_sizes: Array of integers, sizes of compressed layers.
%
% compressed_data.data:
%   - Array of encoded macroblock data (R, G, B layers).

% WHY fast_compress:
% This function uses vectorized operations to optimize compression speed, reducing computational overhead compared to traditional iterative methods.

% NOTES ON VECTORIZATION PROCESS:
% - DCT and inverse DCT are applied using matrix multiplications (`tensorprod`) for efficient block-wise transformations.
% - `blockproc` is used for block-wise processing of images, avoiding explicit loops over blocks.
% - Temporal prediction for P-frames and B-frames is calculated using matrix operations instead of pixel-wise iteration.
% - `cellfun` is used for batch processing of macroblocks during encoding.
% These techniques significantly improve performance for large image sequences.
function [compressed_data] = fast_compress(images, quantization_matrix, GOP_size, num_B, verbose)
    N = length(images);

    encoded = cell(N);
    reconst = cell(N);

    D = dctmtx(8);
    dct3 = @(img) tensorprod(D,tensorprod(D,img,2,1 ), 2, 2);
    idct3 = @(img) tensorprod(D,tensorprod(D,img,1,1 ), 1, 2);

    gop_layout = utils.generate_gop_layout(GOP_size, N, num_B);

    anchors = sort([gop_layout.I, gop_layout.P]);

    if verbose
        h = waitbar(0, 'Constructing I-Frames... (1/5)');
    end

    for k = 1:length(gop_layout.I)
        I_ix = gop_layout.I(k);
        encoded{I_ix} = blockproc(images{I_ix}, [8 8], ...
            @(block) round(dct3(block.data)./ quantization_matrix));
        reconst{I_ix} = blockproc(encoded{I_ix}, [8 8], ...
            @(block) round(idct3(block.data.* quantization_matrix)));
        if verbose
            waitbar(k/double(length(gop_layout.I)), h)
        end
    end

    if verbose
        waitbar(0,h,'Constructing P-Frames... (2/5)')
    end
    for k = 1:length(gop_layout.P)
        P_ix = gop_layout.P(k);
        prev_ix = anchors(find(anchors < P_ix, 1, 'last'));
        encoded{P_ix} = blockproc(images{P_ix} -reconst{prev_ix}, [8 8], ...
            @(block) round(dct3(block.data)./ quantization_matrix));
    
        reconst{P_ix} = blockproc(encoded{P_ix}, [8 8], ...
            @(block) round(idct3(block.data.* quantization_matrix)))+reconst{prev_ix};
        if verbose
            waitbar(k/double(length(gop_layout.P)), h);
        end
    end


    if verbose
        waitbar(0,h, 'Constructing B-Frames with temporal alpha... (3/5)');
    end
    for k = 1:length(gop_layout.B)
        B_ix = gop_layout.B(k);
        prev_ix = anchors(find(anchors < B_ix, 1, 'last'));
        next_ix = anchors(find(anchors > B_ix, 1, 'first'));
    
        % normalized temporal weight
        alpha = (B_ix - prev_ix) / (next_ix - prev_ix);
    
    
        encoded{B_ix} = blockproc(images{B_ix} - (alpha*reconst{next_ix} + (1-alpha)*reconst{prev_ix} ), [8 8], ...
            @(block) round(dct3(block.data)./ quantization_matrix));
    
        % reconst{B_ix} = blockproc(encoded{B_ix}, [8 8], ...
        %     @(block) round(idct3(block.data.* quantization_matrix)))+(alpha*reconst{next_ix} + (1-alpha)*reconst{prev_ix});
        if verbose
            waitbar(k/double(length(gop_layout.B)), h)
        end
    
    end

    if verbose
        waitbar(0,h, 'Generating compressed frames... (4/5)');
    end

    mblocks = cell(N,1);
    for k = 1:length(encoded)
        mblocks{k} = utils.frame_to_mb(encoded{k});
        if verbose
            waitbar(k/N, h)
        end
    end

    if verbose
        waitbar(0,h, 'Zigzag-RLE encode... (4/5)');
    end

    [R,G,B] = utils.zigzag_rle_encode(mblocks,verbose);

    if verbose
        close(h);
    end
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


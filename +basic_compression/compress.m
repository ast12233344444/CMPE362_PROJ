% Compresses a sequence of images using DCT, quantization, and encoding.
%
%   This function compresses a sequence of images by converting them into macroblocks,
%   applying the Discrete Cosine Transform (DCT), quantizing the transformed blocks,
%   and encoding the quantized blocks using zigzag and run-length encoding.
%
%   Input:
%       images              - A cell array of images to be compressed. (L * H * W * 3)
%       quantization_matrix - A matrix used for quantizing DCT coefficients. (8x8 matrix).
%       GOP_size            - Size of the Group of Pictures (GOP) for compression. (integer).
%       verbose             - A boolean flag to enable verbose output (optional).
%
%   Output:
%       compressed_data - A structure containing the following fields:
%           header:
%               GOP_size            - Size of the Group of Pictures (GOP).
%               quantization_matrix - Quantization matrix used during compression.
%               num_images          - Number of images in the compressed data.
%               image_size          - A vector [height, width, num_layers] specifying
%                                      the dimensions of the images.
%               layer_sizes         - Sizes of individual layers (R, G, B).
%           data:
%               A matrix containing the compressed image data.
function [compressed_data] = compress(images, quantization_matrix, GOP_size,verbose)
    if nargin < 4
        verbose = false; % Default to false if not provided
    end

    mblocks = [];
    num_images = length(images);

    mblocks = convert_imgs_to_mbs(GOP_size,images,mblocks,verbose);
    mblocks = apply_dct_to_mblocks(mblocks,verbose);
    mblocks = quantize_mblocks(mblocks,quantization_matrix,verbose);

    [Rlayer,Glayer,Blayer] = utils.zigzag_rle_encode(mblocks,verbose);

    compressed_data =  struct(...
        "header", struct('GOP_size', GOP_size, ...
                         'quantization_matrix', quantization_matrix, ...
                         'num_images', num_images, ...
                         'image_size', size(images{1}), ...
                         'layer_sizes', [size(Rlayer, 1), size(Glayer, 1), size(Blayer, 1)] ...
                     ), ...
        "data", [Rlayer; Glayer; Blayer]);

end

function mblocks = convert_imgs_to_mbs(GOP_size,images,mblocks, verbose)
    num_images = length(images);
    if verbose
        h1 = waitbar(0, 'Converting images to blocks...');
    end
    for k = 1:num_images
        if verbose
            waitbar(k / num_images, h1);
        end
        if mod(k-1, GOP_size) == 0 
            image = images{k};
            blocks = utils.frame_to_mb(image);
            mblocks{end+1} = blocks;
        else
            image_current = images{k};
            image_prev = images{k-1};
            diff = image_current - image_prev;
            blocks = utils.frame_to_mb(diff);
            mblocks{end+1} = blocks;
        end
    end
    if verbose
        close(h1);
    end
end



function mblocks = apply_dct_to_mblocks(mblocks, verbose)
    if verbose
        h2 = waitbar(0, 'Applying DCT to blocks...');
    end
    for k = 1:length(mblocks)
        if verbose
            waitbar(k / length(mblocks), h2);
        end
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
    if verbose
        close(h2);
    end
end


function mblocks = quantize_mblocks(mblocks, quantization_matrix, verbose)  
    if verbose
        h3 = waitbar(0, 'Quantizing blocks...');
    end
    for k = 1:length(mblocks)
        if verbose
            waitbar(k / length(mblocks), h3);
        end
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
    if verbose
        close(h3);
    end
end

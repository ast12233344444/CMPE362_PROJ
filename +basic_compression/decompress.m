% Decompresses image data from a compressed format.
%   This function takes a compressed data structure and reconstructs the
%   individual image layers (R, G, B) based on the header information and
%   data provided in the input structure.
%
%   Input:
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
%      verbose - A boolean flag indicating whether to display progress
%
%   Output:
%       images - A reconstructed image matrix containing the decompressed
%                image data.
%   Notes:
%       - The function assumes that the input structure is correctly formatted
%         and contains all necessary fields.
%       - The quantization matrix is converted to double precision for processing.
function images = decompress(compressed_data, verbose)

    quantization_matrix = double(compressed_data.header.quantization_matrix);
    GOP_size = compressed_data.header.GOP_size;

    mblocks = utils.zigzag_rle_decode(compressed_data);

    mblocks = dequantize_mblocks(mblocks,quantization_matrix, verbose);
    mblocks = apply_idct_to_mblocks(mblocks, verbose);
    if verbose
        h = waitbar(0, 'Reconstructing images...');
    end

    num_images = length(mblocks);
    images = cell(num_images, 1);

    for k = 1:num_images
        if mod(k-1, GOP_size) == 0
            mblock = mblocks{k};
            image = utils.mb_to_frame(mblock);
            images{k} = image;
        else
            mblock = mblocks{k};
            image_prev = images{k-1};
            diff = utils.mb_to_frame(mblock);
            image_current = image_prev + diff;
            images{k} = image_current;
        end
        if verbose
            waitbar(k / num_images, h);
        end
    end

    if verbose
        waitbar(0, h, 'Converting images to uint8...');
    end
    for k = 1:num_images
        images{k} = uint8(images{k});
        if verbose
            waitbar(k / num_images, h);
        end
    end
    if verbose
        close(h);
    end
end

function mblocks = dequantize_mblocks(mblocks,quantization_matrix, verbose)
    if verbose
        h = waitbar(0, 'Applying dequantization...');
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
        if verbose
            waitbar(k / length(mblocks), h);
        end
    end

    if verbose
        close(h)
    end
end


function mblocks = apply_idct_to_mblocks(mblocks, verbose)
    if verbose
        h = waitbar(0, 'Applying inverse DCT...');
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
        if verbose
            waitbar(k / length(mblocks), h);
        end
    end
    if verbose
        close(h)
    end
end

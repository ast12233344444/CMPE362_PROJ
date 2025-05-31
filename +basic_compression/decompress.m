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
%
%   Output:
%       images - A reconstructed image matrix containing the decompressed
%                image data.
%   Notes:
%       - The function assumes that the input structure is correctly formatted
%         and contains all necessary fields.
%       - The quantization matrix is converted to double precision for processing.
function images = decompress(compressed_data)

    quantization_matrix = double(compressed_data.header.quantization_matrix);
    GOP_size = compressed_data.header.GOP_size;

    mblocks = utils.zigzag_rle_decode(compressed_data);

    mblocks = dequantize_mblocks(mblocks,quantization_matrix);

    mblocks = apply_idct_to_mblocks(mblocks);

    images = [];
    num_images = length(mblocks);

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

    h6 = waitbar(0, 'Converting images to uint8...');
    for k = 1:num_images
        waitbar(k / num_images, h6);
        images{k} = uint8(images{k});
    end
    close(h6);
end

function mblocks = dequantize_mblocks(mblocks,quantization_matrix)
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
end


function mblocks = apply_idct_to_mblocks(mblocks)
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
end

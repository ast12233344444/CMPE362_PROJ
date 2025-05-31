function compressed_size = dump_size(compressed_data)
    header = compressed_data.header;
    compressed_size = 0;
    
    compressed_size = compressed_size + 4; % GOP_size (int32)
    compressed_size = compressed_size + 4; % num_B (int32)
    % size of quantization_matrix (int32)
    compressed_size = compressed_size + 4 * numel(size(header.quantization_matrix)); 
    % quantization_matrix (uint8)
    compressed_size = compressed_size + numel(header.quantization_matrix(:));
    compressed_size = compressed_size + 4; % num_images (int32)
    compressed_size = compressed_size + 4 * numel(header.image_size); % image_size (int32)
    compressed_size = compressed_size + 4 * numel(header.layer_sizes); % layer_sizes (int32)
    
    % size of data matrix (int32)
    compressed_size = compressed_size + 4 * numel(size(compressed_data.data)); 
    compressed_size = compressed_size + numel(compressed_data.data); % data matrix (int8)
end

function images = fast_decompress(compressed_data, verbose)

    quantization_matrix = double(compressed_data.header.quantization_matrix);
    GOP_size = compressed_data.header.GOP_size;
    num_B = compressed_data.header.num_B;
    N = compressed_data.header.num_images;


    D = dctmtx(8);
    idct3 = @(img) tensorprod(D,tensorprod(D,img,1,1 ), 1, 2);

    mblocks = utils.zigzag_rle_decode(compressed_data);

    encoded = cellfun(@cell2mat, mblocks, 'UniformOutput',false);

   
    gop_layout = utils.generate_gop_layout(GOP_size,N, num_B);
    anchors = sort([gop_layout.I, gop_layout.P]);
    
    reconst = cell(N);
    
    if verbose
        h = waitbar(0, 'Decompressing I-Frames... (1/4)');
    end


    for k = 1:length(gop_layout.I)
        I_ix = gop_layout.I(k);
        reconst{I_ix} = blockproc(encoded{I_ix}, [8 8], ...
            @(block) round(idct3(block.data.* quantization_matrix)));
        if verbose
            waitbar(k/double(length(gop_layout.I)), h)
        end
    end
    
    if verbose
        waitbar(0,h,'Decompressing P-Frames... (2/4)')
    end
    
    for k = 1:length(gop_layout.P)
        P_ix = gop_layout.P(k);
        prev_ix = anchors(find(anchors < P_ix, 1, 'last'));
        reconst{P_ix} = blockproc(encoded{P_ix}, [8 8], ...
            @(block) round(idct3(block.data.* quantization_matrix)))+reconst{prev_ix};
        if verbose
            waitbar(k/double(length(gop_layout.P)), h);
        end
    end
    
    if verbose
        waitbar(0,h, 'Decompressing B-Frames with temporal alpha... (3/4)');
    end
    for k = 1:length(gop_layout.B)
        B_ix = gop_layout.B(k);
        prev_ix = anchors(find(anchors < B_ix, 1, 'last'));
        next_ix = anchors(find(anchors > B_ix, 1, 'first'));
    
        % normalized temporal weight
        alpha = (B_ix - prev_ix) / (next_ix - prev_ix);
    
        reconst{B_ix} = blockproc(encoded{B_ix}, [8 8], ...
            @(block) round(idct3(block.data.* quantization_matrix)))+(alpha*reconst{next_ix} + (1-alpha)*reconst{prev_ix});
        if verbose
            waitbar(k/double(length(gop_layout.B)), h)
        end
    
    end
    
    if verbose
        waitbar(0,h, 'Generating uncompressed frames... (4/4)');  
    end

    images = cell(N, 1);
    for k = 1:N
        images{k} = uint8( min(max(reconst{k},0),255) );  
        if verbose
            waitbar(k/N, h)
        end
    end
    if verbose
        close(h);
    end
end

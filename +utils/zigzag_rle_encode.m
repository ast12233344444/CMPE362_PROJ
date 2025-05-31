function [Rlayer,Glayer,Blayer] = zigzag_rle_encode(mblocks, verbose)
    Rlayer_cell = {};
    Glayer_cell = {};
    Blayer_cell = {};
    
    if verbose
        h4 = waitbar(0, 'Performing zigzag and run-length encoding...');
    end
    for k = 1:length(mblocks)
        if verbose
            waitbar(k / length(mblocks), h4);
        end
        mblock = mblocks{k};
        for i = 1:size(mblock, 1)
            for j = 1:size(mblock, 2)
                block = int8(mblock{i, j});
                R = block(:, :, 1);
                G = block(:, :, 2);
                B = block(:, :, 3);
                Rzb = utils.zigzag(R);
                Gzb = utils.zigzag(G);
                Bzb = utils.zigzag(B);
                Rrle = utils.run_length_encode(Rzb);
                Grle = utils.run_length_encode(Gzb);
                Brle = utils.run_length_encode(Bzb);
    
                Rlayer_cell{end+1} = Rrle;
                Glayer_cell{end+1} = Grle;
                Blayer_cell{end+1} = Brle;
            end
        end
    end
    Rlayer = vertcat(Rlayer_cell{:});
    Glayer = vertcat(Glayer_cell{:});
    Blayer = vertcat(Blayer_cell{:});
    if verbose
        close(h4);
    end
end

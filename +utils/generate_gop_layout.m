function gop_layout = generate_gop_layout(gop_size, num_frames, num_b_per_anchor)
%GENERATE_GOP_LAYOUT  Closed‐GOP frame‐type sequence + indices
%   gop_layout = generate_gop_layout(gop_size, num_frames, num_b_per_anchor)
%
%   OUTPUT (fields of gop_layout):
%     types — 1×num_frames char vector, each entry 'I','P', or 'B'
%     I     — indices in [1..num_frames] of I-frames
%     P     — indices of P-frames
%     B     — indices of B-frames

    types = repmat(' ', 1, num_frames);
    frame_count = 0;

    while frame_count < num_frames
        % --- build one GOP chunk ---
        gop = 'I';  % always start with I
        frame_count = frame_count + 1;
        if frame_count >= num_frames
            % only one frame left
            types(frame_count) = 'I';
            break;
        end

        % fill up to gop_size
        for i = 1:(gop_size-1)
            if frame_count >= num_frames, break; end

            % decide P or B
            if mod(i, num_b_per_anchor+1)==0
                t = 'P';
            else
                % if the next frame is the very last one,
                % force it to be P so GOP closes properly
                if frame_count+1 == num_frames
                    t = 'P';
                else
                    t = 'B';
                end
            end

            % append
            gop(end+1) = t;
            frame_count = frame_count + 1;
        end

        % ensure GOP doesn't end in 'B'
        if gop(end)=='B'
            gop(end) = 'P';
        end

        % write into the global types buffer
        start_idx = frame_count - numel(gop) + 1;
        types(start_idx:frame_count) = gop;
    end

    % now collect indices
    I_idx = find(types=='I');
    P_idx = find(types=='P');
    B_idx = find(types=='B');

    % pack into output struct
    gop_layout = struct( ...
      'types', types, ...
      'I', I_idx, ...
      'P', P_idx, ...
      'B', B_idx ...
    );
end
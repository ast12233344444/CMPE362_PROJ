function output = run_length_decode(rle)
    if isempty(rle)
        output = [];
        return;
    end

    % Preallocate output length for efficiency
    total_length = sum(rle(:,2));
    output = zeros(total_length, 1);

    idx = 1;
    for i = 1:size(rle, 1)
        val = rle(i, 1);
        count = rle(i, 2);
        output(idx:idx+count-1) = val;
        idx = idx + count;
    end
end

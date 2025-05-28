function rle = run_length_encode(input)
    if isempty(input)
        rle = [];
        return;
    end

    input = input(:);  % ensure column vector
    n = length(input);

    change_idx = [1; find(diff(input) ~= 0) + 1; n + 1];

    symbols = input(change_idx(1:end-1));
    counts = diff(change_idx);

    rle = [symbols counts];  % Each row is a "tuple": [value, count]
end
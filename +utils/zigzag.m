function output = zigzag(input)
    [rows, cols] = size(input);
    if rows ~= cols
        error('Input matrix must be square');
    end

    n = rows;  % size of the matrix
    output = zeros(1, n * n);  % preallocate output vector
    index = 1;

    for s = 1:(2*n - 1)
        if mod(s, 2) == 0
            % Even sum of indices: go bottom to top
            i_start = max(1, s - n + 1);
            i_end = min(s, n);
            for i = i_start:i_end
                j = s - i + 1;
                output(index) = input(i, j);
                index = index + 1;
            end
        else
            % Odd sum of indices: go top to bottom
            i_start = min(s, n);
            i_end = max(1, s - n + 1);
            for i = i_start:-1:i_end
                j = s - i + 1;
                output(index) = input(i, j);
                index = index + 1;
            end
        end
    end
end


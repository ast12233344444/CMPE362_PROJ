function output = inverse_zigzag(input)
    n = sqrt(length(input));
    if mod(n,1) ~= 0
        error('Input length is not a perfect square');
    end

    n = int32(n);
    output = zeros(n, n);
    index = 1;

    for s = 1:(2*n - 1)
        if mod(s, 2) == 0
            % Even sum of indices: bottom to top
            i_start = max(1, s - n + 1);
            i_end = min(s, n);
            for i = i_start:i_end
                j = s - i + 1;
                output(i, j) = input(index);
                index = index + 1;
            end
        else
            % Odd sum of indices: top to bottom
            i_start = min(s, n);
            i_end = max(1, s - n + 1);
            for i = i_start:-1:i_end
                j = s - i + 1;
                output(i, j) = input(index);
                index = index + 1;
            end
        end
    end
end
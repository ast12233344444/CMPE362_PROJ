% INVERSE_ZIGZAG - Converts a 1D array into a square matrix using inverse zigzag traversal.
%
% Syntax:
%   output = inverse_zigzag(input)
%
% Input:
%   input - A 1D array whose length must be a perfect square.
%
% Output:
%   output - A square matrix (NxN) reconstructed from the input array
%            using inverse zigzag traversal.
%
% Description:
%   The function reconstructs a square matrix from a 1D array by performing
%   an inverse zigzag traversal. The traversal alternates between filling
%   diagonals from bottom-to-top and top-to-bottom. The reconstruction starts
%   from the top-left corner and ends at the bottom-right corner of the matrix.
%
% Example:
%   input = [1, 2, 4, 7, 5, 3, 6, 8, 9];
%   output = inverse_zigzag(input);
%   % output = [1, 2, 3;
%   %           4, 5, 6;
%   %           7, 8, 9]
%
% Notes:
%   - The length of the input array must be a perfect square. If not, the
%     function will throw an error.
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

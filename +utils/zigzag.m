% ZIGZAG - Converts a square matrix into a 1D array using zigzag traversal.
%
% Syntax:
%   output = zigzag(input)
%
% Input:
%   input - A square matrix (NxN) to be traversed in zigzag order.
%
% Output:
%   output - A 1D array containing the elements of the input matrix
%            arranged in zigzag order.
%
% Description:
%   The function performs a zigzag traversal of the input square matrix.
%   Zigzag traversal alternates between traversing diagonals from bottom-to-top
%   and top-to-bottom. The traversal starts from the top-left corner and ends
%   at the bottom-right corner of the matrix.
%
% Example:
%   input = [1, 2, 3;
%            4, 5, 6;
%            7, 8, 9];
%   output = zigzag(input);
%   % output = [1, 2, 4, 7, 5, 3, 6, 8, 9]
%
% Notes:
%   - The input matrix must be square (NxN). If the matrix is not square,
%     the function will throw an error.
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


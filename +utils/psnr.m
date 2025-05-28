% PSNR Computes the Peak Signal-to-Noise Ratio (PSNR) between two images.
%
%   psnr_value = psnr(original_image, decompressed_image)
%
%   Input:
%       original_image     - The original image (matrix).
%       decompressed_image - The decompressed image (matrix).
%
%   Output:
%       psnr_value - The PSNR value in decibels (dB).
%
%   Example:
%       psnr_value = psnr(original_image, decompressed_image);
%
function psnr_value = psnr(original_image, decompressed_image)
    % Convert images to double for computation
    original_image = double(original_image);
    decompressed_image = double(decompressed_image);
    
    % Compute Mean Squared Error (MSE)
    mse = mean((original_image(:) - decompressed_image(:)).^2);
    
    % Handle edge case where MSE is zero (identical images)
    if mse == 0
        psnr_value = Inf; % Infinite PSNR for identical images
        return;
    end
    
    % Compute PSNR
    max_pixel_value = 255; % Assuming 8-bit images
    psnr_value = 10 * log10((max_pixel_value^2) / mse);
end

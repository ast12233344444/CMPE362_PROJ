plotGOPSizeToCompressionRatio("assets/gopsize_to_compression_ratio.csv")
function plotGOPSizeToCompressionRatio(filename)
    data = readtable(filename);
    
    gopSize = data.GOP_size;
    compressionRatio = data.Compresssion_Ratio;
    
    figure;
    plot(gopSize, compressionRatio, '-o', 'LineWidth', 1.5);
    xlabel('GOP Size');
    ylabel('Compression Ratio');
    title('GOP Size vs Compression Ratio');
    grid on;

    [~, name, ~] = fileparts(filename);
    pngFilename = strcat(name, '.png');
    
    saveas(gcf, pngFilename);
end

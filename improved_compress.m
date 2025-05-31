Q0 = [
 16 , 11 , 10 , 16 , 24 , 40 , 51 , 61;
 12 , 12 , 14 , 19 , 26 , 58 , 60 , 55;
 14 , 13 , 16 , 24 , 40 , 57 , 69 , 56;
 14 , 17 , 22 , 29 , 51 , 87 , 80 , 62;
 18 , 22 , 37 , 56 , 68 , 109 , 103 , 77;
 24 , 35 , 55 , 64 , 81 , 104 , 113 , 92;
 49 , 64 , 78 , 87 , 103 , 121 , 120 , 101;
 72 , 92 , 95 , 98 , 112 , 100 , 103 , 99;
];

Q1 = [ ...
    3  5  7  9 11 13 15 17;
    5  7  9 11 13 15 17 19;
    7  9 11 13 15 17 19 21;
    9 11 13 15 17 19 21 23;
   11 13 15 17 19 21 23 25;
   13 15 17 19 21 23 25 27;
   15 17 19 21 23 25 27 29;
   17 19 21 23 25 27 29 31 ...
];
Q3 = Q1*3;
Q5 = Q1*5;
Q7 = Q1*7;
Q9 = Q1*9;
Q17 = Q1*17;

files = dir(fullfile("./video_data", "*.jpg"));

images = cell(length(files), 1);
original_size = 0;
for k = 1:length(files)
    filename = files(k).name;
    file = fullfile("./video_data", filename);
    img = double(imread(file));

    images{k} = img;
    original_size = original_size + numel(img);
end

GOP_size = 30;
num_B = 3;
tic;
compressed_data = improved_compression.compress(images, Q7, GOP_size, num_B, true);
compressed_size = improved_compression.dump('result.bin',compressed_data);
comp_ratio = double(original_size) / double(compressed_size);
elapsed_time = toc;


fprintf('GOP_size: %d, num_B: %d, Compression Ratio: %f, Elapsed: %f seconds\n', GOP_size, num_B, comp_ratio, elapsed_time);



pkg load image
files = dir('tmp/all/*.jpg');
for d=1:length(files)
file_name = fullfile('tmp/all', files(d).name);
fprintf('%s\n', file_name);
I = imread(file_name);
max_wh = max(size(I));
if max_wh > 1024
    I = imresize(I, 1024/max_wh);
end

b = pencil_draw(I);
R = colour_pencil_draw(I);
imwrite(b, strcat('pencil_',files(d).name), 'jpg');
imwrite(R, strcat('colour_',files(d).name), 'jpg');
end

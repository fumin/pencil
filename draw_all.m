files = dir('tmp/all/*.jpg');
for d=1:length(files)
file_name = fullfile('tmp/all', files(d).name)
b = pencil_draw(imread(file_name));
R = colour_pencil_draw(file_name);
imwrite(b, strcat('pencil_',files(d).name), 'jpg');
imwrite(R, strcat('colour_',files(d).name), 'jpg');
end
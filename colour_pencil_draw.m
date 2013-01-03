function R = colour_pencil_draw(file_name)
% Usage: imshow(colour_pencil_draw('img/sign.png'))
Iruv = rgb2ycbcr(imread(file_name));
Ypencil = pencil_draw(Iruv(:,:,1));

new_Iruv = Iruv;
new_Iruv(:,:,1) = uint8(Ypencil*255);
R = ycbcr2rgb(new_Iruv);
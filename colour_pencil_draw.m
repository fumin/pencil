function R = colour_pencil_draw(I)
% Usage: imshow(colour_pencil_draw(imread('img/sign.png')))
Iruv = rgb2ycbcr(I);
Ypencil = pencil_draw(Iruv(:,:,1));

new_Iruv = Iruv;
new_Iruv(:,:,1) = uint8(Ypencil*255);
R = ycbcr2rgb(new_Iruv);
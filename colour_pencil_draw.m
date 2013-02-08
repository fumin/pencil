function R = colour_pencil_draw(I,line_len_divisor,line_thickness_divisor,lambda,texture_resize_ratio,texture_file_name, col_coeff1,col_coeff2,col_coeff3,pen_coeff1,pen_coeff2,pen_coeff3)
% Usage: imshow(colour_pencil_draw(imread('img/sign.png')))
Iruv = rgb2ycbcr(I);
Ypencil = pencil_draw(Iruv(:,:,1),line_len_divisor,line_thickness_divisor,lambda,texture_resize_ratio,texture_file_name, col_coeff1,col_coeff2,col_coeff3,pen_coeff1,pen_coeff2,pen_coeff3);

new_Iruv = Iruv;
new_Iruv(:,:,1) = uint8(Ypencil*255);
R = ycbcr2rgb(new_Iruv);
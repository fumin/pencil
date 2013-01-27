function Ipencil = pencil_draw(I)
% The algorithm is as follows:
% 1. Compute the outline sketch 'S'
%      * Prepare the 8 directional line segment images, 'L', 
%        all with width and height 'line_len', which is around 1/30 of the
%        input image I's width
%      * Compute the gradient of the input image which is 'Imag'
%      * Generate the pixel classification 'C' of the 8 directions
%      * Convolute the 8 'C's and 'L's to obtain our final outline sketch 'S'
% 2. Compute the texture tone drawing 'T'
%      * Prepare 'Jadjusted' which is the adjusted the raw image 'J'
%        against the natural histogram of typical pencil drawings.
%      * Repetitively stitch our base texture image to the size of our raw image.
%        The result is 'Jtexture', our base texture background. 
%      * Solve for 'beta', the number of times we should draw the texture.
%        'beta' should have the same width and height as our raw image 'J':
%          * Although beta is two dimensional, see it as an
%            one dimensional column 'b' with length size(J,1)*size(J,2).
%            The same goes for 'Jadjusted', whose one dimensional column
%            representation is 'Ja'.
%          * Our minimization objective function is:
%            |log(Jtexture_diag)*b - log(Ja)|^2 + lambda*(|dx*b|^2+|dy*b|^2)
%            Where 'Jtexture_diag' is a diagonal square matrix whose
%            width equals the length of 'b' and with
%            Jtexture's column representation at its diagonals.
%            'dx' and 'dy' are square matrices that represent
%            image pixel differences at the x and y directions.
%          * Apparently, 'Jtexture_diag', 'dx' and 'dy' are all matrices
%            of extreme size, therefore they should be sparse matrices.
%      * Our desired texture tone drawing 'T' is Jtexture.^beta 
% 3. Combine 'S' and 'T'
%
% Usage: imshow(pencil_draw(imread('img/sign.png')))
% Constants:
line_len_divisor = 40; % larger for a shorter line fragment
line_thickness_divisor = 8; % larger for thiner outline sketches
lambda = 2; % larger for smoother tonal mappings
texture_resize_ratio = 0.2;
texture_file_name = 'textures/texture.jpg';

if length(size(I)) == 3
    J = rgb2gray(I);
    type = 'black';
else
    J = I;
    type = 'colour';
end

% ================================================
% Compute the outline sketch 'S'
% ================================================
% calculate 'line_len', the length of the line segments
line_len_double = min([size(J,1), size(J,2)]) / line_len_divisor;
if mod(floor(line_len_double), 2)
    line_len = floor(line_len_double);
else
    line_len = floor(line_len_double) + 1;
end
half_line_len = (line_len + 1) / 2;

% compute the image gradient 'Imag'
Ix = conv2(im2double(J), [1,-1;1,-1], 'same');
Iy = conv2(im2double(J), [1,1;-1,-1], 'same');
Imag = sqrt(Ix.*Ix + Iy.*Iy);

% create the 8 directional line segments L
L = zeros(line_len, line_len, 8);
for n=0:7
    if n == 0 || n == 1 || n == 2 || n == 7
        for x=1:line_len
            y = half_line_len - round((x-half_line_len)*tan(pi/8*n));
            if y > 0 && y <= line_len
                L(y, x, n+1) = 1;
            end
        end
        if n == 0 || n == 1 || n == 2
            L(:,:,n+5) = rot90(L(:,:,n+1));
        end
    end
end
L(:,:,4) = rot90(L(:,:,8), 3);

% add some thickness to L
valid_width = size(conv2(L(:,:,1),ones(round(line_len/line_thickness_divisor)),'valid'), 1);
Lthick = zeros(valid_width, valid_width, 8);
for n=1:8
    Ln = conv2(L(:,:,n),ones(round(line_len/line_thickness_divisor)), 'valid');
    Lthick(:,:,n) = Ln / max(max(Ln));
end

% create the sketch
G = zeros(size(J,1), size(J,2), 8);
for n=1:8
    G(:,:,n) = conv2(Imag, L(:,:,n), 'same');
end

[Gmax, Gindex] = max(G, [], 3);
C = zeros(size(J,1), size(J,2), 8);
for n=1:8
    C(:,:,n) = Imag .* (Gindex == n);
end

Spn = zeros(size(J,1), size(J,2), 8);
for n=1:8
    Spn(:,:,n) = conv2(C(:,:,n), Lthick(:,:,n), 'same');
end
Sp = sum(Spn, 3);
Sp = (Sp - min(Sp(:))) / (max(Sp(:)) - min(Sp(:)));
S = 1 - Sp;


% ==============================================
% Compute the texture tone drawing 'T'
% ==============================================
% new tone adjusted image
Jadjusted = natural_histogram_matching(J,type);

% stich pencil texture image
texture = imread(texture_file_name);
texture = texture(100:size(texture,1)-100,100:size(texture,2)-100);
texture = im2double(imresize(texture, texture_resize_ratio*min([size(J,1),size(J,2)])/1024));
Jtexture = vertical_stitch(horizontal_stitch(texture,size(J,2)), size(J,1));

% solve for beta
sizz = size(J,1)*size(J,2); % width of big matrix

nzmax = 2*(sizz-1);
i = zeros( nzmax, 1 );
j = zeros( nzmax, 1 );
s = zeros( nzmax, 1 );
for m=1:nzmax
    i(m) = ceil((m+0.1) / 2);
    j(m) = ceil((m-0.1) / 2);
    s(m) = -2*mod(m,2) + 1;
end
dx = sparse(i,j,s,sizz,sizz,nzmax);

nzmax = 2*(sizz - size(J,2));
i = zeros( nzmax, 1 );
j = zeros( nzmax, 1 );
s = zeros( nzmax, 1 );
for m=1:nzmax
    if mod(m,2)
        i(m) = ceil((m+0.1) / 2);
    else
        i(m) = ceil((m-1+0.1) / 2) + size(J,2);
    end
    j(m) = ceil((m-0.1) / 2);
    s(m) = -2*mod(m,2) + 1;
end
dy = sparse(i,j,s,sizz,sizz,nzmax);

Jtexture1d = log(reshape(Jtexture',1,[]));
Jtsparse = spdiags(Jtexture1d',0,sizz,sizz);
Jadjusted1d = log(reshape(Jadjusted',1,[])');
beta1d = (Jtsparse'*Jtsparse + lambda*(dx'*dx + dy'*dy))\(Jtsparse'*Jadjusted1d);
beta = reshape(beta1d, size(J,2), size(J,1))';

% compute the texture tone image 'T' and combine it with the outline sketch
% to come out with the final result 'Ipencil'
T = Jtexture .^ beta;
T = (T - min(T(:))) / (max(T(:)) - min(T(:)));
Ipencil = S.*T;

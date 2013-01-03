function Ipencil = pencil_draw(I)
% Usage: imshow(pencil_draw(imread('img/sign.png')))
if length(size(I)) == 3
    J = rgb2gray(I);
else
    J = I;
end

line_len_double = min([size(J,1), size(J,2)]) / 30;
if mod(floor(line_len_double), 2)
    line_len = floor(line_len_double);
else
    line_len = floor(line_len_double) + 1;
end
half_line_len = (line_len + 1) / 2;

Ix = conv2(im2double(J), [1,-1;1,-1], 'same');
Iy = conv2(im2double(J), [1,1;-1,-1], 'same');
Imag = sqrt(Ix.*Ix + Iy.*Iy);

% create the lines L
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
valid_width = size(conv2(L(:,:,1),ones(round(line_len/10)),'valid'), 1);
Lthick = zeros(valid_width, valid_width, 8);
for n=1:8
    Ln = conv2(L(:,:,n),ones(round(line_len/10)), 'valid');
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

% new tone adjusted image
Jadjusted = natural_histogram_matching(J);

% stich pencil texture image
texture = imread('texture.jpg');
texture = im2double(imresize(texture(200:1600,200:2300), 0.2));
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
beta1d = (Jtsparse'*Jtsparse + 2*(dx'*dx + dy'*dy))\(Jtsparse'*Jadjusted1d);
beta = reshape(beta1d, size(J,2), size(J,1))';

T = Jtexture .^ beta;
T = (T - min(T(:))) / (max(T(:)) - min(T(:)));
Ipencil = S.*T;
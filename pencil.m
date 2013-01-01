I = imread('flower.png');
J = rgb2gray(I);
Ix = conv2(im2double(J), [1,-1;1,-1], 'same');
Iy = conv2(im2double(J), [1,1;-1,-1], 'same');
Imag = sqrt(Ix.*Ix + Iy.*Iy);

% create the lines L
line_len_double = min([size(J,1), size(J,2)]) / 40;
if mod(floor(line_len_double), 2)
    line_len = floor(line_len_double);
else
    line_len = floor(line_len_double) + 1;
end
half_line_len = (line_len + 1) / 2;

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
    Spn(:,:,n) = conv2(C(:,:,n), L(:,:,n), 'same');
end
Sp = sum(Spn, 3);
S = 1 - Sp / max(max(Sp));

% new tone adjusted image
ho = zeros(1, 256);
po = zeros(1, 256);
for i=1:256
    po(i) = sum(sum(J == (i-1)));
end
po = po / sum(po);
ho(1) = po(1);
for i=2:256
    ho(i) = ho(i-1) + po(i);
end

p1 = @(x) 1 / 9 * exp(-(256-x)/9) * heaviside(256-x);
p2 = @(x) 1 / (256 - 105) * (heaviside(x-105) - heaviside(x-256));
p3 = @(x) 1 / sqrt(2*pi*11)*exp(-((x-90)^2)/(2*121));
p = @(x) (52*p1(x) + 37*p2(x) + 11*p3(x));
prob = zeros(1, 256); histo = zeros(1, 256);
for i=1:256
    prob(i) = p(i);
end
prob = prob / sum(prob);
histo(1) = prob(1);
for i=2:256
    histo(i) = histo(i-1) + prob(i);
end

Jadjusted = zeros(size(J,1), size(J,2));
for y=1:size(J,1)
    for x=1:size(J,2)
        histogram_value = ho(J(y,x)+1);
        [v,i] = min(abs(histo - histogram_value));
        Jadjusted(y,x) = i;
    end
end
Jadjusted = uint8(Jadjusted);

% stich pencil texture image
texture = imread('texture.png');

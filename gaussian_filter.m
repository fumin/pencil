function Igaussian = gaussian_filter(I, sigma)
hsize = 3*round(sigma);
h = zeros(hsize);
for i=1:hsize
    for j=1:hsize
        u = [j-(3*sigma)/2, i-(3*sigma)/2];
        h(i,j) = exp(-u*u'/(2*sigma*sigma))/sigma*sqrt(2*pi);
    end
end

Igaussian = conv2(I, h, 'same');
Igaussian = Igaussian / max(max(Igaussian));
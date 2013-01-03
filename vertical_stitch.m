function Istitched = vertical_stitch(I,height)
% I must be within 0 and 1
Istitched = I;
while size(Istitched,1)<height
    window_size = round(size(I,1)/4);
    up = I((size(I,1)-window_size+1):size(I,1),:);
    down = I(1:window_size,:);
    aup = zeros(window_size, size(up,2));
    adown = zeros(window_size, size(up,2));
    for i=1:window_size
        aup(i,:) = up(i,:)*(1-i/window_size);
        adown(i,:) = down(i,:)*i/window_size;
    end
    Istitched = [Istitched(1:(size(Istitched,1)-window_size),:);aup+adown;Istitched((window_size+1):size(Istitched,1),:)];
end

Istitched = Istitched(1:height,:);
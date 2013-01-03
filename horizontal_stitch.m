function Istitched = horizontal_stitch(I,width)
% Continuously repeat the image I horizontally until the width of the
% resulting image is 'width'.
% We use alpha blending to smooth the borders in the replication 
%
% I must be within 0 and 1
Istitched = I;
while size(Istitched,2)<width
    window_size = round(size(I,2)/4);
    left = I(:,(size(I,2)-window_size+1):size(I,2));
    right = I(:,1:window_size);
    aleft = zeros(size(left,1),window_size);
    aright = zeros(size(left,1),window_size);
    for i=1:window_size
        aleft(:,i) = left(:,i)*(1-i/window_size);
        aright(:,i) = right(:,i)*i/window_size;
    end
    Istitched = [Istitched(:,1:(size(Istitched,2)-window_size)),aleft+aright,Istitched(:,(window_size+1):size(Istitched,2))];
end

Istitched = Istitched(:,1:width);

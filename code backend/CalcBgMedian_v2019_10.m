function [ bg ] = CalcBgMedian_v2019_10( imageLoader, ti_bg, percentage, color_channel )
% считает медианное значение каждого пикселя из набора номеров кадров
% imageLoader - imLoader_v2019_1
% ti_bg - номера кадров, могуть выходить за границы, могут быть не целыми
% percentage - от 0 до 100 перцентиль


if isempty(ti_bg)
    ti_bg = 1:imageLoader.imNum;
end
if numel(ti_bg) == 1
    ti_bg = round( linspace( 1, imageLoader.imNum, ti_bg) );
end
ti_bg(ti_bg < 1 | ti_bg > imageLoader.imNum) = [];
if isempty(ti_bg)
    warning('no frames');
    bg = zeros(imageLoader.imSize(2),imageLoader.imSize(1));
else    
    bgall = zeros(imageLoader.imSize(2),imageLoader.imSize(1),numel(ti_bg));
    for i = 1:numel(ti_bg)
        im = imageLoader.getImage(ti_bg(i));
        im = im(:,:,color_channel);
        bgall(:,:,i) = im;
    end
    bgr = reshape(permute(bgall,[3 2 1]),[numel(ti_bg), size(bgall,1) * size(bgall,2)]);
    p = prctile(bgr,percentage,1);
    % p = median(bgr,1);
    bg = reshape(p,[size(bgall,2), size(bgall,1)])';
end
end
function [ PIV_output ] = DoCC10( ...
    im1,im2,...
    pp, pg)
iteration_tic = tic;
%DoCC6 Вычисление PIV над двумя изображениями
% pp PIV_params
% pg PIV_grid
%% eval params
s2e = pp;
clear fieldnames fieldnames_i;
fieldnames_my = fieldnames(s2e);
for fieldnames_i = 1:numel(fieldnames_my)
    eval([fieldnames_my{fieldnames_i} '=s2e.' fieldnames_my{fieldnames_i} ';']);
end
clear fieldnames fieldnames_i;

%% grid
xcArr = pg.xMat;
ycArr = pg.yMat;
doCCArr = pg.do_PIV_mat;
%%
if numel(xIDArr) == 1 && (isnan(xIDArr) || xIDArr == 0)
    xIDArr = zeros(size(xcArr));
end
if numel(yIDArr) == 1 && (isnan(yIDArr) || yIDArr == 0)
    yIDArr = zeros(size(xcArr));
end
xIDArr = round(xIDArr);
yIDArr = round(yIDArr);
%%
if any(size(xcArr) ~= size(ycArr) | size(xcArr) ~= size(doCCArr))
    error 'DoCC: Разные размеры матриц координат';
end
if any(size(im1) ~= size(im2))
    error 'DoCC: Разные размеры изображений';
end
xFieldCount = size(xcArr,1);
yFieldCount = size(xcArr,2);
imSize = fliplr(size(im1));
%%
status = nan*zeros(size(xcArr));
xdispl = nan*zeros(size(xcArr));
ydispl = nan*zeros(size(xcArr));
CC_maxValue = nan*zeros(size(xcArr));
CC_maxRaitio = nan*zeros(size(xcArr));
mean_im1 = nan*zeros(size(xcArr));
% mean_im2 = nan*zeros(size(xcArr));
clear CC_infoArr = cell(size(xcArr));
if (saveCCandIMC)
    CC_infoArr = cell(size(xcArr));
else
    CC_infoArr = [];
end
% if useBiasCorrection || saveCCandIMC
%     [r,s] = meshgrid( -wSize(1)/2:wSize(1)/2 - 1, -wSize(2)/2:wSize(2)/2 - 1 );
%     biasCorrMatrix = ( 1-abs(r) / wSize(1) ).*( 1-abs(s) / wSize(2) );
% end
%% основной цикл
for xi = 1:xFieldCount
    for yi = 1:yFieldCount
        xc = xcArr(xi,yi);
        yc = ycArr(xi,yi);
        xID = xIDArr(xi,yi);
        yID = yIDArr(xi,yi);
        doCC = doCCArr(xi,yi);
        
        status(xi,yi) = 0;
        
        
        if ~doCC
            status(xi,yi) = 85;
            continue;
        end
        if isnan(xc) || isnan(yc) || isnan(xID) || isnan(yID)
            status(xi,yi) = 84;
            continue;
        end
        xp_sp = NaN; yp_sp = NaN;
        %%
        c = [xc, yc]; %центр
        dc0 = [xID, yID]; % предсмещение
        
        %% первый проход, если удастся, то он подменит xID, yID на уточненные
        if doFirstPass
            imArea1 = RectArea(c - dc0/2,wSize1);
            imArea2 = RectArea(c + dc0/2,wSize1);
            if ~(RectFitsin(imArea1,imSize) &&  RectFitsin(imArea2,imSize))
                status(xi,yi) = 101;
                continue;
            end
            [xS1, xE1, yS1, yE1] = BoardersOfArea(imArea1);
            [xS2, xE2, yS2, yE2] = BoardersOfArea(imArea2);
            im1c=im1(yS1:yE1, xS1:xE1);
            im2c=im2(yS2:yE2, xS2:xE2);
            result_conv =fftshift(real(ifft2(conj(fft2(im1c)).*fft2(im2c))));
            mean_im1(xi,yi) = mean(im1c(:));
            %         mean_im2(xi,yi) = mean(im2c(:));
            
            %         %bias correction:
            %         if useBiasCorrection
            %             result_conv = result_conv./biasCorrMatrix;
            %         end
            
            % максимумы
            if pp.doMultiMax
                minMatrix = imregionalmax(result_conv);
                maximums_i = find(minMatrix); %индексы
                maximums_v = result_conv(maximums_i); %значения
                if numel(maximums_v > 1)
                    [maximums_v1, maximums_i1] = max(maximums_v); %индекс и значение в списке максимумов
                    maximums_v(maximums_i1) = 0;
                    [maximums_v2, maximums_i2] = max(maximums_v);
                    maximums_v(maximums_i1) = maximums_v1;
                    CC_maxRaitio(xi,yi) = maximums_v1/maximums_v2;
                    CC_maxValue(xi,yi) = maximums_v1;
                else
                    CC_maxRaitio(xi,yi) = Inf;
                    CC_maxValue(xi,yi) = maximums_v;
                end
                location = maximums_i(maximums_i1);
            else
                [~, location] = max(result_conv(:));
                maximums_v1 = nan;  maximums_i1 = nan; maximums_v2 = nan;  maximums_i2 = nan;
                CC_maxRaitio(xi,yi) = Inf;
                CC_maxValue(xi,yi) = maximums_v1;
            end
            [yp,xp] = ind2sub(size(result_conv),location);
            CC_xdispl = xp - wSize1(1)/2 - 1;
            CC_ydispl = yp - wSize1(2)/2 - 1;
            if CC_maxRaitio(xi,yi) < minS2NRatio
                status(xi,yi) = 177;
            elseif ~(abs(CC_xdispl) < maxDispl(1) && abs(CC_ydispl) < maxDispl(2))
                status(xi,yi) = 178;
            else
                xID = xID + CC_xdispl;
                yID = yID + CC_ydispl;
            end
            if (saveCCandIMC)
                xd_FirstPass = CC_xdispl;
                yd_FirstPass = CC_ydispl;
                result_conv_firstPass = result_conv;
            end
        else
            if (saveCCandIMC)
                xd_FirstPass = nan;
                yd_FirstPass = nan;
                result_conv_firstPass = nan;
            end
        end
        %% основной проход
        if status(xi,yi) == 0 % на случай что на первом этапе вылетели с ошибкой
            dc0 = [xID, yID]; % предсмещение
            
            imArea1 = RectArea(c - dc0/2,wSize);
            imArea2 = RectArea(c + dc0/2,wSize);
            if ~(RectFitsin(imArea1,imSize) &&  RectFitsin(imArea2,imSize))
                status(xi,yi) = 1;
                continue;
            end
            [xS1, xE1, yS1, yE1] = BoardersOfArea(imArea1);
            [xS2, xE2, yS2, yE2] = BoardersOfArea(imArea2);
            im1c=im1(yS1:yE1, xS1:xE1);
            im2c=im2(yS2:yE2, xS2:xE2);
            result_conv =fftshift(real(ifft2(conj(fft2(im1c)).*fft2(im2c))));
            
            
            % назуляем ККФ за пределами максимального смещения (2019 11), плюс по одному пикселю на подпиксельный поиск
            if ~isinf(maxDispl(2))
                result_conv(    1 : -maxDispl(2) -1 +  wSize(2)/2 + 1 ,      : ) = 0;
                result_conv(         maxDispl(2) +  wSize(2)/2 + 1 + 1: end, : ) = 0;
            end
            if ~isinf(maxDispl(1))
                result_conv( :, 1 : -maxDispl(1) -1 +  wSize(1)/2 + 1          ) = 0;
                result_conv( :,      maxDispl(1) +  wSize(1)/2 + 1 +1 : end    ) = 0;
            end
            
            mean_im1(xi,yi) = mean(im1c(:));
            %         mean_im2(xi,yi) = mean(im2c(:));
            
            %         %bias correction:
            %         if useBiasCorrection
            %             result_conv = result_conv./biasCorrMatrix;
            %         end
            
            % максимумы
            if pp.doMultiMax
                minMatrix = imregionalmax(result_conv);
                maximums_i = find(minMatrix); %индексы
                maximums_v = result_conv(maximums_i); %значения
                if numel(maximums_v > 1)
                    [maximums_v1, maximums_i1] = max(maximums_v); %индекс и значение в списке максимумов
                    maximums_v(maximums_i1) = 0;
                    [maximums_v2, maximums_i2] = max(maximums_v);
                    maximums_v(maximums_i1) = maximums_v1;
                    CC_maxRaitio(xi,yi) = maximums_v1/maximums_v2;
                    CC_maxValue(xi,yi) = maximums_v1;
                else
                    CC_maxRaitio(xi,yi) = Inf;
                    CC_maxValue(xi,yi) = maximums_v;
                end
                location = maximums_i(maximums_i1);
            else
                [maximums_v, location] = max(result_conv(:));
                maximums_v1 = nan;  maximums_i1 = nan; maximums_v2 = nan;  maximums_i2 = nan;
                CC_maxRaitio(xi,yi) = Inf;
                CC_maxValue(xi,yi) = maximums_v1;
            end
            [yp,xp] = ind2sub(size(result_conv),location);
            CC_xdispl = xp - wSize(1)/2 - 1;
            CC_ydispl = yp - wSize(2)/2 - 1;
            if CC_maxRaitio(xi,yi) < minS2NRatio
                status(xi,yi) = 77;
            elseif ~(abs(CC_xdispl) < maxDispl(1) && abs(CC_ydispl) < maxDispl(2))
                status(xi,yi) = 78;
            else
                xdispl(xi,yi) = xID + CC_xdispl;
                ydispl(xi,yi) = yID + CC_ydispl;
                
                %добавка от подпиксельного поиска
                if ~useSubpixel
                    status(xi,yi) = 0;
                elseif ~(xp > 1 && xp < wSize(1) && yp > 1 && yp < wSize(2))%проверка на правильное положение максимума
                    status(xi,yi) = 4;
                else
                    Cx = result_conv(yp,xp-1:xp+1);
                    Cy = result_conv(yp-1:yp+1,xp)';
                    Cx23 = Cx(2)/Cx(3);Cx12 = Cx(1)/Cx(2);Cy23 = Cy(2)/Cy(3);Cy12 = Cy(1)/Cy(2);
                    minC = 0;
                    maxC = 1e10;
                    if (Cx12 > maxC || Cx23 > maxC || Cy12 > maxC || Cy23 > maxC) ||...
                            (Cx12 <= minC || Cx23 <= minC || Cy12 <= minC || Cy23 <= minC)
                        status(xi,yi) = 41;
                    else
                        xp_sp = -0.5*(log(  Cx23  )+log(  Cx12  )) / (log(  Cx23  )-log(  Cx12  ));
                        yp_sp = -0.5*(log(  Cy23  )+log(  Cy12  ))/  (log(  Cy23  )-log(  Cy12  ));
                        if ~(abs(xp_sp)<1 && abs(yp_sp)<1)
                            error ('DoCC: subpixel: Ошибка положения максимума');
                        end
                        status(xi,yi) = 0;
                        xdispl(xi,yi) = xID + CC_xdispl + xp_sp;
                        ydispl(xi,yi) = yID + CC_ydispl + yp_sp;
                    end
                end
            end
        end
        %%
        if (saveCCandIMC)
            clear CC_info;
            CC_info.xi = xi;
            CC_info.yi = yi;
            CC_info.xc = xc;
            CC_info.yc = yc;
            CC_info.status = status(xi,yi);
            CC_info.imc1 = im1c;
            CC_info.imc2 = im2c;
            CC_info.result_conv = result_conv;
            CC_info.result_conv_firstPass = result_conv_firstPass;
%             CC_info.r = r;
%             CC_info.s = s;
            CC_info.CC_xdispl = CC_xdispl;
            CC_info.CC_ydispl = CC_ydispl;
            CC_info.xd_FirstPass = xd_FirstPass;
            CC_info.yd_FirstPass = yd_FirstPass;
            CC_info.xp_sp = xp_sp;
            CC_info.yp_sp = yp_sp;
            CC_info.xdispl = xdispl(xi,yi);
            CC_info.ydispl = ydispl(xi,yi);
            CC_info.maximums_v = maximums_v;
            CC_info.maximums_v1 = maximums_v1;
            CC_info.maximums_i1 = maximums_i1;
            CC_info.maximums_v2 = maximums_v2;
            CC_info.maximums_i2 = maximums_i2;
            CC_info.CC_maxRaitio = CC_maxRaitio(xi,yi);
            CC_infoArr{xi,yi} = CC_info;
        end
    end
end
PIV_output.status = status;
PIV_output.xdispl = xdispl;
PIV_output.ydispl = ydispl;
PIV_output.CC_maxValue = CC_maxValue;
PIV_output.CC_maxRaitio = CC_maxRaitio;
PIV_output.CC_infoArr = CC_infoArr;
PIV_output.pp = pp;
PIV_output.pg = pg;
PIV_output.imSize = imSize;
PIV_output.mean_im1 = mean_im1;
% PIV_output.mean_im2 = mean_im2;
PIV_output.time_of_iteration = toc(iteration_tic);
end

function result = RectFitsin(imArea,imSize)
[xS, xE, yS, yE] = BoardersOfArea(imArea);
imSizeX = imSize(1);
imSizeY = imSize(2);
result = (xS >= 1 && xE <= imSizeX && yS >= 1 && yE <= imSizeY);
end

function imArea = RectArea(c,wSize)
xc = c(1);
yc = c(2);
xS = xc - round(wSize(1)/2);
xE = xc + round(wSize(1)/2)-1;
yS = yc - round(wSize(2)/2);
yE = yc + round(wSize(2)/2)-1;
imArea = round([xS xE yS yE]);
end

function [xS, xE, yS, yE] = BoardersOfArea(imArea)
xS = imArea(1);
xE = imArea(2);
yS = imArea(3);
yE = imArea(4);
end
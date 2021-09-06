classdef PIV_grid
    %квадратная сетка для PIV
    %   Detailed explanation goes here
    properties
        version = 1;
        
        xMat;        
        yMat; %(xi yi)
        xArr;        
        yArr;
        xStep;       
        yStep; %auto
        do_PIV_mat;
    end
    methods
        function obj = PIV_grid(xArr, yArr)
            if nargin == 2
                [obj.yMat,obj.xMat] = meshgrid(yArr,xArr);
                obj.xArr = xArr;
                obj.yArr = yArr;
                obj.do_PIV_mat = true(size(obj.xMat));
                if numel(xArr) > 1
                    d = diff(xArr);
                    if any(d ~= d(1))
                        obj.xStep = NaN;
                    else
                        obj.xStep = d(1);
                    end
                else
                    obj.xStep = NaN;
                end
                if numel(yArr) > 1
                    d = diff(yArr);
                    if any(d ~= d(1))
                        obj.yStep = NaN;
                    else
                        obj.yStep = d(1);
                    end
                else
                    obj.yStep = NaN;
                end
            else
                error ('need 2 arguments')
            end
        end
        
        function s = Get_size(obj)
            s = size(obj.xMat);
        end
    end
    methods(Static)
        function obj = Get_max_grid(im_size_xy, step_xy)
            im_size_x = im_size_xy(1);
            im_size_y = im_size_xy(2);
            st_x = step_xy(1);
            st_y = step_xy(2);
            s_x = ceil(st_x + 1);
            s_y = ceil(st_y + 1);
            e_x = floor(im_size_x - st_x + 1);
            e_y = floor(im_size_y - st_y + 1);
            obj = PIV_grid(...
                s_x : st_x : e_x,...
                s_y : st_y : e_y);
        end
        
        function result = RectFitsin(imArea,imSize)
            [xS, xE, yS, yE] = PIV_grid.BoardersOfArea(imArea);
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
    end
    methods
        function obj = Disable_from_mask(obj, mask, wSize, max_prc)
            %Disable_from_mask выключает узлы, в которых слишком много
            %маски
            imSize = fliplr(size(mask));
            xcArr = obj.xMat;
            ycArr = obj.yMat;
            xFieldCount = size(xcArr,1);
            yFieldCount = size(xcArr,2);
            for xi = 1:xFieldCount
                for yi = 1:yFieldCount
                    xc = xcArr(xi,yi);
                    yc = ycArr(xi,yi);
                    if isnan(xc) || isnan(yc)
                        continue;
                    end
                    c = [xc, yc]; %центр                    
                    imArea1 = obj.RectArea(c,wSize);
                    if ~obj.RectFitsin(imArea1,imSize) 
                        continue;
                    end
                    [xS1, xE1, yS1, yE1] = obj.BoardersOfArea(imArea1);
                    im1c = mask(yS1:yE1, xS1:xE1);
                    
                    mask_prc = 100 * sum(im1c(:)) / numel(im1c);
                    if mask_prc > max_prc
                        obj.do_PIV_mat(xi,yi) = false;
                    end
                end
            end
        end
    end
    methods (Static)
        function overlap_xy = Get_overlap(window_size, step_xy)
            overlap_xy(1) = 100* (window_size(1) - step_xy(1)) / window_size(1);
            overlap_xy(2) = 100*(window_size(2) - step_xy(2)) / window_size(2);
        end
        function step_xy = Get_step_from_overlap(window_size, overlap)
            step_xy(1) = window_size(1) - overlap/100 * window_size(1);
            step_xy(2) = window_size(2) - overlap/100 * window_size(2);
        end
    end
    
end


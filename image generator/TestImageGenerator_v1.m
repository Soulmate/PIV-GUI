% TODO
%         вихрь птолемея (гауссово распределение завихренности)
%         трехмерное движение (потеря частиц, изменение яркости)
%         правильные границы
%         подпиксельное смещение
%
%         ошибка от
%         смещения,
%         размера окна,
%         размера частицы (гауссово распределение),
%         количества частиц в окне
%         при постоянной яркости
%
%         построение распределений
%         штрихи пока не надо

%%
classdef TestImageGenerator_v1 < handle
    %TestImageGenerator_v1 герегирует тестовые изображения по параметрам, перечисленным в файле
    %   TODO описать пример
    
    properties
        % изображение
        imSize = 128*[1 1] ; %y x
        noiseLevel = 0.1;  % типичное знаениче 0.1, максимальное значение случайного шума, в абсолютных единицах яркости
        multiasmpling = 4; % типичное значение 4
        
        % смещение частиц за кадр (глобальное)
        disp = [10 -10];%[15.508 17.195]; %x y
        dispScatt = [3 3]; %x y
        
        % частицы
        dens = 0.01; % штук на квадратный пиксель
        valMin = 0.5; % минимальное значение яркости
        valMax = 1;   % максимальное значение яркости
        pSizeMin = 0.1; % минимальный размер частицы в пикселях
        pSizeMax = 3;   % максимальный размер частицы в пикселях
        expTimeRatio = 0.5; %отношение экспозиции к межкадровому промежутку (0 - 1, чем больше, тем более смазанные частицы)
        
        
        path = 'result1';
        
        % изображения
        ims;
    end
    
    methods
        function obj = TestImageGenerator_v1()
            %TestImageGenerator_v1 Construct an instance of this class
            %   Detailed explanation goes here
            if ~exist(obj.path,'dir'), mkdir(obj.path); end
        end
        
        function ims = Generate_pair(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            
            numOfParticles = round(prod(obj.imSize)*obj.dens); %TODO учесть что площать больше из-за смещения
            dispx = obj.disp(1) + obj.dispScatt(1) * (rand([numOfParticles, 1]) - 0.5);
            dispy = obj.disp(2) + obj.dispScatt(2) * (rand([numOfParticles, 1]) - 0.5);
            
            x0 = rand([numOfParticles, 1]);
            y0 = rand([numOfParticles, 1]);
            pSize = rand([numOfParticles, 1]);
            
            
            x0 = x0*(obj.imSize(2) + abs(obj.disp(1))) - obj.disp(1);
            y0 = y0*(obj.imSize(1) + abs(obj.disp(2))) - obj.disp(2);
            pSize = pSize*(obj.pSizeMax-obj.pSizeMin) + obj.pSizeMin;
            
            clear x0s;
            clear y0s;
            x0s{1} = x0;
            y0s{1} = y0;
            x0s{2} = x0 + dispx;
            y0s{2} = y0 + dispy;
            clear x0;
            clear y0;
            
            ims = cell(2,1);
            for im_i = 1:2
                x0 = x0s{im_i};
                y0 = y0s{im_i};
                
                im = zeros(obj.imSize*obj.multiasmpling);
                val = rand([numOfParticles, 1]);
                val = val*(obj.valMax-obj.valMin) + obj.valMin;
                for i = 1:numOfParticles
                    d_i = sqrt(dispx(i)*dispx(i) + dispy(i)*dispy(i));
                    expNumOfPoints = round(d_i * obj.expTimeRatio/pSize(i)*2);
                    if expNumOfPoints < 1
                        expNumOfPoints =1;
                    end
                    for expi = 1:expNumOfPoints %номер экспозиции
                        if expNumOfPoints <= 1
                            x0_i = x0(i);
                            y0_i = y0(i);
                        else
                            x0_i = x0(i) + dispx(i) *  obj.expTimeRatio * (expi - 1)/(expNumOfPoints - 1);
                            y0_i = y0(i) + dispy(i) *  obj.expTimeRatio * (expi - 1)/(expNumOfPoints - 1);
                        end
                        
                        x0_i = x0_i*obj.multiasmpling;
                        y0_i = y0_i*obj.multiasmpling;
                        pSize_i = pSize(i)*obj.multiasmpling;
                        
                        
                        AreaSize = pSize_i;
                        minx = round((x0_i - AreaSize - 1));
                        maxx = round((x0_i + AreaSize + 1));
                        miny = round((y0_i - AreaSize - 1));
                        maxy = round((y0_i + AreaSize + 1));
                        minx = min(size(im,2),max(1,minx));
                        maxx = min(size(im,2),max(1,maxx));
                        miny = min(size(im,1),max(1,miny));
                        maxy = min(size(im,1),max(1,maxy));
                        
                        s2 = (pSize_i/3)^2;%квадрат сигмы
                        for x = minx:maxx
                            for y = miny:maxy
                                v =  obj.gauss2d(x,y,x0_i,y0_i,s2,val(i));
                                im(y,x) = im(y,x) + v;
                            end
                        end
                    end
                end
                
                im = imresize(im, 1/obj.multiasmpling);
                im = min(1,im);
                im = im + rand(size(im))*obj.noiseLevel;
                ims{im_i} = im;
            end
            
            obj.ims = ims;
            toc
        end
        %%
        function plot_pair(obj)
            figure('name','f1');
            im_i = 1;
            while ~isempty(findobj('type','figure','name','f1'))
                imshow(obj.ims{im_i});
                hold on;
                pause(0.7);
                if im_i == 1
                    im_i = 2;
                    title('1');
                else
                    im_i = 1;
                    title('2');
                end
            end
        end
    end
    %%
    
    %% Служебные функции
    methods(Static)
        function v = gauss2d(x,y,x0,y0,sigma2,val)
            v = val*exp(-(x-x0)^2/2/sigma2 -(y-y0)^2/2/sigma2);
        end
    end
    
end


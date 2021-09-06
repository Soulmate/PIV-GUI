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
classdef TestImageGenerator_v2 < handle
    %TestImageGenerator_v1 герегирует тестовые изображения по параметрам, перечисленным в файле
    %   TODO описать пример
    
    properties
        % изображение
        im__size = 128*[1 2] ; %y x
        im__noiseLevel = 0.1;  % типичное знаениче 0.1, максимальное значение случайного шума, в абсолютных единицах яркости
        im__multiasmpling = 4; % типичное значение 4
        im__expTimeRatio = 0; %отношение экспозиции к межкадровому промежутку (0 - 1, чем больше, тем более смазанные частицы)
        
        % смещение частиц за кадр (глобальное)
        d_uniform_xy = [10 -10];%[15.508 17.195]; %x y
        d_uniform_scatt_xy = 1*[1 1]; %x y
        
        % частицы
        p_density = 0.03; % частиц на квадратный пиксель
        pv_min = 1; % минимальное значение яркости
        pv_max = 1;   % максимальное значение яркости
        ps_mean = 3; % средний размер частиц
        ps_std = 0.1;   % std размеров частиц
        
        
        % положения и смещения частиц
        x;
        y;
        ps; %размер частиц
        pv; %яркость частиц на 1 и 2 кадре в 2 колонки
        dx;
        dy;
        N; %всего частиц (в т.ч. вне области видимости)
        
        % изображения
        ims;
    end
    
    methods
        function obj = TestImageGenerator_v2()
            %TestImageGenerator_v1 Construct an instance of this class
            %   Detailed explanation goes here
        end
        
        function Save_images(obj, folder_path)
            if ~exist(folder_path,'dir'), mkdir(folder_path); end
            for i = 1:numel(obj.ims)
                imwrite(obj.ims{i}, sprintf('%s\\%d.jpg',folder_path,i));
            end
        end
        
        function Save_images_pair(obj, folder_path, i1, i2)
            if ~exist(folder_path,'dir'), mkdir(folder_path); end            
            imwrite(obj.ims{1}, sprintf('%s\\%08d.jpg',folder_path,i1));
            imwrite(obj.ims{2}, sprintf('%s\\%08d.jpg',folder_path,i2));
        end
        %%
        function calc__pos(obj, dx_max, dx_min, dy_max, dy_min) % равномерно распределить частицы, смещения и размеры по гауссу         
            %             TODO добавить возможность менять параметры без перегенерации
            
            % область, в которой надо генерировать частицы
            % с учетом того, что частицы будут смещаться
            % ТУДУ - пока работает только для пары изображений
            x_min =                     min(0, -dx_max); %3 сигмы
            y_min =                     min(0, -dy_max); 
            x_max = obj.im__size(2) +   max(0, -dx_min);
            y_max = obj.im__size(1) +   max(0, -dy_min);
            A = (x_max - x_min) * (y_max - y_min); %площадь области
            obj.N = round(A * obj.p_density);
            obj.x = x_min + (x_max - x_min) * rand([obj.N, 1]);
            obj.y = y_min + (y_max - y_min) * rand([obj.N, 1]);
        end
        function calc__displ(obj)             
            obj.dx = obj.d_uniform_xy(1) + obj.d_uniform_scatt_xy(1) * randn([obj.N, 1]);
            obj.dy = obj.d_uniform_xy(2) + obj.d_uniform_scatt_xy(2) * randn([obj.N, 1]);
        end
        function calc__sizes(obj)    
            obj.ps = obj.ps_mean + obj.ps_std * randn([obj.N, 1]);
        end
        function calc__brightnesses(obj)    
            obj.pv(:,1) = obj.pv_min + (obj.pv_max - obj.pv_min) * rand([obj.N, 1]);
            obj.pv(:,2) = obj.pv_min + (obj.pv_max - obj.pv_min) * rand([obj.N, 1]);
        end
        function plot_distributions(obj)    
            %%
            clf
            subplot(3,3,1)
            hold on;
            rectangle('Position',[0 0 obj.im__size(2) obj.im__size(1)]);
            plot(obj.x, obj.y,'.r'); 
            plot(obj.x + obj.dx, obj.y + obj.dy,'.g')
            axis equal
            set(gca,'ydir','reverse');
            xlabel('x');
            ylabel('y');
            title('Положения: точки')
            
            subplot(3,3,2)
            hold on;
            rectangle('Position',[0 0 obj.im__size(2) obj.im__size(1)]);
            quiver(obj.x, obj.y, obj.dx, obj.dy, 0, 'k');
            axis equal
            set(gca,'ydir','reverse');
            xlabel('x');
            ylabel('y');
            title('Положения: векторное поле')
            
            numbins = round(obj.N / 10);
            subplot(3,3,3)            
            histogram(obj.x,numbins);hold on
            xlabel('x, px')
            title('Распределение положений')
            
            subplot(3,3,4)
            histogram(obj.y,numbins);hold on
            xlabel('y, px')
            title('Распределение положений')
            
            subplot(3,3,5)
            histogram(obj.dx,numbins);hold on
            xlabel('dx, px')
            title('Распределение смещений')
            
            subplot(3,3,6)
            histogram(obj.dy,numbins);hold on
            xlabel('dy, px')
            title('Распределение смещений')
            
            subplot(3,3,7)
            histogram(obj.ps,numbins);hold on
            xlabel('particle size, px')
            title('Распределение размеров')
            
            subplot(3,3,8)
            histogram(obj.pv(:,1),numbins);hold on
            xlabel('particle brightness (frame 1), px')
            title('Распределение яркостей на 1 кадре')
            
            subplot(3,3,9)
            histogram(obj.pv(:,2),numbins);hold on
            xlabel('particle brightness (frame 2), px')
            title('Распределение яркостей на 2 кадре')
        end
        %%
        
        
        function im = generate_image(obj, x0, y0, v0) %строит одно изображение в т.ч. со стриками частиц
            im = zeros(obj.im__size * obj.im__multiasmpling); % увеличенное изображение
            
            for i = 1:obj.N
                pSize_i = obj.ps(i)*obj.im__multiasmpling;
                
                d_i = sqrt(obj.dx(i)*obj.dx(i) + obj.dy(i)*obj.dy(i));
                expNumOfPoints = round(d_i * obj.im__expTimeRatio/obj.ps(i)*2); %число экспозиций чтобы симулировать стрик
                
                if expNumOfPoints < 1
                    expNumOfPoints = 1;
                end
                
                for expi = 1:expNumOfPoints %номер экспозиции
                    if expNumOfPoints <= 1
                        x0_i = x0(i);
                        y0_i = y0(i);
                    else
                        x0_i = x0(i) + obj.dx(i) *  obj.im__expTimeRatio * (expi - 1)/(expNumOfPoints - 1);
                        y0_i = y0(i) + obj.dy(i) *  obj.im__expTimeRatio * (expi - 1)/(expNumOfPoints - 1);
                    end
                    
                    x0_i = x0_i*obj.im__multiasmpling;
                    y0_i = y0_i*obj.im__multiasmpling;
                                        
                    % область на которой будет вычисляться яркость
                    AreaSize = pSize_i;  % размер области
                    minx = round((x0_i - AreaSize - 1));
                    maxx = round((x0_i + AreaSize + 1));
                    miny = round((y0_i - AreaSize - 1));
                    maxy = round((y0_i + AreaSize + 1));
                    minx = min(size(im,2),max(1,minx));
                    maxx = min(size(im,2),max(1,maxx));
                    miny = min(size(im,1),max(1,miny));
                    maxy = min(size(im,1),max(1,maxy));
                    
                    s2 = (pSize_i/3)^2;%квадрат сигмы
                    for pixel_x = minx:maxx
                        for pixel_y = miny:maxy
                            v =  obj.gauss2d( pixel_x, pixel_y, x0_i, y0_i, s2, v0(i) );
                            im(pixel_y,pixel_x) = im(pixel_y,pixel_x) + v;
                        end
                    end
                end
            end
            
            im = imresize(im, 1/obj.im__multiasmpling);
            %% постобработка
            %добавление шума
            im = im + rand(size(im))*obj.im__noiseLevel; 
            
            %наложение частиц не увеличит яркость, клипим ее
            im = min(1,im);
        end
        
        function Generate_pair(obj)
            obj.ims = cell(2,1);
            x0s = cell(2,1);
            y0s = cell(2,1);
            x0s{1} = obj.x;
            y0s{1} = obj.y;
            x0s{2} = obj.x + obj.dx;
            y0s{2} = obj.y + obj.dy;
            for i = 1:2    
                obj.ims{i} = obj.generate_image(x0s{i}, y0s{i}, obj.pv(:,i));
            end
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


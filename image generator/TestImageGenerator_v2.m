% TODO
%         ����� �������� (�������� ������������� �������������)
%         ���������� �������� (������ ������, ��������� �������)
%         ���������� �������
%         ������������� ��������
%
%         ������ ��
%         ��������,
%         ������� ����,
%         ������� ������� (�������� �������������),
%         ���������� ������ � ����
%         ��� ���������� �������
%
%         ���������� �������������
%         ������ ���� �� ����

%%
classdef TestImageGenerator_v2 < handle
    %TestImageGenerator_v1 ���������� �������� ����������� �� ����������, ������������� � �����
    %   TODO ������� ������
    
    properties
        % �����������
        im__size = 128*[1 2] ; %y x
        im__noiseLevel = 0.1;  % �������� �������� 0.1, ������������ �������� ���������� ����, � ���������� �������� �������
        im__multiasmpling = 4; % �������� �������� 4
        im__expTimeRatio = 0; %��������� ���������� � ������������ ���������� (0 - 1, ��� ������, ��� ����� ��������� �������)
        
        % �������� ������ �� ���� (����������)
        d_uniform_xy = [10 -10];%[15.508 17.195]; %x y
        d_uniform_scatt_xy = 1*[1 1]; %x y
        
        % �������
        p_density = 0.03; % ������ �� ���������� �������
        pv_min = 1; % ����������� �������� �������
        pv_max = 1;   % ������������ �������� �������
        ps_mean = 3; % ������� ������ ������
        ps_std = 0.1;   % std �������� ������
        
        
        % ��������� � �������� ������
        x;
        y;
        ps; %������ ������
        pv; %������� ������ �� 1 � 2 ����� � 2 �������
        dx;
        dy;
        N; %����� ������ (� �.�. ��� ������� ���������)
        
        % �����������
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
        function calc__pos(obj, dx_max, dx_min, dy_max, dy_min) % ���������� ������������ �������, �������� � ������� �� ������         
            %             TODO �������� ����������� ������ ��������� ��� �������������
            
            % �������, � ������� ���� ������������ �������
            % � ������ ����, ��� ������� ����� ���������
            % ���� - ���� �������� ������ ��� ���� �����������
            x_min =                     min(0, -dx_max); %3 �����
            y_min =                     min(0, -dy_max); 
            x_max = obj.im__size(2) +   max(0, -dx_min);
            y_max = obj.im__size(1) +   max(0, -dy_min);
            A = (x_max - x_min) * (y_max - y_min); %������� �������
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
            title('���������: �����')
            
            subplot(3,3,2)
            hold on;
            rectangle('Position',[0 0 obj.im__size(2) obj.im__size(1)]);
            quiver(obj.x, obj.y, obj.dx, obj.dy, 0, 'k');
            axis equal
            set(gca,'ydir','reverse');
            xlabel('x');
            ylabel('y');
            title('���������: ��������� ����')
            
            numbins = round(obj.N / 10);
            subplot(3,3,3)            
            histogram(obj.x,numbins);hold on
            xlabel('x, px')
            title('������������� ���������')
            
            subplot(3,3,4)
            histogram(obj.y,numbins);hold on
            xlabel('y, px')
            title('������������� ���������')
            
            subplot(3,3,5)
            histogram(obj.dx,numbins);hold on
            xlabel('dx, px')
            title('������������� ��������')
            
            subplot(3,3,6)
            histogram(obj.dy,numbins);hold on
            xlabel('dy, px')
            title('������������� ��������')
            
            subplot(3,3,7)
            histogram(obj.ps,numbins);hold on
            xlabel('particle size, px')
            title('������������� ��������')
            
            subplot(3,3,8)
            histogram(obj.pv(:,1),numbins);hold on
            xlabel('particle brightness (frame 1), px')
            title('������������� �������� �� 1 �����')
            
            subplot(3,3,9)
            histogram(obj.pv(:,2),numbins);hold on
            xlabel('particle brightness (frame 2), px')
            title('������������� �������� �� 2 �����')
        end
        %%
        
        
        function im = generate_image(obj, x0, y0, v0) %������ ���� ����������� � �.�. �� �������� ������
            im = zeros(obj.im__size * obj.im__multiasmpling); % ����������� �����������
            
            for i = 1:obj.N
                pSize_i = obj.ps(i)*obj.im__multiasmpling;
                
                d_i = sqrt(obj.dx(i)*obj.dx(i) + obj.dy(i)*obj.dy(i));
                expNumOfPoints = round(d_i * obj.im__expTimeRatio/obj.ps(i)*2); %����� ���������� ����� ������������ �����
                
                if expNumOfPoints < 1
                    expNumOfPoints = 1;
                end
                
                for expi = 1:expNumOfPoints %����� ����������
                    if expNumOfPoints <= 1
                        x0_i = x0(i);
                        y0_i = y0(i);
                    else
                        x0_i = x0(i) + obj.dx(i) *  obj.im__expTimeRatio * (expi - 1)/(expNumOfPoints - 1);
                        y0_i = y0(i) + obj.dy(i) *  obj.im__expTimeRatio * (expi - 1)/(expNumOfPoints - 1);
                    end
                    
                    x0_i = x0_i*obj.im__multiasmpling;
                    y0_i = y0_i*obj.im__multiasmpling;
                                        
                    % ������� �� ������� ����� ����������� �������
                    AreaSize = pSize_i;  % ������ �������
                    minx = round((x0_i - AreaSize - 1));
                    maxx = round((x0_i + AreaSize + 1));
                    miny = round((y0_i - AreaSize - 1));
                    maxy = round((y0_i + AreaSize + 1));
                    minx = min(size(im,2),max(1,minx));
                    maxx = min(size(im,2),max(1,maxx));
                    miny = min(size(im,1),max(1,miny));
                    maxy = min(size(im,1),max(1,maxy));
                    
                    s2 = (pSize_i/3)^2;%������� �����
                    for pixel_x = minx:maxx
                        for pixel_y = miny:maxy
                            v =  obj.gauss2d( pixel_x, pixel_y, x0_i, y0_i, s2, v0(i) );
                            im(pixel_y,pixel_x) = im(pixel_y,pixel_x) + v;
                        end
                    end
                end
            end
            
            im = imresize(im, 1/obj.im__multiasmpling);
            %% �������������
            %���������� ����
            im = im + rand(size(im))*obj.im__noiseLevel; 
            
            %��������� ������ �� �������� �������, ������ ��
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
    
    %% ��������� �������
    methods(Static)
        function v = gauss2d(x,y,x0,y0,sigma2,val)
            v = val*exp(-(x-x0)^2/2/sigma2 -(y-y0)^2/2/sigma2);
        end
    end
    
end


classdef Image_loader < handle
    %IMLOADER Класс загрузки изображений
    %   bufferSize - размер буфера, можно не указывать
    
    properties
        path;
        imagePaths;
        bufferSize;
        indexArray;
        imArray;
        imSize;
        imNum;
        % свойста, которые стоит менять после конструктора:        
        use_ind2gray; %индексное изображение, для файлов которые пишет TimeBench
    end
    
    methods
        function il = Image_loader( impath, imagesExt, bufferSize )
            if nargin > 0
                %                 disp('Reading Folder....')
                if ~exist(impath,'dir'), error('=== no folder === '); end
                tic
                il.path = impath;
                if  ~exist('imagesExt','var') || isempty(imagesExt)
                    d = dir ([impath '\*']);
                    d = d(4);
                    [~,~,imagesExt] = fileparts(d.name);
                end
                if imagesExt(1) == '.', imagesExt = imagesExt(2:end); end
                if  ~exist('bufferSize','var') || isempty(bufferSize), bufferSize = 10;  end                
                il.bufferSize = bufferSize;
                %% чтение папки с изображениями
                %                 imagesExt = 'jpg';
                il.imagePaths = FilesInFolder( il.path , imagesExt, true);
                if isempty(il.imagePaths), error('Пустая папка'); end
                
                il.indexArray = zeros(il.bufferSize,1);
                il.imArray = cell(il.bufferSize,1);
                il.imNum = numel(il.imagePaths);
                im = imread(il.imagePaths{1});
                il.imSize = fliplr(size(im(:,:,1)));
                %                 fprintf('File info loaded in %g sec\nTotal number of frames %d\n',toc, il.imNum);
            else
                error('!!!! need path in constructor');
            end
        end
        
        function im = getImage(obj, i)
            if (obj.bufferSize > 0)
                ii = find(obj.indexArray == i);
                if ~isempty(ii)
                    im = obj.imArray{ii};
                    return;
                end
            end            
            
            if isempty(obj.use_ind2gray)
                try 
                    im = imread(obj.imagePaths{i});
                catch
                    im = [];
                    return;
                end
            else
                [im, rgbmap] = imread(obj.imagePaths{i});
                im = ind2gray(im,rgbmap);
            end            
                        
            % буфферизация:
            if (obj.bufferSize > 0)
                obj.indexArray = circshift(obj.indexArray,1);
                obj.imArray = circshift(obj.imArray,1);
                obj.indexArray(1) = i;
                obj.imArray{1} = im;
            end            
        end
        
        function imPath = getImagePath(obj,i)
            imPath = obj.imagePaths{i};
        end
        
        function ResetCache(obj)
            obj.indexArray = zeros(obj.bufferSize,1);
            obj.imArray = cell(obj.bufferSize,1);
        end
    end    
end
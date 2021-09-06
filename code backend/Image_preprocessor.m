classdef Image_preprocessor < handle
    %IMLOADER Класс загрузки изображений
    %   bufferSize - размер буфера, можно не указывать
    properties (Access = private)   
        ip 
        imSize;
        imNum;
        
        bufferSize
        indexArray;
        imArray;
        
        params Image_preprocessor_params
    end
    
    methods
        function obj = Image_preprocessor( ip, params, bufferSize )
            obj.ip = ip;
            obj.imNum = ip.imNum;
            obj.imSize = ip.imSize; 
            obj.params = params;            
            obj.bufferSize = bufferSize;                           
            % очистить буффер            
            obj.indexArray = zeros(obj.bufferSize,1);
            obj.imArray = cell(obj.bufferSize,1);
        end
        %%
        function im = getImage(obj, i)
            if (obj.bufferSize > 0)
                ii = find(obj.indexArray == i);
                if ~isempty(ii)
                    im = obj.imArray{ii};
                    return;
                end
            end
                        
            im = obj.ip.getImage(i);
            im = im(:,:,obj.params.color_channel);
            
            if obj.params.bg_on &&  ~isempty(obj.params.bg)
                switch obj.params.bg_cut_type
                    case 'max'
                        im = max(obj.params.bg_cut_val, double(im) - double(obj.params.bg));
                    case 'min'
                        im = min(obj.params.bg_cut_val, double(im) - double(obj.params.bg));
                    case 'none'
                        im = double(im) - double(obj.bg);
                    otherwise
                        warning('Unexpected bg_cut_type');
                        im = double(im) - double(obj.bg);
                end
            end
            
            if obj.params.mask_on && ~isempty(obj.params.mask)                
                im( obj.params.mask ) = obj.params.mask_set_value;
            end
            
            if obj.params.levels_on
                im = mat2gray(im,obj.params.levels_limits);
            end
            
            % буфферизация:
            if (obj.bufferSize > 0)
                obj.indexArray = circshift(obj.indexArray,1);
                obj.imArray = circshift(obj.imArray,1);
                obj.indexArray(1) = i;
                obj.imArray{1} = im;
            end
        end  
    end
end

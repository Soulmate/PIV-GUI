classdef Array_temp_storage < handle
    %Array_temp_storage Cell массив с автоматическим сохранением данных на диск
    %   A = Array_temp_storage(101, 10, "temp_storage");
    %  В него можно сохранять и извлекать данные как в cell array.
    %  На ХДД данные сохраняются сегментами. Автоматически сегменты
    %  сохраняются на ХДД в момент добавления/изменения элементов когда
    %  они заполнены целиком но при этом не являются текущими. Если писать
    %  данные в случайном порядке, сегменты будут заполняться медленно и не
    %  будут сохраняться на ХДД. При чтении весь сегмент извлекается из
    %  памяти, неактивные полные сегменты при этом убираются
    
    %     data_size - размер массива с данными
    %     seg_size - разммер сегмента. Может быть не
    %     кратен размеру данных, может превышать размер данных или быть Inf
    %     (тогда будет один сегмент, который сохранится на ХДД только по
    %     требованию через Move_all_to_hdd)
    %     storage_file_path_base - основа пути к файлам с данными. она добивается  " ats_seg0005"
    %     rw_options:
    %     'replace' - если есть старые файлы, удалить их
    %     'read' - прочитать старые файлы, если из не достаотчно, выдать
    %     предупреждение
    %     'new' - если есть старые файлы выдать ошибку
    
    %%
    properties (SetAccess = protected, GetAccess = public)
        
        seg_in_mem
        seg_count
        seg_i_arr %для каждого элемента номер сегмента
        data_i_in_seg %для каждого сегмента номера элементов
        data_is_empty_arr
        
        data_size
        seg_size
        
        storage_file_path_base
        storage_file_path_arr
        
        data
        
        version = 1;
    end
    %%
    methods
        function obj = Array_temp_storage(data_size, seg_size, storage_file_path_base)            
            obj.data_size = data_size;
            obj.seg_size = seg_size;
            
            obj.data = cell(obj.data_size,1);
            
            % распределяем элементы по сегментам
            obj.seg_i_arr = zeros(obj.data_size,1);
            seg_i = 1;
            items_in_current_seg = 0;
            for i = 1:obj.data_size
                if items_in_current_seg >= seg_size
                    seg_i = seg_i + 1;
                    items_in_current_seg = 0;
                end
                obj.seg_i_arr(i)  = seg_i;
                items_in_current_seg = items_in_current_seg + 1;
            end
            obj.seg_count = obj.seg_i_arr(end);
            obj.data_i_in_seg = cell(obj.seg_count,1);
            for i = 1:obj.seg_count
                obj.data_i_in_seg{i} = find(obj.seg_i_arr == i);
            end
            
            obj.seg_in_mem  = true(obj.seg_count,1);
            
            % файлы для хранения. Если существуют, то удалить все файлы с
            % такой базой
            obj.storage_file_path_base = storage_file_path_base;
            delete( [ obj.storage_file_path_base '*' ] ); 
            obj.storage_file_path_arr = cell(obj.seg_count,1);
            for seg_i = 1:obj.seg_count
                obj.storage_file_path_arr{seg_i} = sprintf( '%s ats_seg%04d.mat', obj.storage_file_path_base, seg_i );
            end    
            
            obj.data_is_empty_arr = true(obj.data_size,1);
        end
        
        function Set(obj, i, item)
            if i < 1 || i > obj.data_size, return; end
            
            % если сегмент на хдд, то возвращаем его в память
            current_segment = obj.seg_i_arr(i);
            if ~obj.seg_in_mem( current_segment )
                obj.Seg_move_from_hdd( current_segment );
            end
            
            obj.data{i} = item;
            obj.data_is_empty_arr(i) = false;
            
            % проверим есть ли полные сегменты кроме текущего и их
            % переместим на хдд
            seg_is_full_arr = obj.Get_seg_is_full();
            seg_is_full_arr(current_segment) = false;
            seg_to_move = find( seg_is_full_arr & obj.seg_in_mem );
            for seg_to_move_i = 1:numel(seg_to_move)
                obj.Seg_move_to_hdd( seg_to_move(seg_to_move_i) );
            end
        end
        
        function item = Get(obj, i)
            if i < 1 || i > obj.data_size
                item = [];
                return;
            end
            
            % если сегмент на хдд, то возвращаем его в память
            current_segment = obj.seg_i_arr(i);
            if ~obj.seg_in_mem(current_segment)
                obj.Seg_move_from_hdd( current_segment );
            end
            
            item = obj.data{i};
            
            % проверим есть ли полные сегменты кроме текущего и их
            % переместим на хдд
            
            seg_is_full_arr = obj.Get_seg_is_full();
            
            seg_is_full_arr(current_segment) = false;
            seg_to_move = find( seg_is_full_arr & obj.seg_in_mem );
            
            for seg_to_move_i = 1:numel(seg_to_move)
                obj.Seg_move_to_hdd( seg_to_move(seg_to_move_i) );
            end
            
        end
        
        function [output, data_is_empty_arr]  = Get_all_as_cell(obj)
            output = cell(obj.data_size,1);
            for i = 1:obj.data_size
                output{i} = obj.Get(i);
            end
            data_is_empty_arr = obj.data_is_empty_arr;
        end
        
        function [output, data_is_empty_arr] = Get_as_cell(obj, ti_arr)
            output = cell(numel(ti_arr),1);
            for i = 1:numel(ti_arr)
                output{i} = obj.Get(ti_arr(i));
            end
            data_is_empty_arr = obj.data_is_empty_arr(ti_arr(i));
        end
        
        function Remove_all_files(obj)
            for i = 1:obj.seg_count
                if exist(obj.storage_file_path_arr{i},'file')
                    delete(obj.storage_file_path_arr{i});
                end
            end
        end
        
        function Move_all_to_hdd(obj)
            seg_in_mem_arr =  find(obj.seg_in_mem);
            for i = 1:numel(seg_in_mem_arr)
                obj.Seg_move_to_hdd(seg_in_mem_arr(i));
            end
        end
        
        function Clear(obj)
            obj.Remove_all_files();
            obj.data = cell(obj.data_size,1);
            obj.data_is_empty_arr = true(obj.data_size,1);
            obj.seg_in_mem  = true(obj.seg_count,1);
        end
        
        function Export_to_file(obj, file_path_base) % сохраняет все данные в зип файл и файл с инфой
            % файл с информацией:
            info_file_path = sprintf( '%s info.mat', file_path_base );    
            data_size = obj.data_size;
            seg_size = obj.seg_size;
            version = obj.version;
            data_is_empty_arr = obj.data_is_empty_arr;
            
            if ~exist(fileparts(info_file_path),'dir'), mkdir(fileparts(info_file_path)); end
            save(info_file_path, 'version', 'data_size', 'seg_size', 'data_is_empty_arr');
            
            % файлы с данными
            obj.Move_all_to_hdd();      
            data_file_path = sprintf( '%s data.zip', file_path_base );           
            zip( data_file_path, obj.storage_file_path_arr );
        end
        
        function Import_from_file(obj, file_path_base)            
            info_file_path = sprintf( '%s info.mat', file_path_base ); % файл с информацией
            data_file_path = sprintf( '%s data.zip', file_path_base ); % файлы с данными                
            if ~exist(info_file_path,'file')
                warning('Ошибка загрузки: нет файла с данными %s', file_path_base ); 
                return;
            end
            if ~exist(data_file_path,'file')
                warning('Ошибка загрузки: нет файла с данными %s', data_file_path ); 
                return;
            end
            
            % очистим временные файлы
            obj.Clear();            
                        
            % файл с информацией
            f_info = load(info_file_path, 'version', 'data_size', 'seg_size', 'data_is_empty_arr');
            if obj.version ~= f_info.version
                error('Ошибка загрузки: не совпадающая версия');
            end
            if obj.data_size ~= f_info.data_size
                error('Ошибка загрузки: неправильный размер: %s', info_file_path);
            end
            if obj.seg_size  ~= f_info.seg_size                
                obj = Array_temp_storage(obj.data_size, f_info.seg_size, obj.storage_file_path_base);
                warning('Данные с другим размером сегмента, размер сегмента изменен на %d: %s', obj.seg_size, info_file_path);
            end
            obj.data_is_empty_arr = f_info.data_is_empty_arr;
            
            % файлы с данными распакуем во временную директорию
            filenames  = unzip( data_file_path, obj.storage_file_path_base );
            %проверяем файлы
            if numel(filenames) ~= numel(obj.storage_file_path_arr)
                warning('Файл с данными не может быть загружен, неправильное количество файлов: %s', data_file_path ); 
                delete(filenames{:});
                rmdir(temp_folder);
                return
            end            
            
            obj.seg_in_mem  = false(obj.seg_count,1); %все данные только на винчестере  
        end
    end
    %%
    methods (Access = private)
        function Seg_move_to_hdd(obj, seg_i)
%                         disp(['Seg_move_to_hdd ' num2str(seg_i)])
            if ~obj.seg_in_mem(seg_i)
                warinig('Seg_move_to_hdd: segment is not in memory');
                return; 
            end
            data_in_seg_i = obj.data_i_in_seg{seg_i};
            data_in_seg = obj.data(data_in_seg_i);
            file_path = obj.storage_file_path_arr{seg_i};
            if ~exist(fileparts(file_path),'dir')
                mkdir(fileparts(file_path));
            end
            save(file_path,'data_in_seg');
            for i =1:numel(data_in_seg_i)
                obj.data{data_in_seg_i(i)} = [];
            end
            obj.seg_in_mem(seg_i) = false;
        end
        function Seg_move_from_hdd(obj, seg_i)
%                         disp(['Seg_move_from_hdd ' num2str(seg_i)])
            data_in_seg_i = obj.data_i_in_seg{seg_i};
            file_path = obj.storage_file_path_arr{seg_i};
            f = load(file_path,'data_in_seg');
            data_in_seg = f.data_in_seg;
            for i =1:numel(data_in_seg_i)
                obj.data{data_in_seg_i(i)} = data_in_seg{i};
            end
            obj.seg_in_mem(seg_i) = true;
        end
        function seg_is_full_arr = Get_seg_is_full(obj)            
            seg_is_full_arr = false(obj.seg_count,1);
            for seg_i = 1:obj.seg_count 
                is_full = ~any( obj.data_is_empty_arr( obj.data_i_in_seg{seg_i} ) );
                seg_is_full_arr(seg_i) = is_full;
            end            
        end
    end
end
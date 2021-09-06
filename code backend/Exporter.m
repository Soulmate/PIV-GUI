classdef Exporter < handle
    %UNTITLED8 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        decimal_delimeter = '.';
        column_delimeter = '\t';
        %         save_header = true; TODO
        ommit_nans = false;
    end
    
    methods
        
        function Export_all_fields_to_one_file( obj, file_path, data, transform_processor )
            %             data - что-то типа Array_temp_storage, имеет метод Get(ti) и размером с pf
            %             Get возвращает какую-то структуру, содержащую матрицы xdispl, ydispl и status (все числовые), размером с pg
            if exist(file_path,'file')
                delete(file_path);
            end            
            if ~exist(fileparts(file_path),'dir'), mkdir(fileparts(file_path)); end
            fileID = fopen(file_path,'w');
            for ti = 1:numel(transform_processor.time)                
                t = transform_processor.time(ti);
                x = transform_processor.xMat;
                y = transform_processor.yMat;
                d = data.Get(ti);
                if ~isempty(d)
                    xd  = transform_processor.Convert_xdispl( d.xdispl );
                    yd  = transform_processor.Convert_ydispl( d.ydispl );
                else
                    xd = nan;
                    yd = nan;
                end
                %                 status  =  d.status;
                for i = 1:numel(x)
                    if obj.ommit_nans && (isnan(xd(i)) || isnan(yd(i)))
                        continue;
                    end
                    output_string = sprintf('%f%s%f%s%f%s%f%s%f\r\n',...
                        x (i),  obj.column_delimeter,...
                        y (i),  obj.column_delimeter,...
                        t,      obj.column_delimeter,...
                        xd(i),  obj.column_delimeter,...
                        yd(i));
                    if obj.decimal_delimeter ~= '.'
                        output_string(output_string == '.') = obj.decimal_delimeter;
                    end
                    fprintf(fileID,output_string);
                end
            end
            fclose(fileID);
        end
        %%
        function Export_all_fields_to_separate_files( obj, file_path_base, data, transform_processor )
            %             data - что-то типа Array_temp_storage, имеет метод Get(ti) и размером с pf
            %             Get возвращает какую-то структуру, содержащую матрицы xdispl, ydispl и status (все числовые), размером с pg
            if ~exist(fileparts(file_path_base),'dir'), mkdir(fileparts(file_path_base)); end            
            for ti = 1:numel(transform_processor.time)
                t = transform_processor.time(ti);     
                if ~contains( file_path_base, '~info~')
                    error('Путь должен содержать подстроку ~info~');
                end
                file_path = strrep( file_path_base, '~info~', ...
                    sprintf(', time %08.5f', t) );                
                if exist(file_path,'file')
                    delete(file_path);
                end                
                d = data.Get(ti);
                x = transform_processor.xMat;
                y = transform_processor.yMat;
                xd  = transform_processor.Convert_xdispl( d.xdispl );
                yd  = transform_processor.Convert_ydispl( d.ydispl );
                obj.Export_one_field_to_file( file_path, x, y, xd, yd );
            end
        end
        %%
        function Export_time_series_to_separate_files( obj, file_path_base, ts, transform_processor, pos_ij_arr )
            %             file_path_base - путь к файлам, должен содержать подстроку '~info~', которая заменится на инфо текущего кадра
            %             ts - в пикселях на кадр
            if ~exist(fileparts(file_path_base),'dir'), mkdir(fileparts(file_path_base)); end
            for pos_ij_arr_i = 1:size(ts,3)                                
                pos_i = pos_ij_arr(pos_ij_arr_i,1);
                pos_j = pos_ij_arr(pos_ij_arr_i,2);
                x = transform_processor.xMat(pos_i,pos_j);
                y = transform_processor.yMat(pos_i,pos_j);                
                if ~contains( file_path_base, '~info~')
                    error('Путь должен содержать подстроку ~info~');
                end
                file_path = strrep( file_path_base, '~info~', ...
                    sprintf(', pos_i %d, pos_j %d, x %.5f, y %.5f', pos_i, pos_j, x, y) );                
                if exist(file_path,'file')
                    delete(file_path);
                end                
                fileID = fopen(file_path,'w');
                for i = 1:size(ts,1)                    
                    t  = ts(i, 2, pos_ij_arr_i);
                    xd = ts(i, 3, pos_ij_arr_i);
                    yd = ts(i, 4, pos_ij_arr_i);
                    xd_mps  = transform_processor.Convert_xdispl( xd );
                    yd_mps  = transform_processor.Convert_ydispl( yd );
                    
                    if obj.ommit_nans && (isnan(xd) || isnan(yd))
                        continue;
                    end
                    output_string = sprintf('%f%s%f%s%f\r\n',...
                        t ,  obj.column_delimeter,...
                        xd_mps,  obj.column_delimeter,...
                        yd_mps);
                    if obj.decimal_delimeter ~= '.'
                        output_string(output_string == '.') = obj.decimal_delimeter;
                    end
                    fprintf(fileID,output_string);
                end
                
                fclose(fileID);
            end
        end
        
        
        
        
        
        
        %%
        function Export_one_field_to_file( obj, file_path, x_m, y_m, xd_mps, yd_mps )
            if exist(file_path,'file')
                delete(file_path);
            end
            fileID = fopen(file_path,'w');
            for i = 1:numel(x_m)
                if obj.ommit_nans && (isnan(xd_mps(i)) || isnan(yd_mps(i)))
                    continue;
                end
                output_string = sprintf('%f%s%f%s%f%s%f\r\n',...
                    x_m (i),    obj.column_delimeter,...
                    y_m (i),    obj.column_delimeter,...
                    xd_mps(i),  obj.column_delimeter,...
                    yd_mps(i));
                if obj.decimal_delimeter ~= '.'
                    output_string(output_string == '.') = obj.decimal_delimeter;
                end
                fprintf(fileID,output_string);
            end
            fclose(fileID);
        end
        %%
        function Export_profile_to_file( obj, file_path, pos_m, xd_mps, yd_mps)
            pos_m = pos_m(:);
            xd_mps  = xd_mps(:);
            yd_mps  = yd_mps(:);
            if exist(file_path,'file')
                delete(file_path);
            end
            fileID = fopen(file_path,'w');
            for i = 1:numel(pos_m)
                if obj.ommit_nans && (isnan(xd_mps(i)) || isnan(yd_mps(i)))
                    continue;
                end
                output_string = sprintf('%f%s%f%s%f\r\n',...
                    pos_m(i),    obj.column_delimeter,...                    
                    xd_mps (i),  obj.column_delimeter,...
                    yd_mps (i));
                if obj.decimal_delimeter ~= '.'
                    output_string(output_string == '.') = obj.decimal_delimeter;
                end
                fprintf(fileID,output_string);
            end
            fclose(fileID);
        end
        %%
        
    end
end


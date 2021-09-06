classdef PIV_processor < handle
    %Record_processor версия 5
    %   Detailed explanation goes here
    
    properties (Access = private)
        % можно задать только при создании
        pp PIV_params %структуры pp для всей записи  %TODO поддержку разных pp
        pf PIV_frames
        pg PIV_grid
    end
    properties (SetAccess = protected, GetAccess = public)
        %% Вычисляемые параметры
        iteration_time_arr % время на итерацию (только PIV)
        iteration_time_full_arr % полное время на итерацию (включая время между циклами)
        compared_frames__num_of_pairs
        is_processed_arr
        %% временные, работают только для текущей пары
        current_firstFrame_i %текущий номер первого кадра
        current_compared_frames %номера текущих обрабатываемых кадров как в compared_frames_offset
        current_im_arr % такого же размера как compared_frames_offset, и соответствующие кадры
        current_ti % текущий номер пары
        %%
        data     Array_temp_storage; %результаты PIV
        ID_data  Array_temp_storage; %предсмещения
    end
    properties
        iteration_time_full_tic % для полного времени
    end
    
    methods
        function obj = PIV_processor(pp, pf, pg,...
                data_storage_file_path_base, data_seg_size)
            obj.pp = pp;
            obj.pf = pf;
            obj.pg = pg;
            
            obj.compared_frames__num_of_pairs = size(obj.pf.compared_frames_offset,1);
            obj.current_firstFrame_i = nan;
            obj.current_compared_frames = [];
            obj.current_im_arr = [];
            obj.current_ti = nan;
            
                        
            obj.data = Array_temp_storage( ...
                obj.pf.frame_count,...
                data_seg_size,...
                data_storage_file_path_base);
            obj.ID_data = Array_temp_storage( ...
                obj.pf.frame_count,...
                data_seg_size,...
                [ data_storage_file_path_base ' ID_data' ]);
            obj.Reset_processing();
        end
        
        function Reset_processing(obj)
            obj.iteration_time_arr = nan(obj.pf.frame_count,1);
            obj.iteration_time_full_arr = nan(obj.pf.frame_count,1);
            obj.iteration_time_full_tic = [];
            obj.data.Clear();
            obj.is_processed_arr = false(obj.pf.frame_count,1);
        end
        
        function Process_one(obj, ipp, ti)
            piv_iteration_time = tic;
            
            if (ti < 1 || ti > obj.pf.frame_count)
                error('Нужен индекс в firstFrames');
            end
            
            obj.current_ti = ti;
            obj.current_firstFrame_i = obj.pf.first_frames(ti);
            obj.current_compared_frames = obj.current_firstFrame_i + obj.pf.compared_frames_offset;
            obj.current_im_arr = cell(size(obj.current_compared_frames));
            
            for im_arr_i = 1:numel(obj.current_im_arr)
                im = ipp.getImage(obj.current_compared_frames(im_arr_i));
                if isempty(im)
                    return;
                end
                obj.current_im_arr{im_arr_i} = im;
            end
            
            %             for pair_i = 1%:obj.compared_frames__num_of_pairs   TODO для нескольких кадров
            pp_current = obj.pp;
            ID = obj.ID_data.Get(ti);
            if ~isempty(ID)
                pp_current.xIDArr = ID.xIDArr;
                pp_current.yIDArr = ID.yIDArr;
            end
            
            pg_current = obj.pg;
            
            piv_output = DoCC10(...
                obj.current_im_arr{1},...
                obj.current_im_arr{2},...
                pp_current,...
                pg_current);
            obj.data.Set(ti, piv_output);
            %             end
            
            obj.is_processed_arr(ti) = true;
            
            obj.iteration_time_arr(ti) = toc(piv_iteration_time);
            
            if ~isempty(obj.iteration_time_full_tic)
                obj.iteration_time_full_arr(ti) = toc(obj.iteration_time_full_tic);
            end
            obj.iteration_time_full_tic = tic;
        end
        
        
        function info = Get_info(obj)
            ti = obj.current_ti ;
            if ~isnan(ti)
                info = sprintf('осталось %.2f мин., поле %d за, %.4f c (из них PIV %.1f%%)', ...
                    sum(isnan(obj.iteration_time_full_arr))*nanmedian(obj.iteration_time_full_arr)/60,...
                    obj.current_ti,...
                    obj.iteration_time_full_arr(ti),...
                    obj.iteration_time_arr(ti) / obj.iteration_time_full_arr(ti) * 100) ;
            else
                info = '';
            end
        end
        
        function info = Get_info_progress(obj)
            info = sprintf('Обработано %d из %d',...
                sum(obj.is_processed_arr),...
                obj.pf.frame_count);
        end
        
        function Save_data(obj)
            obj.data.Move_all_to_hdd();
        end
    end
end


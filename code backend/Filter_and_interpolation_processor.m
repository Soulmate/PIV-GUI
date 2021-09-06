classdef Filter_and_interpolation_processor < handle
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = private)
        p Filter_and_interpolation_params  %можно поменять только пересоздав
        pf PIV_frames
        pg PIV_grid
    end
    properties
        %         iteration_time_arr % время на итерацию (только фильтрация и интерполяция)
        %         iteration_time_full_arr % полное время на итерацию (включая время между циклами)
        %         iteration_time_full_tic % для полного времени
        % %         compared_frames__num_of_pairs
        %         is_processed_arr
        %
        %         current_ti = nan;
        %         current_stage = 'none';
        %%
        data Array_temp_storage;
    end
    
    methods
        function obj = Filter_and_interpolation_processor( fi_params, pf, pg,...
                data_storage_file_path_base, data_seg_size )
            obj.p = fi_params;
            obj.pf = pf;
            obj.pg = pg;
            
            %             obj.compared_frames__num_of_pairs = size(obj.pf.compared_frames_offset,1);
            
            obj.data = Array_temp_storage( ...
                obj.pf.frame_count,...
                data_seg_size,...
                data_storage_file_path_base);
            
            %             obj.Reset_processing();
        end
        
        %         function Reset_processing(obj)
        %             obj.iteration_time_arr = nan(obj.pf.frame_count,1);
        %             obj.iteration_time_full_arr = nan(obj.pf.frame_count,1);
        %             obj.iteration_time_full_tic = [];
        %             obj.data.Clear();
        %             obj.is_processed_arr = false(obj.pf.frame_count,1);
        %         end
        %%
        function Process_all( obj, data_piv )
            for ti = 1:obj.pf.frame_count
                fprintf( 'stage 1 2, ti %d/%d\n', ti, obj.pf.frame_count )
                obj.Process_one__stage1__local_filtering( data_piv, ti );
                obj.Process_one__stage2__median_space_filtering( ti );
            end
            obj.Process_all_median_time();
            obj.Process_all__interpolate_time();
            for ti = 1:obj.pf.frame_count
                fprintf( 'Process_one__interpolate_space, ti %d/%d\n', ti, obj.pf.frame_count )
                obj.Process_one__interpolate_space( ti );
            end
            
            
            %             iteration_time = tic;
            %             obj.current_ti = ti;
            %             obj.is_processed_arr(ti) = true;
            %             obj.iteration_time_arr(ti) = toc(iteration_time);
            %             if ~isempty(obj.iteration_time_full_tic)
            %                 obj.iteration_time_full_arr(ti) = toc(obj.iteration_time_full_tic);
            %             end
            %             obj.iteration_time_full_tic = tic;
        end
        %%
        function Process_one__stage1__local_filtering(obj, data_piv, ti)
            
            %загружает из piv, фильтрует локально и сохраняет в data (отфильтрованные смещения забивает нанами)
            if isempty(data_piv), return; end
            po = data_piv.Get(ti);
            if isempty(po), return; end
            
            xdispl = po.xdispl; %поля после фильтрации и интерполяции
            ydispl = po.ydispl; %поля после фильтрации и интерполяции
            status = zeros(size(po.status));  % статус фильтрации
            
            %параметры:
            local_filtering__on = obj.p.local_filtering__on;
            CC_ratio_limits = obj.p.CC_ratio_limits;
            CC_maxRaitio_max = obj.p.CC_maxRaitio_max;
            mean_im1_limits = obj.p.mean_im1_limits;
            xd_limits = obj.p.xd_limits;
            yd_limits = obj.p.yd_limits;
            d_limits = obj.p.d_limits;
            
            if local_filtering__on
                status(po.status ~= 0)                        = -po.status(po.status ~= 0)  ; % отброшена на этапе PIV
                status(po.CC_maxRaitio < CC_ratio_limits(1))  = 2; % отброшена по соотношению пиков ККФ
                status(po.CC_maxRaitio > CC_ratio_limits(2))  = 2;
                
                status(po.CC_maxValue > CC_maxRaitio_max)     = 3; % отброшена по значению пика ККФ
                
                status(po.mean_im1 < mean_im1_limits(1))      = 4; % отброшена по яркости изображения в окне
                status(po.mean_im1 > mean_im1_limits(2))      = 4;% если mean_im1_limits НаН, то фильтрации не произойдет
                
                status(xdispl < xd_limits(1))                 = 5; % отброшена по превышению смещения
                status(xdispl > xd_limits(2))                 = 5;
                status(ydispl < yd_limits(1))                 = 5;
                status(ydispl > yd_limits(2))                 = 5;
                
                if ~all(isnan(d_limits) | isinf(d_limits))
                    v = sqrt(po.xdispl .^ 2 + po.ydispl .^ 2);
                    status(v < d_limits(1))                   = 5;
                    status(v > d_limits(2))                   = 5;
                end
                
                xdispl(status ~= 0) = nan;
                ydispl(status ~= 0) = nan;
            end
            
            
            
            fi_output.status = status;
            fi_output.xdispl = xdispl;
            fi_output.ydispl = ydispl;
            obj.data.Set(ti, fi_output);
        end
        %%
        function Process_one__stage2__median_space_filtering(obj, ti)
            % фильтрация по отличию от медианной фильтрации по пространству
            median_space__on                = obj.p.median_space__on;
            median_space__window_size       = obj.p.median_space__window_size;
            median_space__max_d_difference  = obj.p.median_space__max_d_difference;
            if median_space__on
                fi_output = obj.data.Get(ti);
                if isempty(fi_output), return; end
                
                gp = fi_output.status == 0;
                xd = fi_output.xdispl;
                yd = fi_output.ydispl;
                
                xd(~gp) = nan;
                yd(~gp) = nan;
                xd3fs = nanmedfilt2( xd, median_space__window_size );
                yd3fs = nanmedfilt2( yd, median_space__window_size );
                bp = ...
                    abs(xd3fs - xd) > median_space__max_d_difference |...
                    abs(yd3fs - yd) > median_space__max_d_difference;
                fi_output.status(bp)                                = 6;                        % фильтрация по отличию от медианной фильтрации по пространству
                fi_output.xdispl( fi_output.status ~= 0 ) = nan;
                fi_output.ydispl( fi_output.status ~= 0 ) = nan;
                obj.data.Set(ti, fi_output);
            end
        end
        
        function Process_all_median_time(obj )
            % работает с уже отфильтрованными данными
            median_time__on                     = obj.p.median_time__on;
            median_time__max_d_difference       = obj.p.median_time__max_d_difference;
            median_time__dynamic__on            = obj.p.median_time__dynamic__on;  %динамическая намного медленнее, но не требует много памяти
            median_time__dynamic__window_size   = obj.p.median_time__dynamic__window_size;
            
            if median_time__on
                if ~median_time__dynamic__on
                    % вычисляем медианное поле для всей записи
                    fprintf( 'Get_median_field all...\n' );
                    [xd_median, yd_median] = Analyzer.Get_median_field(obj.data); % TODO жрет много памяти, вычислять отдельно по сегментам
                    
                    % этот кусок уже память не жрет, но можно сделать
                    % быстрее за счет памяти
                    for ti = 1:obj.pf.frame_count
                        fprintf( 'Process_all_median_time, ti %d/%d\n', ti, obj.pf.frame_count )
                        
                        fi_output = obj.data.Get(ti);
                        if isempty(fi_output), continue; end
                        
                        xd = fi_output.xdispl;
                        yd = fi_output.ydispl;
                        
                        bp = ...
                            abs(xd_median - xd) > median_time__max_d_difference |...
                            abs(yd_median - yd) > median_time__max_d_difference;
                        
                        fi_output.status(bp)                        = 7;          % фильтрация по отличию от медианной фильтрации по времени
                        fi_output.xdispl(bp) = nan;
                        fi_output.ydispl(bp) = nan;
                        
                        obj.data.Set(ti, fi_output);
                    end
                else
                    for ti = 1:obj.pf.frame_count
                        fprintf( 'Process_all_median_time, ti %d/%d\n', ti, obj.pf.frame_count )
                        
                        %                         ti_arr_s =  ti - ceil (median_time__dynamic__window_size/2);
                        %                         ti_arr_e =  ti + floor(median_time__dynamic__window_size/2);
                        %                         ti_arr_s = max(ti_arr_s,1);
                        %                         ti_arr_e = min(ti_arr_e,obj.pf.frame_count);
                        %                         ti_arr = ti_arr_s : ti_arr_e;
                        [xd_median, yd_median] = Analyzer.Get_median_field(obj.data, [], [ ti median_time__dynamic__window_size] );

                        
                        fi_output = obj.data.Get(ti);
                        if isempty(fi_output), continue; end
                        xd = fi_output.xdispl;
                        yd = fi_output.ydispl;
                        
                        bp = ...
                            abs(xd_median - xd) > median_time__max_d_difference |...
                            abs(yd_median - yd) > median_time__max_d_difference;
                        
                        fi_output.status(bp) = 7;          % фильтрация по отличию от медианной фильтрации по времени
                        fi_output.xdispl(bp) = nan;
                        fi_output.ydispl(bp) = nan;
                        
                        obj.data.Set(ti, fi_output);
                    end
                end
            end
        end
        %%
        
        function Process_all__interpolate_time(obj)
            % интерполяция по времени на основе всех не нан смещений
            interp_time__on             = obj.p.interp_time__on;
            interp_time__Method         = obj.p.interp_time__Method;
            interp_time__max_gap_length = obj.p.interp_time__max_gap_length;
            if interp_time__on
                % TODO жрет много памяти, вычислять отдельно по
                % сегментам
                [fi_output_all, data_is_empty_arr] = obj.data.Get_all_as_cell();
                gp_t = ~data_is_empty_arr; %номера полей, для которые поля посчитаны
                xd_mat3 = cellfun(@(x) x.xdispl, fi_output_all(gp_t),'uni',false); % склеиваем только подсчитанные поля
                yd_mat3 = cellfun(@(x) x.ydispl, fi_output_all(gp_t),'uni',false);
                xd_mat3 = cat(3,xd_mat3{:});
                yd_mat3 = cat(3,yd_mat3{:});
                bp_mat3 = isnan(xd_mat3) | isnan(yd_mat3);
                
                t = obj.pf.first_frames(gp_t); % на случай неэквидистанстный фреймов или недосчитанных данных
                
                for i = 1:size(xd_mat3,1) %todo parfor
                    for j = 1:size(xd_mat3,2)
                        fprintf( 'Process_all__interpolate_time, i %d/%d, j %d/%d\n', i, size(xd_mat3,1), j, size(xd_mat3,2) )
                        
                        xd_ts = squeeze(xd_mat3(i,j,:));
                        yd_ts = squeeze(yd_mat3(i,j,:));
                        bp    = squeeze(bp_mat3(i,j,:));
                        gp = ~bp;
                        if ~any(bp(:)), continue; end % ничего не надо интерполировать
                        if sum(gp(:)) < 3, continue; end % не с чего интерполировать
                        xd_ts(bp) = interp1gap(t(gp), xd_ts(gp), t(bp), interp_time__max_gap_length, interp_time__Method);
                        yd_ts(bp) = interp1gap(t(gp), yd_ts(gp), t(bp), interp_time__max_gap_length, interp_time__Method);
                        
                        %                             xd_ts(bp) = interp1(t(gp), xd_ts(gp), t(bp), interp_time__Method, 'extrap');
                        %                             yd_ts(bp) = interp1(t(gp), yd_ts(gp), t(bp), interp_time__Method, 'extrap');
                        
                        xd_mat3(i,j,:) = reshape( xd_ts, [ 1 1 numel(xd_ts) ] );
                        yd_mat3(i,j,:) = reshape( yd_ts, [ 1 1 numel(yd_ts) ] );
                    end
                end
                
                ti_arr = find(gp_t);
                for ti_arr_i = 1:numel(ti_arr)% только для подсчитанных полей
                    ti = ti_arr(ti_arr_i);
                    fi_output = obj.data.Get(ti);
                    if isempty(fi_output), continue; end
                    fi_output.xdispl = xd_mat3(:,:,ti_arr_i);
                    fi_output.ydispl = yd_mat3(:,:,ti_arr_i);
                    
                    % точки, которые были интерполированы:
                    interp_points = bp_mat3(:,:,ti_arr_i)  & ~isnan(fi_output.xdispl) & ~isnan(fi_output.ydispl);
                    
                    fi_output.status(interp_points) = 10; % точки, вычисленные в результате интерполяции по времени
                    obj.data.Set( ti, fi_output );
                end
            end
        end
        
        function Process_one__interpolate_space(obj, ti)
            % интерполяция по пространству на основе всех не нан смещений
            interp_space__on                    = obj.p.interp_space__on;
            interp_space__Method                = obj.p.interp_space__Method;
            interp_space__ExtrapolationMethod   = obj.p.interp_space__ExtrapolationMethod;
            if interp_space__on
                fi_output = obj.data.Get(ti);
                if isempty(fi_output), return; end
                xdispl = fi_output.xdispl;
                ydispl = fi_output.ydispl;
                
                gp = ~isnan(xdispl) & ~isnan(ydispl);
                %                 if sum(gp(:))  > 2
                bp = ~gp;
                if ~any(bp(:)), return; end % ничего не надо интерполировать
                if ~any(gp(:)), return; end % не с чего интерполировать
                SI_xdispl = scatteredInterpolant( obj.pg.xMat(gp), obj.pg.yMat(gp), fi_output.xdispl(gp));
                SI_ydispl = scatteredInterpolant( obj.pg.xMat(gp), obj.pg.yMat(gp), fi_output.ydispl(gp));
                SI_xdispl.Method = interp_space__Method;
                SI_ydispl.Method = interp_space__Method;
                SI_xdispl.ExtrapolationMethod = interp_space__ExtrapolationMethod;
                SI_ydispl.ExtrapolationMethod = interp_space__ExtrapolationMethod;
                xdispl_q = SI_xdispl( obj.pg.xMat(bp), obj.pg.yMat(bp) );
                ydispl_q = SI_ydispl( obj.pg.xMat(bp), obj.pg.yMat(bp) );
                if isempty(xdispl_q) || isempty(ydispl_q)
                    warning('Process_one__interpolate_space: Интерполяция не удалась')
                    return;
                end
                xdispl(bp) = xdispl_q;
                ydispl(bp) = ydispl_q;
                
                % точки, которые были интерполированы:
                interp_points = bp  & ~isnan(xdispl) & ~isnan(ydispl);
                fi_output.status(interp_points) = 11;  % точки, вычисленные в результате интерполяции по пространству
                fi_output.xdispl = xdispl;
                fi_output.ydispl = ydispl;
                obj.data.Set(ti, fi_output);
            end
        end
        %%
        function info = GetInfo(obj)
            % TODO жрет много памяти, вычислять отдельно по
            % сегментам
            [fi_output_all, data_is_empty_arr] = obj.data.Get_all_as_cell();
            status = cellfun(@(x) x.status, fi_output_all(~data_is_empty_arr),'uni',false);
            status = cat(3,status{:});
            
            a = status(:);
            info.status_list = unique(a);
            info.status_histc = histc(a, info.status_list);
            
        end
    end
end

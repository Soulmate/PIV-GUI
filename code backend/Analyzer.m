classdef Analyzer < handle
    %UNTITLED9 Summary of this class goes here
    %   Detailed explanation goes here
    properties (Access = private)
        ap      Analyzer_params
        rp      Record_params
        pp      PIV_params
        pg      PIV_grid
        pf      PIV_frames
        
        fi_processor__data Array_temp_storage
        
        
    end
    properties  (SetAccess = protected, GetAccess = public)
        mean_field_xd
        mean_field_yd
    end
    methods
        function obj = Analyzer( ap, rp, pp, pf, pg, fi_processor__data)
            obj.ap = ap;
            obj.rp = rp;
            obj.pp = pp;
            obj.pf = pf;
            obj.pg = pg;
            obj.fi_processor__data = fi_processor__data;
        end
        function [ts, pos_ij_arr] = Get_time_series(obj, data, pos_ij_arr)
            %Get_time_series Summary of this method goes here
            %   Detailed explanation goes here
            %   pos_ij_arr - индексы на сетке в 2 колонки, если пустое - то
            %   для всех точек
            %  [10 12
            %   15 46
            %   13 14]
            % ts - 3д матрица, склеенные по третей размерности
            % трехколоночные матрица (время, xd, yd)
            
            %             if pos_i > size(pg.xMat,1) || pos_j > size(pg.xMat,2), return; end
            if isempty(pos_ij_arr) %выбираем все
                [pos_i, pos_j] = meshgrid( 1:size(obj.pg.xMat,1), 1:size(obj.pg.xMat,2) );
                pos_ij_arr = [ pos_i(:), pos_j(:) ];
            end
            
            ts = nan( obj.pf.frame_count, 4, size(pos_ij_arr,1) );
            
            for ti = 1:obj.pf.frame_count
                t = ( obj.pf.first_frames(ti) - 1 ) / obj.rp.fps;
                d = data.Get(ti);
                if isempty(d), continue; end
                for pos_ij_arr_i = 1:size(pos_ij_arr,1)
                    pos_i = pos_ij_arr(pos_ij_arr_i,1);
                    pos_j = pos_ij_arr(pos_ij_arr_i,2);
                    
                    xd = d.xdispl(pos_i,pos_j);
                    yd = d.ydispl(pos_i,pos_j);
                    
                    ts(ti, 1, pos_ij_arr_i) = ti;
                    ts(ti, 2, pos_ij_arr_i) = t;
                    ts(ti, 3, pos_ij_arr_i) = xd;
                    ts(ti, 4, pos_ij_arr_i) = yd;
                end
            end
            
            %сглаживание
            if round(obj.ap.ts_smoothing_window_size) > 1
                for pos_ij_arr_i = 1:size(pos_ij_arr,1)
                    ts(:,3,pos_ij_arr_i) = nanfastsmooth( ts(:,3,pos_ij_arr_i), round(obj.ap.ts_smoothing_window_size) );
                    ts(:,4,pos_ij_arr_i) = nanfastsmooth( ts(:,4,pos_ij_arr_i), round(obj.ap.ts_smoothing_window_size) );
                end
            end
        end
        function [ xd, yd ] = Calc_mean_field(obj)
            [xd, yd] = Analyzer.Get_mean_field( obj.fi_processor__data );
            obj.mean_field_xd = xd;
            obj.mean_field_yd = yd;
        end
    end
    methods(Static)
        function [xd, yd] = Get_mean_field( data, ti_arr, ti_center_window )
            % ti_arr - индексы по которым считать
            % ti_center_window - центр и размер окна индексов
            % если не указать, то считает по всем (TODO жрет много памяти)
            % xd, yd - 2д матрицs, смещений
            if exist('ti_arr','var') && ~isempty(ti_arr)
                [fi_output_arr, data_is_empty_arr] = data.Get_as_cell(ti_arr);
            elseif exist('ti_center_window','var') && ~isempty(ti_center_window)
                ti_center = ti_center_window(1);
                ti_window = ti_center_window(2);
                ti_arr_s =  ti_center - ceil (ti_window/2);
                ti_arr_e =  ti_center + floor(ti_window/2);
                ti_arr_s = max(ti_arr_s,1);
                ti_arr_e = min(ti_arr_e, data.data_size);
                ti_arr = ti_arr_s : ti_arr_e;
                [fi_output_arr, data_is_empty_arr] = data.Get_as_cell(ti_arr);
            else
                [fi_output_arr, data_is_empty_arr] = data.Get_all_as_cell();
            end
            xd_mat3 = cellfun(@(x) x.xdispl, fi_output_arr(~data_is_empty_arr),'uni',false);
            yd_mat3 = cellfun(@(x) x.ydispl, fi_output_arr(~data_is_empty_arr),'uni',false);
            xd_mat3 = cat(3,xd_mat3{:});
            yd_mat3 = cat(3,yd_mat3{:});
            xd = mean(xd_mat3,3,'omitnan');
            yd = mean(yd_mat3,3,'omitnan');
        end
        function [xd, yd] = Get_median_field( data, ti_arr, ti_center_window )
            % ti_arr - индексы по которым считать
            % ti_center_window - центр и размер окна индексов
            % если не указать, то считает по всем (TODO жрет много памяти)
            % xd, yd - 2д матрицs, смещений
            if exist('ti_arr','var') && ~isempty(ti_arr)
                [fi_output_arr, data_is_empty_arr] = data.Get_as_cell(ti_arr);
            elseif exist('ti_center_window','var') && ~isempty(ti_center_window)
                ti_center = ti_center_window(1);
                ti_window = ti_center_window(2);
                ti_arr_s =  ti_center - ceil (ti_window/2);
                ti_arr_e =  ti_center + floor(ti_window/2);
                ti_arr_s = max(ti_arr_s,1);
                ti_arr_e = min(ti_arr_e, data.data_size);
                ti_arr = ti_arr_s : ti_arr_e;
                [fi_output_arr, data_is_empty_arr] = data.Get_as_cell(ti_arr);
            else
                [fi_output_arr, data_is_empty_arr] = data.Get_all_as_cell();
            end
            xd_mat3 = cellfun(@(x) x.xdispl, fi_output_arr(~data_is_empty_arr),'uni',false);
            yd_mat3 = cellfun(@(x) x.ydispl, fi_output_arr(~data_is_empty_arr),'uni',false);
            xd_mat3 = cat(3,xd_mat3{:});
            yd_mat3 = cat(3,yd_mat3{:});
            xd = median(xd_mat3,3,'omitnan');
            yd = median(yd_mat3,3,'omitnan');
        end
    end
end


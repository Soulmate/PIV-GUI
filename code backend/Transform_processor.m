classdef Transform_processor < handle
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    %     все конвертирует в секунды, метры и м/с
    
    properties
        rp Record_params
        pg PIV_grid
        pf PIV_frames
        
        xMat % преобразованные координаты
        yMat
        time % преобразованное врем€
    end
    
    methods
        function obj = Transform_processor(rp, pg, pf )
            obj.rp = rp;
            obj.pg = pg;
            obj.pf = pf;
            
            obj.xMat = obj.Convert_x( obj.pg.xMat );
            obj.yMat = obj.Convert_y( obj.pg.yMat );
            obj.time = obj.Convert_t( obj.pf.first_frames );
        end
        
        %%
        %         ¬ эти функции можно передавать матрицы любого размера
        function u_mps = Convert_xdispl(obj, xdispl_px)                    
            u_mps = xdispl_px * obj.rp.fps * obj.rp.scale * 1e-6;
        end
        function v_mps = Convert_ydispl(obj, ydispl_px)                    
            v_mps = ydispl_px * obj.rp.fps * obj.rp.scale * 1e-6;
        end
        function x_m = Convert_x(obj, x_px)            
            x_m = ( x_px - obj.rp.zero_pos_px(1) ) * obj.rp.scale * 1e-6;
        end
        function y_m = Convert_y(obj, y_px)            
            y_m = ( y_px - obj.rp.zero_pos_px(2) ) * obj.rp.scale * 1e-6;
        end
        function time_sec = Convert_t(obj, frame_number)
            time_sec = (frame_number - 1) / obj.rp.fps;
        end
                
        function x_px = Convert_x_to_px(obj, x_m)
             x_px = x_m / obj.rp.scale * 1e6  + obj.rp.zero_pos_px(1);
        end
        function y_px = Convert_y_to_px(obj, y_m)
             y_px = y_m / obj.rp.scale * 1e6  + obj.rp.zero_pos_px(2);
        end
    end
end


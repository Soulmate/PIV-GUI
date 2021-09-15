classdef PIV_main < handle
    %PIV_APP Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        core        Core
        piv_plot    PIV_plot
        %%
        p Project_params
        %%
        proj_path %путь к файлу проекта
        
        data_seg_size = 100;
        
        current_frame = 1;
        current_ti = nan;
        
        
        fig_fields;
        
        ax_fields;
        ax_process;
        ax_analyze;
        
        %         gui_app PIV_main_App_v5
        %%
        selected_points; %x_px, y_px, x_m, y_m
    end
    
    methods
        function obj = PIV_main()
            %PIV_APP Construct an instance of this class
            %   Detailed explanation goes here
            obj.piv_plot = PIV_plot();
            obj.p = Project_params();
            obj.proj_path = '';
        end
        function delete(obj) %при удалении объекта удалять временные данные, закрывать фигуры
            if ~isempty(obj.fig_fields) && ishandle(obj.fig_fields)
                close(obj.fig_fields);
            end
            if ~isempty(obj.core) && ~isempty(obj.core.piv_processor) && ~isempty(obj.core.piv_processor.data)
                obj.core.piv_processor.data.Clear();
                obj.core.piv_processor.ID_data.Clear();
            end
            if ~isempty(obj.core) && ~isempty(obj.core.fi_processor) && ~isempty(obj.core.fi_processor.data)
                obj.core.fi_processor.data.Clear();
            end
        end
        
        %%
        function Proj_new( obj, images_folder, images_ext, proj_path  )
            obj.Add_to_log(sprintf('Создание нового проекта...'));
            obj.proj_path = proj_path;
            
            obj.p.rp   =   Record_params();
            
            obj.p.il   =   Image_loader_params();
            obj.p.il.images_folder = images_folder;
            obj.p.il.images_ext    = images_ext;
            il = Image_loader( obj.p.il.images_folder, obj.p.il.images_ext, 10 );
            
            obj.p.ipp  =   Image_preprocessor_params();
            ipp = Image_preprocessor( il, obj.p.ipp, 10 );
            
            obj.p.pp   =   PIV_params();
            obj.p.pg   =   PIV_grid.Get_max_grid(il.imSize,obj.p.pp.wSize/2);
            obj.p.pf   =   PIV_frames(1,il.imNum,1,1);
            obj.p.fi   =   Filter_and_interpolation_params();
            obj.p.ap   =   Analyzer_params();
            obj.p.plot_params =   Plot_params();
            
            
            piv_processor = PIV_processor( obj.p.pp, obj.p.pf, obj.p.pg,...
                [ obj.proj_path ' - temp storage\piv\'], obj.data_seg_size);
            
            fi_processor = Filter_and_interpolation_processor( obj.p.fi, obj.p.pf, obj.p.pg,...
                [ obj.proj_path ' - temp storage\fi\' ],  obj.data_seg_size);
            
            transform_processor = Transform_processor( obj.p.rp, obj.p.pg, obj.p.pf );
            
            exporter = Exporter();
            
            analyzer = Analyzer( obj.p.ap, obj.p.rp, obj.p.pp, obj.p.pf, obj.p.pg, fi_processor.data  );
            
            obj.core = Core( il, ipp, piv_processor, fi_processor, transform_processor, exporter, analyzer );
            obj.Go_to_frame(1);
            obj.selected_points = [];
            obj.Add_to_log(sprintf('Создание нового проекта завершено'));
        end
        
        function Proj_save(obj, proj_path)
            obj.Add_to_log(sprintf('Сохранение проекта...'));
            if exist('proj_path','var')
                obj.proj_path = proj_path;
            end
            
            p = obj.p;
            if ~exist(fileparts(obj.proj_path),'dir'), mkdir(fileparts(obj.proj_path)); end
            save(obj.proj_path, 'p','-mat');
            
            obj.core.piv_processor.data.Export_to_file( [obj.proj_path ' data piv'] );
            obj.core.fi_processor. data.Export_to_file( [obj.proj_path ' data fi'] );
            
            obj.Add_to_log(sprintf('Сохранение проекта завершено'));
        end
        
        function Proj_load(obj, proj_path)
            obj.Add_to_log(sprintf('Загрузка проекта...'));
            obj.proj_path = proj_path;
            
            f = load(proj_path,'-mat');
            obj.p = f.p;
            
            il = Image_loader( obj.p.il.images_folder, obj.p.il.images_ext, 10 );
            ipp = Image_preprocessor( il, obj.p.ipp, 10 );
            
            piv_processor = PIV_processor( obj.p.pp, obj.p.pf, obj.p.pg,...
                [ obj.proj_path ' - temp storage\piv\' ], obj.data_seg_size);
            
            fi_processor = Filter_and_interpolation_processor( obj.p.fi, obj.p.pf, obj.p.pg,...
                [ proj_path ' - temp storage\fi\' ],  obj.data_seg_size);
            
            transform_processor = Transform_processor( obj.p.rp, obj.p.pg, obj.p.pf );
            
            exporter = Exporter();
            
            analyzer = Analyzer( obj.p.ap, obj.p.rp, obj.p.pp, obj.p.pf, obj.p.pg, fi_processor.data  );
            
            obj.core = Core( il, ipp, piv_processor, fi_processor, transform_processor, exporter, analyzer );
            
            obj.core.piv_processor.data.Import_from_file( [obj.proj_path ' data piv'] );
            obj.core.fi_processor. data.Import_from_file( [obj.proj_path ' data fi' ] );
            obj.Go_to_frame(1);
            obj.selected_points = [];
            obj.Add_to_log(sprintf('Загрузка проекта завершена'));
        end
        %%
        function Set_il_params(obj,il_params)
            if ... %если все совпадает
                    strcmp( obj.p.il.images_folder, il_params.images_folder) && ...
                    strcmp( obj.p.il.images_ext,    il_params.images_ext)
                return;
            end
            obj.p.il = il_params;
            obj.core.il = Image_loader( obj.p.il.images_folder, obj.p.il.images_ext, 10 );
            obj.core.ipp = Image_preprocessor( obj.core.il, obj.p.ipp, 10 );
            if   obj.p.pf.frame_end > obj.core.il.imNum
                pf = PIV_frames(obj.p.pf.frame_start, obj.core.il.imNum, obj.p.pf.frame_skip, obj.p.pf.frame_step);
                obj.Set_pf(pf);
            end
        end
        function Set_ipp_params( obj, ipp_params )
            if ipp_params.bg_on && isempty(ipp_params.bg)
                ipp_params.bg_on = false;
            end
            if ipp_params.mask_on && isempty(ipp_params.mask)
                ipp_params.mask_on = false;
            end
            obj.p.ipp = ipp_params;
            obj.core.ipp = Image_preprocessor( obj.core.il, obj.p.ipp, 10 );
        end
        function Set_rp_params( obj, rp )
            obj.p.rp = rp;
            obj.core.transform_processor = Transform_processor( obj.p.rp, obj.p.pg, obj.p.pf );
            obj.core.analyzer = Analyzer( obj.p.ap, obj.p.rp, obj.p.pp, obj.p.pf, obj.p.pg, obj.core.fi_processor.data  );
        end
        function Set_pp( obj, pp )
            obj.p.pp = pp;
            obj.core.piv_processor = PIV_processor( obj.p.pp, obj.p.pf, obj.p.pg,...
                [ obj.proj_path ' - temp storage\piv\' ], obj.data_seg_size );
            obj.core.fi_processor = Filter_and_interpolation_processor( obj.p.fi, obj.p.pf, obj.p.pg,...
                [ obj.proj_path ' - temp storage\fi\' ],  obj.data_seg_size);
            obj.core.analyzer = Analyzer( obj.p.ap, obj.p.rp, obj.p.pp, obj.p.pf, obj.p.pg, obj.core.fi_processor.data  );
        end
        function Set_pg( obj, p_pg )
            obj.p.pg = p_pg;
            obj.core.piv_processor = PIV_processor( obj.p.pp, obj.p.pf, obj.p.pg,...
                [ obj.proj_path ' - temp storage\piv\' ], obj.data_seg_size );
            obj.core.fi_processor = Filter_and_interpolation_processor( obj.p.fi, obj.p.pf, obj.p.pg,...
                [ obj.proj_path ' - temp storage\fi\' ],  obj.data_seg_size);
            obj.core.transform_processor = Transform_processor( obj.p.rp, obj.p.pg, obj.p.pf );
            obj.core.analyzer = Analyzer( obj.p.ap, obj.p.rp, obj.p.pp, obj.p.pf, obj.p.pg, obj.core.fi_processor.data  );
        end
        function Set_pf( obj, p_pf )            
            obj.p.pf = p_pf;
            obj.Go_to_ti(1);
            obj.core.piv_processor = PIV_processor( obj.p.pp, obj.p.pf, obj.p.pg,...
                [ obj.proj_path ' - temp storage\piv\' ], obj.data_seg_size );
            obj.core.fi_processor = Filter_and_interpolation_processor( obj.p.fi, obj.p.pf, obj.p.pg,...
                [ obj.proj_path ' - temp storage\fi\' ],  obj.data_seg_size);
            obj.core.transform_processor = Transform_processor( obj.p.rp, obj.p.pg, obj.p.pf );
            obj.core.analyzer = Analyzer( obj.p.ap, obj.p.rp, obj.p.pp, obj.p.pf, obj.p.pg, obj.core.fi_processor.data  );
        end
        function Set_fi_params( obj, fi_params )
            obj.p.fi = fi_params;
            obj.core.fi_processor = Filter_and_interpolation_processor( obj.p.fi, obj.p.pf, obj.p.pg,...
                [ obj.proj_path ' - temp storage\fi\' ],  obj.data_seg_size);
            obj.core.analyzer = Analyzer( obj.p.ap, obj.p.rp, obj.p.pp, obj.p.pf, obj.p.pg, obj.core.fi_processor.data  );
        end
        function Set_ap( obj, ap )
            obj.p.ap = ap;
            obj.core.analyzer = Analyzer( obj.p.ap, obj.p.rp, obj.p.pp, obj.p.pf, obj.p.pg, obj.core.fi_processor.data  );
        end
        function Set_plot_params( obj, plot_params )
            obj.p.plot_params = plot_params;
        end
        %TODO остальные сеты
        %%
        function Add_to_log(obj, text)
            fprintf('%s > %s\n', datestr(datetime('now'),'HH:MM:SS'), text);
        end
        %%
        function Go_to_frame(obj,frame)
            if isempty(obj.core), return; end
            obj.current_frame = max(1,min(obj.core.il.imNum,frame));
            ti = find(obj.p.pf.first_frames == obj.current_frame,1);
            if ~isempty(ti)
                obj.current_ti = ti;
            else
                obj.current_ti = nan;
            end
        end
        function Go_to_ti(obj,ti)
            if isempty(obj.core), return; end
            obj.current_ti = max(1,min(obj.p.pf.frame_count, ti));
            obj.current_frame = obj.p.pf.first_frames(obj.current_ti);
        end
        function n = ti_count(obj)
            n = 0;
            if isempty(obj.core),       return; end
            if isempty(obj.p),       return; end
            n = obj.p.pf.frame_count;
        end
        function n = im_count(obj)
            n = 0;
            if isempty(obj.core),       return; end
            if isempty(obj.core.il),       return; end
            n = obj.core.il.imNum;
        end
        function n = im_size(obj, dim)
            if ~exist('dim','var')
                n = obj.core.il.imSize;
            else
                n = obj.core.il.imSize(dim);
            end
        end
        %%
        function Process_piv_current(obj)
            if isempty(obj.core),       return; end
            if isnan(obj.current_ti),   return; end
            %             obj.Add_to_log('Вычисление...');
            %             obj.core.piv_processor.iteration_time_full_tic = tic;
            obj.core.piv_processor.Process_one( obj.core.ipp, obj.current_ti );
            obj.Add_to_log(obj.core.piv_processor.Get_info());
        end
        function Process_piv_all(obj,...
                redraw_fields_on, redraw_fields_step,...
                redraw_process_on, redraw_process_step,...
                autosave_on, autosave_step)
            if ~exist('redraw_fields_on',   'var'),  redraw_fields_on = false;  end
            if ~exist('redraw_fields_step', 'var'),  redraw_fields_step = 1;    end
            if ~exist('redraw_process_on',  'var'),  redraw_process_on = false; end
            if ~exist('redraw_process_step','var'),  redraw_process_step = 1;   end
            if ~exist('autosave_on',        'var'),  autosave_on = false;       end
            if ~exist('autosave_step',      'var'),  autosave_step = 100;       end
            obj.Process_piv_reset();
            for ti = 1:obj.p.pf.frame_count
                obj.Go_to_ti(ti);
                obj.Process_piv_current();
                if redraw_fields_on  && rem(ti, redraw_fields_step) == 0
                    obj.Redraw_fields();
                    drawnow();
                end
                if redraw_process_on && rem(ti, redraw_process_step) == 0
                    obj.Redraw_process('piv_processor');
                    drawnow();
                end
                if autosave_on && rem(ti, autosave_step) == 0
                    obj.Proj_save();
                end
            end
        end
        function Process_piv_reset(obj)
            obj.core.piv_processor.Reset_processing();
            %             obj.Redraw_fields();
            %             obj.Redraw_process('piv_processor');
            drawnow();
        end
        function is_processed_arr = Process_piv__is_processed_arr(obj)
            is_processed_arr = obj.core.piv_processor.is_processed_arr;
        end
        function info = Process_piv__Get_info_progress(obj)
            info = obj.core.piv_processor.Get_info_progress();
        end
        function info = Process_piv__Get_info(obj)
            info = obj.core.piv_processor.Get_info();
        end
        %%
        function Process_fi_all(obj)
            obj.Add_to_log('Запущена фильтрация и интерполяция');
            obj.core.fi_processor.Process_all(obj.core.piv_processor.data);
            obj.Add_to_log('Фильтрация и интерполяция завершена');
        end
        %%
        function New_fig_fields(obj)
            obj.fig_fields = figure('name','Поля','WindowButtonDownFcn',@wbdcb);
            %             ah = axes('SortMethod','childorder');
            obj.ax_fields = gca;
            
            function wbdcb(src,~)
                seltype = src.SelectionType;
                if strcmp(seltype,'normal')
                    %                 src.Pointer = 'circle';
                    cp = obj.ax_fields.CurrentPoint;
                    xinit = cp(1,1);
                    yinit = cp(1,2);
                    if ~obj.p.plot_params.plot_in_scale
                        x_px = xinit;
                        y_px = yinit;
                        x_m = obj.core.transform_processor.Convert_x(xinit);
                        y_m = obj.core.transform_processor.Convert_y(yinit);
                    else
                        x_px = obj.core.transform_processor.Convert_x_to_px(xinit);
                        y_px = obj.core.transform_processor.Convert_y_to_px(yinit);
                        x_m = xinit;
                        y_m = yinit;
                    end
                    text_m  = sprintf('%f, %f m',   x_m, y_m );
                    text_px = sprintf('%.0f, %.0f px', x_px, y_px);
                    obj.Add_to_log(sprintf('(%s) (%s)', text_m, text_px));
                    obj.selected_points = [ obj.selected_points; x_px, y_px, x_m, y_m ];
                    obj.Redraw_fields();
                end
                if strcmp(seltype,'alt')
                    cp = obj.ax_fields.CurrentPoint;
                    xinit = cp(1,1);
                    yinit = cp(1,2);
                    if ~obj.p.plot_params.plot_in_scale
                        x_px = xinit;
                        y_px = yinit;
                        x_m = obj.core.transform_processor.Convert_x(xinit);
                        y_m = obj.core.transform_processor.Convert_y(yinit);
                    else
                        x_px = obj.core.transform_processor.Convert_x_to_px(xinit);
                        y_px = obj.core.transform_processor.Convert_y_to_px(yinit);
                        x_m = xinit;
                        y_m = yinit;
                    end
                    selected_points__dsitance = sqrt( (obj.selected_points(:,1) - x_px) .^2 + (obj.selected_points(:,2) - y_px) .^2 );
                    selected_points__to_delete  = selected_points__dsitance < 10;
                    obj.selected_points(selected_points__to_delete,:) = [];
                    obj.Add_to_log(sprintf('Удалено точек: (%d)', selected_points__to_delete));
                    obj.Redraw_fields();
                end
                if strcmp(seltype,'extend')
                    obj.selected_points = [ ];
                    obj.Redraw_fields();
                end
            end
        end
        %%
        function Redraw_fields(obj)
            if isempty(obj.core),     return; end
            if isempty(obj.fig_fields) || ~ishandle(obj.fig_fields)
                obj.New_fig_fields();
            end
            if isempty(obj.ax_fields),       return; end
            if ~ishandle(obj.ax_fields),       return; end
            if isempty(obj.p.plot_params),   return; end
            
            ax = obj.ax_fields;
            cla(ax,'reset');
            reset(ax);
            
            % пределы построения (края изображения)
            XData = [1 obj.im_size(1)];
            YData = [1 obj.im_size(2)];
            if obj.p.plot_params.plot_in_scale
                XData = obj.core.transform_processor.Convert_x(XData);
                YData = obj.core.transform_processor.Convert_y(YData);
            end
            
            x = obj.p.pg.xMat;
            y = obj.p.pg.yMat;
            frame   = obj.current_frame;
            ti      = obj.current_ti;
            time    = obj.core.transform_processor.Convert_t(frame);
            if obj.p.plot_params.plot_in_scale
                x           = obj.core.transform_processor.Convert_x(x);
                y           = obj.core.transform_processor.Convert_y(y);
            end
            
            if obj.p.plot_params.image_on
                if ~obj.p.plot_params.image_processed
                    im = obj.core.il.getImage(obj.current_frame);
                    imshow(im,'Parent',ax,'XData', XData,'YData', YData); hold(ax, 'on');
                else
                    im = obj.core.ipp.getImage(obj.current_frame);
                    imagesc(XData,YData,im,'Parent',ax); hold(ax, 'on');
                    colormap(ax, obj.p.plot_params.image_colormap);
                end
            end
            
            obj.piv_plot.ax = ax;
            obj.piv_plot.plot_params = obj.p.plot_params;
            
            if isnan(obj.current_ti)
                text(ax, 0, 0,'Кадр не выбран для вычислений','color','r','VerticalAlignment','bottom','units','normalized');
            else
                if obj.p.plot_params.grid_on
                    gp = obj.p.pg.do_PIV_mat;
                    obj.piv_plot.plot_centers(x,y,gp); hold(ax, 'on');
                end
                if obj.p.plot_params.grid_show_windows
                    wSize = obj.p.pp.wSize;
                    if obj.p.plot_params.plot_in_scale
                        wSize =     wSize * obj.p.rp.scale * 1e-6;
                    end
                    obj.piv_plot.plot_windows(x,y,wSize); hold(ax, 'on');                     %TODO какой из wSize? TODO работает только для простого масштаба
                end
                
                
                
                piv_output = obj.core.piv_processor.data.Get(obj.current_ti);
                fi_output  = obj.core.fi_processor. data.Get(obj.current_ti);
                if isempty(piv_output)
                    text(ax, 0,0,'Нет данных PIV',       'color','r','VerticalAlignment','bottom','units','normalized');
                else
                    u_piv = piv_output.xdispl;
                    v_piv = piv_output.ydispl;
                    gp_piv = piv_output.status == 0;
                    u_piv(~gp_piv) = nan;
                    v_piv(~gp_piv) = nan;
                    if obj.p.plot_params.plot_in_scale
                        u_piv = obj.core.transform_processor.Convert_xdispl(u_piv);
                        v_piv = obj.core.transform_processor.Convert_ydispl(v_piv);
                    end
                    if obj.p.plot_params.grid_show_status
                        obj.piv_plot.plot_status( x, y, piv_output.status, 'right'); hold(ax, 'on');
                    end
                end
                if isempty(fi_output)
                    text(ax, 0,0,'Нет данных фильтрации','color','r','VerticalAlignment','bottom','units','normalized');
                else
                    u_fi = fi_output.xdispl;
                    v_fi = fi_output.ydispl;
                    gp_fi = ~isnan(u_fi) & ~isnan(v_fi);
                    if obj.p.plot_params.plot_in_scale
                        u_fi = obj.core.transform_processor.Convert_xdispl(u_fi);
                        v_fi = obj.core.transform_processor.Convert_ydispl(v_fi);
                    end
                    if obj.p.plot_params.grid_show_status_filtering
                        obj.piv_plot.plot_status( x, y, fi_output.status, 'left'); hold(ax, 'on');
                    end
                end
                if ~isempty( obj.core.analyzer.mean_field_xd ) && ~isempty( obj.core.analyzer.mean_field_yd )
                    u_mean = obj.core.analyzer.mean_field_xd;
                    v_mean = obj.core.analyzer.mean_field_yd;
                    gp_mean = ~isnan(u_mean) & ~isnan(v_mean);
                    if obj.p.plot_params.plot_in_scale
                        u_mean = obj.core.transform_processor.Convert_xdispl(u_mean);
                        v_mean = obj.core.transform_processor.Convert_ydispl(v_mean);
                    end
                end
                
                if obj.p.plot_params.pcolor_on
                    eqvidistant = ~isnan(obj.p.pg.xStep) && ~isnan(obj.p.pg.yStep);
                    if strcmp( obj.p.plot_params.pcolor_source, 'piv' ) && ~isempty(piv_output)
                        u = u_piv;
                        v = v_piv;
                        gp = gp_piv;
                        obj.piv_plot.plot_pcolor( x, y, u, v, gp, eqvidistant ); hold(ax, 'on');
                    end
                    if strcmp( obj.p.plot_params.pcolor_source, 'fi' ) && ~isempty(fi_output)
                        u = u_fi;
                        v = v_fi;
                        gp = gp_fi;
                        obj.piv_plot.plot_pcolor( x, y, u, v, gp, eqvidistant ); hold(ax, 'on');
                    end
                    if strcmp( obj.p.plot_params.pcolor_source, 'mean' ) &&...
                            ~isempty( obj.core.analyzer.mean_field_xd ) && ~isempty( obj.core.analyzer.mean_field_yd )
                        u = u_mean;
                        v = v_mean;
                        gp = gp_mean;
                        obj.piv_plot.plot_pcolor( x, y, u, v, gp, eqvidistant ); hold(ax, 'on');
                    end
                end
                
                
                if obj.p.plot_params.quiver_on_ID
                    ID_data = obj.core.piv_processor.ID_data.Get(ti);
                    if ~isempty(ID_data)
                        u = ID_data.xIDArr;
                        v = ID_data.yIDArr;
                        if obj.p.plot_params.plot_in_scale
                            u = obj.core.transform_processor.Convert_xdispl(u);
                            v = obj.core.transform_processor.Convert_ydispl(v);
                        end
                        gp = ~isnan(u);
                        obj.piv_plot.plot_quiver( x, y, u, v, gp, obj.p.plot_params.quiver_color_ID ); hold(ax, 'on');
                    end
                end
                
                if obj.p.plot_params.quiver_on_mean && ~isempty( obj.core.analyzer.mean_field_xd ) && ~isempty( obj.core.analyzer.mean_field_yd )
                    u = u_mean;
                    v = v_mean;
                    gp = gp_mean;
                    obj.piv_plot.plot_quiver( x, y, u, v, gp, obj.p.plot_params.quiver_color_mean ); hold(ax, 'on');
                end
                
                if obj.p.plot_params.quiver_on_piv && ~isempty(piv_output)
                    u = u_piv;
                    v = v_piv;
                    gp = gp_piv;
                    obj.piv_plot.plot_quiver( x, y, u, v, gp, obj.p.plot_params.quiver_color_piv ); hold(ax, 'on');
                end
                
                if obj.p.plot_params.quiver_on_fi && ~isempty(fi_output)
                    u = u_fi;
                    v = v_fi;
                    gp = gp_fi;
                    obj.piv_plot.plot_quiver( x, y, u, v, gp, obj.p.plot_params.quiver_color_fi ); hold(ax, 'on');
                end
                
                
                
                %выбранные точки
                for selected_points_i = 1:size(obj.selected_points,1)
                    xinit = obj.selected_points(selected_points_i,1); % в px
                    yinit = obj.selected_points(selected_points_i,2);
                    if obj.p.plot_params.plot_in_scale
                        xinit = obj.core.transform_processor.Convert_x(xinit);
                        yinit = obj.core.transform_processor.Convert_y(yinit);
                    end
                    
                    line(obj.ax_fields, 'XData',xinit,'YData',yinit,...
                        'Marker','+','color','w','markersize',20);
                    text(obj.ax_fields, xinit, yinit,...
                        num2str(selected_points_i),...
                        'color','w','VerticalAlignment','bottom','units','data','fontsize',14);
                end
            end
            
            axis(ax, 'equal');
            ax.YDir = 'Reverse';
            ax.XLim = XData;
            ax.YLim = YData;
            if obj.p.plot_params.show_grid
                grid(ax, 'on');
            end
            if obj.p.plot_params.show_ticks
                if obj.p.plot_params.plot_in_scale
                    xlabel(ax, 'x, м');
                    ylabel(ax, 'y, м');
                else
                    xlabel(ax, 'x, px');
                    ylabel(ax, 'y, px');
                end
            else
                ax.XTick = [];
                ax.YTick = [];
                set(ax,'LooseInset',get(ax,'TightInset'))
            end
            if obj.p.plot_params.show_title
                title( ax, sprintf('Кадр %d, поле %d, время %.4f', frame, ti, time ) );
            end
        end
        %%
        function Redraw_process(obj, processor_name)
            if isempty(obj.core),     return; end
            if isempty(obj.ax_process),     return; end
            if ~ishandle(obj.ax_process),       return; end
            if isempty(obj.core.piv_processor),     return; end
            
            switch processor_name
                case 'piv_processor'
                    processor = obj.core.piv_processor;
                case 'fi_processor'
                    processor = obj.core.fi_processor;
                otherwise
                    return
            end
            ax = obj.ax_process;
            cla(ax);
            reset(ax);
            frame_count = obj.p.pf.frame_count;
            
            plot( ax, processor.iteration_time_arr, '.-');
            hold( ax, 'on');
            plot( ax, processor.iteration_time_full_arr, '.-r');
            ti = processor.current_ti;
            ax.YLim = [0 ax.YLim(2)];
            if ~isnan(ti)
                ylims = ax.YLim;
                plot( ax, [ti ti], ylims);
            end
            
            ti_arr = 1 : frame_count;
            ti_arr_pr = ax.YLim(2) * processor.is_processed_arr;
            plot( ax, ti_arr, ti_arr_pr,'.g');
            xlabel( ax, 'Номер поля');
            ylabel( ax, 'Время на вычисление (с)');
            ax.XLim = [1 frame_count];
        end
        %%
        function Plot_hist_ti(obj)
            if isempty(obj.core),     return; end            
            if isempty(obj.p.plot_params),   return; end
           
            clf
            ax = gca;
            
            frame   = obj.current_frame;
            ti      = obj.current_ti;
            time    = obj.core.transform_processor.Convert_t(frame);
                
            if isnan(obj.current_ti)
                text(ax, 0, 0,'Кадр не выбран для вычислений','color','r','VerticalAlignment','bottom','units','normalized');
            else                
                piv_output = obj.core.piv_processor.data.Get(obj.current_ti);
                ID = obj.core.piv_processor.ID_data.Get(obj.current_ti);
                fi_output  = obj.core.fi_processor. data.Get(obj.current_ti);
                if isempty(piv_output)
                    text(ax, 0,0,'Нет данных PIV',       'color','r','VerticalAlignment','bottom','units','normalized');
                else
                    u = piv_output.xdispl;
                    v = piv_output.ydispl;
                    cc = piv_output.CC_maxRaitio;
                    gp = piv_output.status == 0;                    
                    [u_counts,u_centers] = hist(u(gp));
                    [v_counts,v_centers] = hist(v(gp));
                    [cc_counts,cc_centers] = hist(cc(gp & cc < 2));
                    subplot(311);
                    plot(u_centers, u_counts); hold on;
                    plot(v_centers, v_counts); 
                    subplot(313);
                    plot(cc_centers, cc_counts); hold on;
                end
                if isempty(fi_output)
                    text(ax, 0,0,'Нет данных фильтрации','color','r','VerticalAlignment','bottom','units','normalized');
                else
                    u = fi_output.xdispl;
                    v = fi_output.ydispl;
                    gp = ~isnan(u) & ~isnan(v);                  
                    [u_counts,u_centers] = hist(u(gp));
                    [v_counts,v_centers] = hist(v(gp));
                    subplot(312);
                    plot(u_centers, u_counts); hold on;
                    plot(v_centers, v_counts); 
                end
                if isempty(ID)
                    text(ax, 0,0,'Нет данных предсмещений','color','r','VerticalAlignment','bottom','units','normalized');
                else
                    u = piv_output.xdispl;
                    v = piv_output.ydispl;
                    gp = piv_output.status == 0;
                    u_id = ID.xIDArr;
                    v_id = ID.yIDArr;
                    u  = u - u_id;
                    v  = v - v_id;                
                    [u_counts,u_centers] = hist(u(gp));
                    [v_counts,v_centers] = hist(v(gp));
                    subplot(312);
                    plot(u_centers, u_counts); hold on;
                    plot(v_centers, v_counts); 
                end
           
                xlabel(ax, 'x, м');
                ylabel(ax, 'y, м');
            end
        end
        %% Предобработка изображений
        function Calc_and_use_bg(obj, bg_source_auto_N, bg_source_auto_prctile) %вычисляет и устанавливает фон
            if isempty(obj.core),          return; end
            if isempty(obj.core.il),       return; end
            if exist('bg_source_auto_N','var')
                obj.p.ipp.bg_source_auto_N = bg_source_auto_N;
            end
            if exist('bg_source_auto_prctile','var')
                obj.p.ipp.bg_source_auto_prctile = bg_source_auto_prctile;
            end
            disp('Вычисление фона...');
            obj.p.ipp.bg = CalcBgMedian_v2019_10(obj.core.il, obj.p.ipp.bg_source_auto_N, obj.p.ipp.bg_source_auto_prctile, obj.p.ipp.color_channel);
            disp('вычисление фона завершено');
            obj.p.ipp.bg_on = true;
            obj.Set_ipp_params( obj.p.ipp );
        end
        function Load_and_use_bg(obj, file_path)
            if isempty(obj.core),          return; end
            if isempty(obj.core.il),       return; end
            if exist('file_path','var')
                obj.p.ipp.bg_source_file_path = file_path;
            end
            if ~exist(obj.p.ipp.bg_source_file_path,'file')
                obj.Add_to_log('Файл не найден');
                return;
            end
            im = imread(obj.p.ipp.bg_source_file_path);
            if size(im,2) ~= obj.core.il.imSize(1) ||  size(im,1) ~= obj.core.il.imSize(2)
                obj.Add_to_log('Размер изображения фона должен совпадать с размером изображений. Фон не вычитается');
                return;
            end
            bg = im(:,:,obj.p.ipp.color_channel);
            p_ipp = obj.p.ipp;
            p_ipp.bg = bg;
            p_ipp.bg_on = true;
            obj.Set_ipp_params( p_ipp );
        end
        function Load_and_use_mask(obj, file_path, mask_source_color)
            if isempty(obj.core),          return; end
            if isempty(obj.core.il),       return; end
            if ~exist('file_path','var')
                obj.Add_to_log('Файл не найден');
                return;
            end
            im = imread(file_path);
            if size(im,2) ~= obj.im_size(1) ||  size(im,1) ~= obj.im_size(2)
                obj.Add_to_log('Размер изображения маски должен совпадать с размером изображений. Маска не используется');
                return;
            end
            obj.p.ipp.mask_source_path = file_path;
            if exist('mask_source_color','var')
                obj.p.ipp.mask_source_color = mask_source_color;
            end
            mask = ...
                im(:,:,1) == obj.p.ipp.mask_source_color(1) &...
                im(:,:,2) == obj.p.ipp.mask_source_color(2) &...
                im(:,:,3) == obj.p.ipp.mask_source_color(3);
            obj.p.ipp.mask = mask;
            obj.p.ipp.mask_on = true;
            obj.Set_ipp_params( obj.p.ipp );
        end
        
        
        
        
        
        %% Экспорт
        function Export_all_fields_to_one_file( obj, file_path )
%             Сохранение всех полей скорости в один файл
            obj.Add_to_log(sprintf('Сохранение в %s', file_path));
            obj.core.exporter.Export_all_fields_to_one_file(...
                file_path, obj.core.fi_processor.data, obj.core.transform_processor );
            obj.Add_to_log(sprintf('Сохранение завершено'));
        end
        function Export_all_fields_to_separate_files( obj, file_path_base )
%             Сохранение всех полей скорости в набор файлов
            obj.Add_to_log(sprintf('Сохранение в %s', file_path_base));
            obj.core.exporter.Export_all_fields_to_separate_files(...
                file_path_base, obj.core.fi_processor.data, obj.core.transform_processor);
            obj.Add_to_log(sprintf('Сохранение завершено'));
        end
        function Export_time_series( obj, file_path_base, pos_ij_arr )
%             Сохранение временных зависимостей в набор файлов
            obj.Add_to_log(sprintf('Сохранение в %s', file_path_base));
            [ts, pos_ij_arr] = obj.Get_time_series( pos_ij_arr );
            obj.core.exporter.Export_time_series_to_separate_files( file_path_base, ts, obj.core.transform_processor, pos_ij_arr );
            obj.Add_to_log(sprintf('Сохранение завершено'));
        end
        function Export_mean_field_to_files( obj, file_path, profile_y__pos_i, profile_x__pos_j )
%             Сохранение среднего поля в файл
            % profile_x__pos_j - набор номеров координат по y для профилей вдоль x
            % profile_x__pos_j - набор номеров координат по x для профилей вдоль y
            obj.Add_to_log(sprintf('Сохранение в %s', file_path));
            [xd, yd] = obj.Update_mean_field();
            x = obj.p.pg.xMat;
            y = obj.p.pg.yMat;
            x           = obj.core.transform_processor.Convert_x(x);
            y           = obj.core.transform_processor.Convert_y(y);
            xd          = obj.core.transform_processor.Convert_xdispl(xd);
            yd          = obj.core.transform_processor.Convert_ydispl(yd);
            file_path_mean = strrep( file_path, '~info~', ' среднее поле' );
            obj.core.exporter.Export_one_field_to_file( file_path_mean, x, y, xd, yd)
            for profile_x__pos_j__i = 1:numel(profile_x__pos_j)
                pos_j = profile_y__pos_i(profile_x__pos_j__i);
                x_profile = obj.p.pg.xMat(:,pos_j);
                xd_profile = xd(:,pos_j);
                yd_profile = yd(:,pos_j);
                y           = obj.core.transform_processor.Convert_y(y);
                x_profile   = obj.core.transform_processor.Convert_x(x_profile);
                file_path_profile = strrep( file_path, '~info~', sprintf(' профиль по x, pos_j %d, y %.5f', pos_j, y) );
                obj.core.exporter.Export_profile_to_file( file_path_profile, x_profile, xd_profile, yd_profile );
            end
            for profile_y__pos_i__i = 1:numel(profile_y__pos_i)
                pos_i = profile_y__pos_i(profile_y__pos_i__i);
                x = unique(obj.p.pg.xMat(pos_i,:));
                y_profile = obj.p.pg.yMat(pos_i,:);
                xd_profile = xd(pos_i,:);
                yd_profile = yd(pos_i,:);
                x           = obj.core.transform_processor.Convert_x(x);
                y_profile   = obj.core.transform_processor.Convert_y(y_profile);
                file_path_profile = strrep( file_path, '~info~', sprintf(' профиль по y, pos_i %d, x %.5f', pos_i, x) );
                obj.core.exporter.Export_profile_to_file( file_path_profile, y_profile, xd_profile, yd_profile );
            end
            obj.Add_to_log(sprintf('Сохранение завершено'));
        end
        function Export_figure_current(obj, file_path)
            if ~exist(fileparts(file_path),'dir'), mkdir(fileparts(file_path)); end
            obj.Redraw_fields();
            saveas(obj.fig_fields, file_path);
        end
        function Export_figure_all(obj, file_path_base, ti_arr)
            % Сохранение изображений с полями скорости в набор файлов
            if ~exist(fileparts(file_path_base),'dir'), mkdir(fileparts(file_path_base)); end
            if ~exist('ti_arr','var'), ti_arr = 1:obj.ti_count; end
            for i = 1:numel(ti_arr)
                ti = ti_arr(i);
                obj.Go_to_ti(ti);
                obj.Redraw_fields();
                drawnow();
                file_path = strrep( file_path_base, '~info~', sprintf(' %08d',ti) );
                saveas( obj.fig_fields, file_path );
                obj.Add_to_log(sprintf('Сохранен  кадр %d в %s', ti, file_path));
            end
        end
        function Export_figure_all_video(obj, file_path, frame_rate, ti_arr)
%             Сохранение изображений с полями скорости в видеофайл
            if ~exist(fileparts(file_path),'dir'), mkdir(fileparts(file_path)); end
            v = VideoWriter(file_path);
            v.FrameRate = frame_rate;
            open(v);
            if ~exist('ti_arr','var'), ti_arr = 1:obj.ti_count; end
            for i = 1:numel(ti_arr)
                ti = ti_arr(i);
                obj.Go_to_ti(ti);
                obj.Redraw_fields();
                drawnow();
                writeVideo(v, getframe(obj.fig_fields));
                obj.Add_to_log(sprintf('Сохранен  кадр %d',ti));
            end
            close(v)
        end
        function Export_comment(obj, file_path)
            if ~exist(fileparts(file_path),'dir'), mkdir(fileparts(file_path)); end
            fileID = fopen(file_path,'w');
            for i = 1:numel(obj.p.rp.comment)
                fprintf(fileID, '%s\r\n', obj.p.rp.comment{i});
            end
            fclose(fileID);
        end
        
        
        
        
        
        %% Анализ
        function pos_ij_arr = Get_pos_ij_arr__of_selected_point(obj)
            if isempty(obj.selected_points)
                pos_ij_arr = [];
                return;
            end
            pos_ij_arr = zeros( size(obj.selected_points,1), 2 );
            for i = 1:size(obj.selected_points,1)
                sp_x = obj.selected_points(i,1);
                sp_y = obj.selected_points(i,2);
                d = sqrt( (obj.p.pg.xMat - sp_x).^2 + (obj.p.pg.yMat - sp_y).^2 );
                [d_min, d_min_i] = min(d(:));
                if d_min > 100, warning('Выбранная точка дальше 100 px от ближайшего узла'); end
                [pos_i, pos_j] =  ind2sub(size(d),d_min_i);
                pos_ij_arr(i,:) = [pos_i, pos_j];
            end
        end
        function pos = Get_pos_by_pos_ij_arr(obj, pos_ij_arr)
            if isempty(pos_ij_arr)
                pos = [];
                return;
            end
            pos = nan(size(pos_ij_arr,1),4);
            for i = 1:size(pos_ij_arr,1)
                pos_i = pos_ij_arr(i,1);
                pos_j = pos_ij_arr(i,2);
                x_px = obj.p.pg.xMat(pos_i,pos_j);
                y_px = obj.p.pg.yMat(pos_i,pos_j);
                x_m = obj.core.transform_processor.Convert_x(x_px);
                y_m = obj.core.transform_processor.Convert_y(y_px);
                pos(i,:) = [x_px y_px x_m y_m];
            end
        end
        
        function [ts, pos_ij_arr] = Get_time_series( obj, pos_ij_arr )
            [ts, pos_ij_arr] = obj.core.analyzer.Get_time_series( obj.core.fi_processor.data, pos_ij_arr);
        end
        
        function Plot_time_series( obj, pos_ij_arr  )
            [ts, pos_ij_arr] = obj.Get_time_series( pos_ij_arr );
            
            for pos_ij_arr_i = 1:size(ts,3)
                pos_i = pos_ij_arr(pos_ij_arr_i,1);
                pos_j = pos_ij_arr(pos_ij_arr_i,2);
                x = obj.p.pg.xMat(pos_i,pos_j);
                y = obj.p.pg.yMat(pos_i,pos_j);
                
                t  = ts(:, 2, pos_ij_arr_i);
                xd = ts(:, 3, pos_ij_arr_i);
                yd = ts(:, 4, pos_ij_arr_i);
                
                subplot(211);
                plot( t, xd, '.',...
                    'displayname',...
                    sprintf('pos_i %d, pos_j %d, x %.5f, y %.5f', pos_i, pos_j, x, y) );
                hold('on');
                xlabel('Время, с');
                ylabel('u, м/с');
                
                subplot(212);
                plot( t, yd, '.',...
                    'displayname',...
                    sprintf('pos_i %d, pos_j %d, x %.5f, y %.5f', pos_i, pos_j, x, y) );
                hold('on');
                xlabel('Время, с');
                ylabel('v, м/с');
            end
        end
        
        function Plot_profiles( obj, profile_y__pos_i, profile_x__pos_j, legend_text  )
            % profile_x__pos_j - набор номеров координат по y для профилей вдоль x
            % profile_x__pos_j - набор номеров координат по x для профилей вдоль y
            %TODO сделать Getprofiles, сделать для не среднего
            [xd, yd] = obj.Update_mean_field();            
            xd          = obj.core.transform_processor.Convert_xdispl(xd);
            yd          = obj.core.transform_processor.Convert_ydispl(yd);
            
            if ~isempty(profile_x__pos_j)                
                for profile_x__pos_j__i = 1:numel(profile_x__pos_j)
                    pos_j = profile_y__pos_i(profile_x__pos_j__i);
                    y = unique(obj.p.pg.yMat(:,pos_j));
                    x_profile = obj.p.pg.xMat(:,pos_j);
                    xd_profile = xd(:,pos_j);
                    yd_profile = yd(:,pos_j);
                    y           = obj.core.transform_processor.Convert_y(y);
                    x_profile   = obj.core.transform_processor.Convert_x(x_profile);
                    subplot(221);
                    plot( x_profile, xd_profile, '.-',...
                        'displayname',...
                        sprintf('%s pos_j %d, y %.5f м', legend_text, pos_j, y) );hold('on');
                    subplot(222);
                    plot( x_profile, yd_profile, '.-',...
                        'displayname',...
                        sprintf('%s pos_j %d, y %.5f м', legend_text, pos_j, y) );hold('on');
                end
                subplot(221);
                xlabel('x, м');
                ylabel('u, м/с');
                legend('show','location','eastoutside','interpreter','none')
                subplot(222);
                xlabel('x, м');
                ylabel('v, м/с');
                legend('show','location','eastoutside','interpreter','none')
            end
            
            if ~isempty(profile_y__pos_i)                
                for profile_y__pos_i__i = 1:numel(profile_y__pos_i)
                    pos_i = profile_y__pos_i(profile_y__pos_i__i);
                    x = unique(obj.p.pg.xMat(pos_i,:));
                    y_profile = obj.p.pg.yMat(pos_i,:);
                    xd_profile = xd(pos_i,:);
                    yd_profile = yd(pos_i,:);
                    x           = obj.core.transform_processor.Convert_x(x);
                    y_profile   = obj.core.transform_processor.Convert_y(y_profile);
                    subplot(223);
                    plot( xd_profile, y_profile, '.-',...
                        'displayname',...
                        sprintf('%s pos_i %d, x %.5f м', legend_text, pos_i, x) );hold('on');
                    subplot(224);
                    plot( yd_profile, y_profile, '.-',...
                        'displayname',...
                        sprintf('%s pos_i %d, x %.5f м', legend_text, pos_i, x) );hold('on');
                end
                subplot(223);
                ylabel('y, м');
                xlabel('u, м/с');
                legend('show','location','eastoutside','interpreter','none')
                subplot(224);
                ylabel('y, м');
                xlabel('v, м/с');
                legend('show','location','eastoutside','interpreter','none')
            end
        end
        
        
        function [xd, yd] = Update_mean_field( obj )
            obj.Add_to_log('Вычисление среднего поля...')
            [xd, yd] = obj.core.analyzer.Calc_mean_field();
            obj.Add_to_log('Среднее поле вычислено')
        end
        
        function [xd_mat3, yd_mat3] = Get_displ_mat3( obj, stage)
            switch stage
                case 'piv'
                    data = obj.core.piv_processor.data;
                case 'fi'
                    data = obj.core.fi_processor.data;
            end
            [data_arr, data_is_empty_arr] = data.Get_all_as_cell();
            xd_mat3 = cellfun(@(x) x.xdispl, data_arr(~data_is_empty_arr),'uni',false);
            yd_mat3 = cellfun(@(x) x.ydispl, data_arr(~data_is_empty_arr),'uni',false);
            xd_mat3 = cat(3,xd_mat3{:});
            yd_mat3 = cat(3,yd_mat3{:});
        end
        %%
        function Add_selected_point_px(obj,x_px,y_px)
            x_m = obj.core.transform_processor.Convert_x(x_px);
            y_m = obj.core.transform_processor.Convert_y(y_px);
            obj.selected_points = [ obj.selected_points; x_px, y_px, x_m, y_m ];
        end
        function Add_selected_point_m(obj,x_m,y_m)
            x_px = obj.core.transform_processor.Convert_x_to_px(x_m);
            y_px = obj.core.transform_processor.Convert_y_to_px(y_m);
            obj.selected_points = [ obj.selected_points; x_px, y_px, x_m, y_m ];
        end
        function Clear_selected_point_m(obj)
            obj.selected_points = [  ];
        end
        %%
        function [fi_output, pg] = Get_field_intrept(obj, ti)
            if isempty(obj.core) || isempty(obj.core.fi_processor), return; end
            fi_output = obj.core.fi_processor.data.Get(ti);
            pg = obj.p.pg;
        end
        %% Предсмещения
        function Import_initial_displacements(obj, input_piv_main)
            % загружает начальные смещения из проекта
            %             input_piv_main - типа PIV_main из которого берутся смещения
            if ~isequal( obj.p.pf.first_frames, input_piv_main.p.pf.first_frames )
                error('pf совпадают');
            end
            obj.Add_to_log('Начало импорта смещений...');
            for ti = 1:obj.ti_count
                [ fi_input, pg_input ] = input_piv_main.Get_field_intrept(ti);
                if isempty(fi_input)
                    warning('Нет данных предсмещения');
                    continue; % ID останется нулевым
                else
                    xdispl = fi_input.xdispl;
                    ydispl = fi_input.ydispl;
                    x = pg_input.xMat;
                    y = pg_input.yMat;
                    gp = ~isnan(xdispl) & ~isnan(ydispl);
                    if ~any(gp(:)), continue; end % ID останется нулевым
                    SI_xdispl = scatteredInterpolant( x(gp), y(gp), xdispl(gp));
                    SI_ydispl = scatteredInterpolant( x(gp), y(gp), ydispl(gp));
                    SI_xdispl.Method = 'linear';
                    SI_ydispl.Method = 'linear';
                    SI_xdispl.ExtrapolationMethod = 'nearest';
                    SI_ydispl.ExtrapolationMethod = 'nearest';
                    xdispl_q = SI_xdispl( obj.p.pg.xMat, obj.p.pg.yMat );
                    ydispl_q = SI_ydispl( obj.p.pg.xMat, obj.p.pg.yMat );
                    if isempty(xdispl_q) || isempty(ydispl_q)
                        warning('Process_one__interpolate_space: Интерполяция не удалась')
                        continue;
                    end
                    frame_step_ratio = obj.p.pf.frame_step / input_piv_main.p.pf.frame_step; % на случай если считалось с разными шагами
                    ID.xIDArr = xdispl_q * frame_step_ratio;
                    ID.yIDArr = ydispl_q * frame_step_ratio;
                    obj.core.piv_processor.ID_data.Set( ti, ID );
                end
            end
            obj.Add_to_log('Импорт смещений завершен');
        end
        %% Импорт параметров из проекта
        function Import_params(obj, input_piv_main, params_list)
            %             params_list - список имен параметров как cell массив строк {'pp', 'pg'}
            if any(strcmp(params_list,'rp'))
                obj.Set_rp_params(input_piv_main.p.rp);
            end
            if any(strcmp(params_list,'il'))
                obj.Set_il_params(input_piv_main.p.il);
            end
            if any(strcmp(params_list,'ipp'))
                obj.Set_ipp_params(input_piv_main.p.ipp);
            end
            if any(strcmp(params_list,'pp'))
                obj.Set_pp(input_piv_main.p.pp);
            end
            if any(strcmp(params_list,'pf'))
                obj.Set_pf(input_piv_main.p.pf);
            end
            if any(strcmp(params_list,'pg'))
                obj.Set_pg(input_piv_main.p.pg);
            end
            if any(strcmp(params_list,'fi'))
                obj.Set_fi_params(input_piv_main.p.fi);
            end
            if any(strcmp(params_list,'ap'))
                obj.Set_ap(input_piv_main.p.ap);
            end
            if any(strcmp(params_list,'plot_params'))
                obj.Set_plot_params(input_piv_main.p.plot_params);
            end
        end
    end
end


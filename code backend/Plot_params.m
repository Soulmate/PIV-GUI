classdef Plot_params
    %PLOT_PARAMS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        image_on = true;        
        image_processed = true;
        image_colormap = 'jet';
        
        grid_on = true;
        grid_symbol = '+';
        grid_symbol_size = 5;
        grid_symbol_color = 'r';
        grid_show_status = false;
        grid_show_status_filtering = false;
        grid_show_windows = false;
        
        pcolor_on = false;
        pcolor_source = 'fi'; % врианты 'piv' 'fi' 'mean'
        pcolor_colormap = 'jet';
        pcolor_value = 'V'; %u, v, V
        pcolor_caxis_auto = true;
        pcolor_caxis = [0 100];  
        pcolor_colorbar_on = true;
        pcolor_shading = 'interp';
        
        quiver_on_piv = true;         %исходные
        quiver_on_fi  = true;         %фильтрованные и интерполированные
        quiver_color_piv = 'w';                
        quiver_color_fi  = 'g';
        quiver_scale = 5;
        quiver_step = 1; 
        quiver_directions_only = false;      
        
        quiver_on_mean = false;
        quiver_color_mean = 'y';
        
        quiver_on_ID = false; % начальные смещения
        quiver_color_ID = 'm';
        
        plot_in_scale = true; 
        
        show_grid = false;
        show_ticks = false;
        show_title = true;
    end    
end

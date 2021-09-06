classdef Filter_and_interpolation_params
    %UNTITLED3 Summary of this class goes here
    %   Detailed explanation goes here
    properties
        version = 1;
        
        %% ‘ильтраци€:
        local_filtering__on = true;
        CC_ratio_limits = [1.2 inf];
        CC_maxRaitio_max = inf;
        mean_im1_limits = [-inf inf];
        xd_limits = [-inf inf];
        yd_limits = [-inf inf];
        d_limits  = [-inf inf];
        
        %медианна€ фильтраци€:
        median_space__on = false;
        median_space__window_size = [3 3]; % размер окна (x y)
        median_space__max_d_difference = 5; % максимальное отличие от медианного, px/кадр
        
        %медианна€ фильтраци€:
        median_time__on = false;        
        median_time__max_d_difference = 5; % максимальное отличие от медианного, px/кадр
        median_time__dynamic__on = false;
        median_time__dynamic__window_size = 5; % размер окна (ti)        
        %% »нтерпол€ци€:
        interp_space__on = false;
        interp_space__Method = 'linear'; % 'linear','nearest' , or 'natural'.
        interp_space__ExtrapolationMethod = 'none'; %'nearest', 'linear', or 'none'.
               
        interp_time__on = false;
        interp_time__Method = 'linear'; % 'linear' | 'nearest' | 'next' | 'previous' | 'spline' | 'pchip' | 'cubic' | 'makima'         
        interp_time__max_gap_length = 5; % максимальный промеждуток, который мы интерполируем (в кадрах)
    end    
end


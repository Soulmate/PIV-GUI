classdef Project_params
    %UNTITLED5 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        rp      Record_params
        il      Image_loader_params
        ipp     Image_preprocessor_params
        
        pp      PIV_params 
        pg      PIV_grid
        pf      PIV_frames
        fi      Filter_and_interpolation_params
        
        ap      Analyzer_params
        
        plot_params    Plot_params
    end
end


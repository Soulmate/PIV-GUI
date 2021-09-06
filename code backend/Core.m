classdef Core < handle
    %UNTITLED6 Summary of this class goes here
    %   Detailed explanation goes here
    %
    properties
        il                  Image_loader
        ipp                 Image_preprocessor
        piv_processor       PIV_processor
        fi_processor        Filter_and_interpolation_processor
        transform_processor Transform_processor
        exporter            Exporter
        analyzer            Analyzer
    end
    %
    methods
        function obj = Core(il, ipp, piv_processor, fi_processor, transform_processor, exporter, analyzer )
            obj.il = il;
            obj.ipp = ipp;
            obj.piv_processor = piv_processor;
            obj.fi_processor = fi_processor;
            obj.transform_processor = transform_processor;
            obj.exporter = exporter;
            obj.analyzer = analyzer;
        end
    end
end


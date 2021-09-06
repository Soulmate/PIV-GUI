classdef PIV_params
    %UNTITLED Summary of this class goes here
    
    % pp.wSize = [32 32];
    % pp.maxDispl = pp.wSize*Inf;
    % pp.minS2NRatio = 1;
    % pp.useSubpixel = true;
    % pp.useBiasCorrection = false;
    % pp.saveCCandIMC = false;
    % pp.xIDArr%- массив(можно двумерный) координат центров
    % pp.yIDArr%- массив(можно двумерный) начальных смещений
    % pp.doCCArr%- массив делать/не делать КК (может быть [] - делать все)
    
    properties
        version = 1;
        
        wSize = [64 64];
        doFirstPass = true;
        wSize1 = [128 128];
        maxDispl = [Inf Inf];
        minS2NRatio = 1;
        useSubpixel = true;
        doMultiMax = true;
        xIDArr = 0; % массив(можно двумерный) начальных смещений
        yIDArr = 0;
        saveCCandIMC = false; % сохранять ккф и элементы изображений для анализа
        max_mask_pixels_prc = 50; %максимальный процент пикселей маски в окне. При превышении ККФ не вычисляется
        useBiasCorrection = false; % использовать Bias сorrection
    end    
end


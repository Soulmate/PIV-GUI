classdef PIV_params
    %UNTITLED Summary of this class goes here
    
    % pp.wSize = [32 32];
    % pp.maxDispl = pp.wSize*Inf;
    % pp.minS2NRatio = 1;
    % pp.useSubpixel = true;
    % pp.useBiasCorrection = false;
    % pp.saveCCandIMC = false;
    % pp.xIDArr%- ������(����� ���������) ��������� �������
    % pp.yIDArr%- ������(����� ���������) ��������� ��������
    % pp.doCCArr%- ������ ������/�� ������ �� (����� ���� [] - ������ ���)
    
    properties
        version = 1;
        
        wSize = [64 64];
        doFirstPass = true;
        wSize1 = [128 128];
        maxDispl = [Inf Inf];
        minS2NRatio = 1;
        useSubpixel = true;
        doMultiMax = true;
        xIDArr = 0; % ������(����� ���������) ��������� ��������
        yIDArr = 0;
        saveCCandIMC = false; % ��������� ��� � �������� ����������� ��� �������
        max_mask_pixels_prc = 50; %������������ ������� �������� ����� � ����. ��� ���������� ��� �� �����������
        useBiasCorrection = false; % ������������ Bias �orrection
    end    
end


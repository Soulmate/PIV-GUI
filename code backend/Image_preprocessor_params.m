classdef Image_preprocessor_params
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        version = 1;
        %%
        color_channel = 1;
        %% bg
        bg
        
        bg_on = false;
        bg_cut_type = 'max';% min ��� max ��� ������ (����� �� ����� ����������)
        bg_cut_val  = 0;
        
        bg_source_file_path = '';
        
        bg_source_auto_prctile = 1;
        bg_source_auto_N = 10; %����� �������
        %% mask
        mask
        
        mask_on = false;
        mask_set_value = 0; % ������� ���������� �� ��� ��������        
        mask_source_path = "";
        mask_source_color = [255 0 0]; % ������� ����������� �������� � ����� ������ ��������� ������
        %% ������������ �����
        dynamic_mask_on = false;
        dynamic_mask_imageLoader; % ��������� ����������� � ������� �������� � ��������         
        dynamic_mask_set_value = 0; % ������� ���������� �� ��� ��������     
        dynamic_mask_source_color = 0; % ������� ����������� �������� � ����� ������ ��������� ������
        %% levels
        levels_on = false;
        levels_limits = [0 100];
    end
end
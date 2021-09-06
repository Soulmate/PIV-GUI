classdef PIV_frames
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
    %            compared_frames_offset %������������ �����: �������� [ 0 1; 0 2; 0 3 ] - ������ �� ������, ������ � �������, ������ � ���������
    %            firstFrames        % ������ ������ ������ ���������
    
    properties (SetAccess = protected, GetAccess = public)
        version = 1;
        
        frame_start
        frame_end
        frame_skip
        frame_step
        
        first_frames
        compared_frames_offset
        frame_count
    end
    
    methods
        function obj = PIV_frames(frame_start, frame_end, frame_skip, frame_step)
            % frame_start - � ������ ����� ��������
            % frame_end - �� ������ ����� ������� (����� ����� ������, �.�. �� ����� ������ ������������ ������)
            % frame_skip: 1 - ������ ������, 2 - ������ ������....
            % frame_step: ����� ������� ������ ����������, 1 - ��������, 2 - ����� 1
            
            obj.frame_start = frame_start;
            obj.frame_end = frame_end;
            obj.frame_skip = frame_skip;
            obj.frame_step = frame_step;
            
            obj.first_frames = frame_start : frame_skip : ( frame_end - frame_step );
            obj.compared_frames_offset  = [0 frame_step];
            obj.frame_count = numel(obj.first_frames);
        end
    end
end



%             if (max(firstFrames(:)) + max(compared_frames_offset(:)) > ip.imNum)
%                 error('���� ����� ����� ����� � ������� ������ ��� ����� �����������');
%             end
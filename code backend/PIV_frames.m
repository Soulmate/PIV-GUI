classdef PIV_frames
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
    %            compared_frames_offset %сравниваемые кадры: например [ 0 1; 0 2; 0 3 ] - первый со вторым, первый с третьим, первый с четвертым
    %            firstFrames        % номера первых кадров сравнения
    
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
            % frame_start - с какого кадра начинать
            % frame_end - до какого кадра считать (полей будет меньше, т.к. он будет вторым сравниваемым кадров)
            % frame_skip: 1 - каждый первый, 2 - каждый второй....
            % frame_step: через сколько кадров сравнивать, 1 - соседние, 2 - через 1
            
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
%                 error('надо будет брать кадры с номером больше чем число изображений');
%             end
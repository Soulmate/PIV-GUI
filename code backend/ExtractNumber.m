function [ n ] = ExtractNumber( str )
%EXTRACTNUMBER Summary of this function goes here
%   Detailed explanation goes here
id = isstrprop(str,'digit');
if (~any(id))
    n = NaN;
    return
end
n_end = find(id,1,'last');
id(n_end:end) = true;
n_beg = find(~id,1,'last')+1;
if (isempty(n_beg))
    n_beg = 1;
end
n = str2num(str(n_beg:n_end));
end
%% test
% 
% ExtractNumber('0501') == 501
% ExtractNumber('asd_0502.jpg') == 502
% ExtractNumber('asdf1231asd2_0501.jpg') == 501
% isnan(ExtractNumber('sadfasdf.jpg'))
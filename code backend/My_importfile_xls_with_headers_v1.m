function [data, headers, raw_data] = My_importfile_xls_with_headers_v1(workbookFile, xlRange, row_num_headers, row_num_data_start) 
% reads xlsx file with headers
% workbookFile - file path
% example: rec_list = importfile_reclist_v2('..\ADC records list.xlsx');

sheetName = 1;
if exist('xlRange','var') && ~isempty(xlRange)
    [~, ~, raw_data] = xlsread(workbookFile, sheetName, xlRange);
else
    [~, ~, raw_data] = xlsread(workbookFile, sheetName);
end
headers = raw_data(row_num_headers,:);
data = raw_data(row_num_data_start:end,:);
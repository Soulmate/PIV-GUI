function [table_data, data, raw_data] = My_importfile_xls_with_headers_to_table_v1(workbookFile, xlRange, row_num_headers, row_num_data_start) 
% reads xlsx file with headers
% workbookFile - file path
% example: rec_list = My_importfile_xls_with_headers_to_table_v1('..\список записей 1.xlsx',[],1,3));
%%

[data, headers, raw_data] = My_importfile_xls_with_headers_v1(workbookFile, xlRange, row_num_headers, row_num_data_start);


%где стринги заменим наны на пустую строку
d_is_str = cellfun(@(x) ischar(x), data);
d_is_nan = cellfun(@(x) any(isnan(x)),  data);
d_is_num = cellfun(@(x) isnumeric(x),  data);
d_col_str = repmat(any(d_is_str,1),[size(data,1),1]); %если в колонке хотя бы одна текстовая строка

data( d_col_str & d_is_nan ) = {''}; % если в колонке есть текст, то всё будет текстом
data( d_col_str & d_is_num ) = cellfun(@(x) num2str(x), data( d_col_str & d_is_num ), 'uni', false); % если в колонке есть текст, то всё будет текстом
try
table_data = cell2table( data, 'variablenames', headers );
catch
    disp(headers);
    error('в первой строке файла должны быть валидные имена переменных для матлаба')
end

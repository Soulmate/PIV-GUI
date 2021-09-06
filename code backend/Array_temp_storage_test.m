obj = Array_temp_storage(11, 3, 'temp_storage');
%%

for i = 1:101
    obj.Set(i,-i);
end

for i = 1:101
    obj.Set(i,i);
end
%%
% obj.Get(11)
%%
obj.Get_all_as_cell()
%%
obj.Export_to_file('test ats\1');
%%

clear all
obj = Array_temp_storage(11, 5, 'temp_storage');


obj.Import_from_file('test ats\1');
obj.Get_all_as_cell()
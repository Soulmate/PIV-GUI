addpath('..\code gui');
addpath('..\code backend');
addpath('..\lib');
close all
clear all
clc
%%
obj = PIV_main();
% obj.Proj_new('..\test_data\25mm_tr.1_10m3h_11062019_125251 cut', 'jpg', 'test\2.proj');
obj.Proj_new('..\test_data\175mm_tr.1_16m3h_14062019_82909 cut', 'jpg', 'test\2.proj');
% obj.Proj_new('D:\Experiments\2019 okbm PIV\100кадров_Exp.2', 'jpg', 'test\2.proj');
%%
rp = obj.p.rp;
rp.comment = {'Тестовой описание' 'вторая строка' };
rp.scale = 104;
rp.fps = 30;
rp.zero_pos_px = [-100 500];
obj.Set_rp_params(rp);
%% построение
plot_params = obj.p.plot_params;
plot_params.grid_on = true;
plot_params.quiver_scale = 0.1;
plot_params.quiver_on_piv = true;
plot_params.quiver_on_fi = true;
plot_params.quiver_color_fi = 'r';
plot_params.quiver_on_mean = true;
plot_params.quiver_on_mean = true;
plot_params.plot_in_scale = true;
plot_params.show_ticks = true;
obj.Set_plot_params(plot_params);
%% Параметры изображений
ipp_params = obj.p.ipp;
ipp_params.color_channel = 2;
obj.Set_ipp_params(ipp_params);

% % фон
% obj.Load_and_use_bg('..\test_data\25mm_tr.1_10m3h_11062019_125251 cut\25mm_tr.1_10m3h0000005459.jpg'); 
% obj.Go_to_frame(1); 
% obj.Redraw_fields();
% im = obj.core.ipp.getImage(1);
% if ~all(im(:)) == 0
%     error('фон');
% end

obj.Calc_and_use_bg();
%%
ipp_params = obj.p.ipp;
ipp_params.color_channel = 2;
ipp_params.mask_source_color = [237 28 36];
obj.Set_ipp_params(ipp_params);
obj.Load_and_use_mask('..\test_data\mask 2 175mm_tr.1_16m3h0000000006.png');
%%
pf = PIV_frames(1,100,1,1);
obj.Set_pf(pf);

pg = PIV_grid( [100:32:350], [150:32:350] );
% pg = PIV_grid( 100, 200 );
obj.Set_pg(pg);

pp = obj.p.pp;
pp.doFirstPass = true;
pp.wSize1 = 128 * [1 1];
pp.wSize  = 64 * [1 1];
pp.saveCCandIMC  = false;
obj.Set_pp(pp);

fi = obj.p.fi;
fi.local_filtering__on = true;
fi.median_space__on = true;
fi.median_space__window_size = [3 3]; % размер окна (x y)
fi.median_space__max_d_difference = 3; % максимальное отличие от медианного, px/кадр        
fi.median_time__on = true;
fi.median_time__max_d_difference = 3;
fi.median_time__dynamic__on = false;
fi.median_time__dynamic__window_size = 5;
fi.interp_space__on = true;
fi.interp_time__on = true;
fi.interp_time__max_gap_length = 5;
obj.Set_fi_params(fi);
%%
figure
obj.ax_process = gca;
obj.Process_piv_all(true,1,true,1);
obj.Process_fi_all();
info = obj.core.fi_processor.GetInfo();
disp([info.status_list, info.status_histc]);
%% analyze
ap = obj.p.ap;
ap.ts_smoothing_window_size = 1;
obj.Set_ap(ap);

figure
% obj.Plot_time_series( [ 3 1; 3 2; 3 3; 3 4; 3 5; ] );
obj.Plot_time_series( [ 1 1 ] );

obj.Update_mean_field();
obj.Redraw_fields();
%%
file_path = 'test\1.proj';
obj.Proj_save(file_path);

clear all
file_path = 'test\1.proj';
obj = PIV_main();
obj.Proj_load(file_path);
%% export
obj.core.exporter.decimal_delimeter = '.';
obj.core.exporter.column_delimeter = '\t';
obj.core.exporter.ommit_nans = true;
obj.Export_all_fields_to_one_file('output\test.dat');
obj.Export_all_fields_to_separate_files('output\fs\test sep.dat');
obj.Export_figure_current( 'output\1.png' );
% obj.Export_figure_all( 'output\all.png' )
% obj.Export_figure_all_video( 'output\all.avi', 5 )
obj.Export_comment( 'output\-описание.txt' )
obj.Export_time_series( 'output\ts\ts.dat', [] );
% obj.Export_mean_field_to_files( 'output\mean.dat', [1 2 3], [4 5 6] );
obj.Export_mean_field_to_files( 'output\mean.dat', [1], [1] );
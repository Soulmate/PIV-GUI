tim = TestImageGenerator_v2;
%%
d = [10 -20];

tim.d_uniform_xy = d;
tim.d_uniform_scatt_xy = 0* [1 1];


tim.calc__pos( d(1), d(1), d(2), d(2) );
tim.calc__displ();
tim.calc__sizes();
tim.calc__brightnesses();
tim.plot_distributions();

%%

figure
tim.Generate_pair();
tim.plot_pair();
tim.Save_images('result1');


%% TODO
% отдельная генерация случайных положений ,скоростей распределений 
% с одним и тем же положением менять смещение
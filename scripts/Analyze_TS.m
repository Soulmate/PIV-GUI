% расширенная версия Get_time_series из Analyzer

%   pos_ij_arr - индексы на сетке в 2 колонки, если пустое - то
%   для всех точек
%  [10 12
%   15 46
%   13 14]

% ts - 3д матрица, склеенные по третей размерности
% трехколоночные матрица (время, xd, yd)

%obj - piv_main


pos_ij_arr = [3 3];


%             if pos_i > size(pg.xMat,1) || pos_j > size(pg.xMat,2), return; end
if isempty(pos_ij_arr) %выбираем все
    [pos_i, pos_j] = meshgrid( 1:size(obj.pg.xMat,1), 1:size(obj.pg.xMat,2) );
    pos_ij_arr = [ pos_i(:), pos_j(:) ];
end

ts = nan( obj.p.pf.frame_count, 9, size(pos_ij_arr,1) );

for ti = 1:obj.p.pf.frame_count
    disp([ti obj.p.pf.frame_count]);
    t = ( obj.p.pf.first_frames(ti) - 1 ) / obj.p.rp.fps;
    d_piv =  obj.core.piv_processor.data.Get(ti);
    d_fi  =  obj.core.fi_processor. data.Get(ti);
    if isempty(d_piv), continue; end
    if isempty(d_fi), continue; end
    for pos_ij_arr_i = 1:size(pos_ij_arr,1)
        pos_i = pos_ij_arr(pos_ij_arr_i,1);
        pos_j = pos_ij_arr(pos_ij_arr_i,2);
        
        ts(ti, 1, pos_ij_arr_i) = ti;
        ts(ti, 2, pos_ij_arr_i) = t;
        ts(ti, 3, pos_ij_arr_i) = d_piv.xdispl(pos_i,pos_j);
        ts(ti, 4, pos_ij_arr_i) = d_piv.ydispl(pos_i,pos_j);        
        ts(ti, 5, pos_ij_arr_i) = d_piv.CC_maxRaitio(pos_i,pos_j);
        ts(ti, 6, pos_ij_arr_i) = d_piv.CC_maxValue(pos_i,pos_j);
        ts(ti, 7, pos_ij_arr_i) = d_piv.mean_im1(pos_i,pos_j);
        ts(ti, 8, pos_ij_arr_i) = d_fi.xdispl(pos_i,pos_j);
        ts(ti, 9, pos_ij_arr_i) = d_fi.ydispl(pos_i,pos_j);
    end
end
% 
% %сглаживание
% if round(obj.p.ap.ts_smoothing_window_size) > 1
%     for pos_ij_arr_i = 1:size(pos_ij_arr,1)
%         ts(:,3,pos_ij_arr_i) = nanfastsmooth( ts(:,3,pos_ij_arr_i), round(obj.ap.ts_smoothing_window_size) );
%         ts(:,4,pos_ij_arr_i) = nanfastsmooth( ts(:,4,pos_ij_arr_i), round(obj.ap.ts_smoothing_window_size) );
%     end
% end

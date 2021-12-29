% информация о ККФ выделенных точек
% Надо считать PIV в включенной записью дополнительных данных

d = obj.core.piv_processor.data.Get(obj.current_ti);

pos_ij_arr = Get_pos_ij_arr__of_selected_point(obj);



for pos_num = 1:size(pos_ij_arr,1)
    
    pos_i = pos_ij_arr(pos_num,1);
    pos_j = pos_ij_arr(pos_num,2);
    
    x = obj.p.pg.xMat(pos_i,pos_j);
    y = obj.p.pg.yMat(pos_i,pos_j);
    
    
    status = d.status(pos_i,pos_j);%: [49×17 double]
    xdispl = d.xdispl(pos_i,pos_j);%: [49×17 double]
    ydispl = d.ydispl(pos_i,pos_j);%: [49×17 double]
    CC_maxValue = d.CC_maxValue(pos_i,pos_j);%: [49×17 double]
    CC_maxRaitio = d.CC_maxRaitio(pos_i,pos_j);%: [49×17 double]
    
    mean_im1 = d.mean_im1(pos_i,pos_j);%: [49×17 double]
    time_of_iteration = d.time_of_iteration;%: 1.2989
    
    
    
    fprintf(['====\n'...
        'i %d, j %d\n'...
        'x %f, y %f\n'...
        'status %d\n',...
        'xdispl %f, ydispl %f\n'...
        'CC_maxValue %f, CC_maxRaitio %f\n'...
        'mean_im1 %f\n'],...
        pos_i,pos_j,...
        x,y,...
        status,...
        xdispl, ydispl,...
        CC_maxValue, CC_maxRaitio,...
        mean_im1);
    
    if ~isempty(d.CC_infoArr)
        CC_infoArr = d.CC_infoArr{pos_i,pos_j};%: {49×17 cell}
        
        
        
        imc1 = CC_infoArr.imc1;%: [64×64 double]
        imc2 = CC_infoArr.imc2;%: [64×64 double]
        result_conv = CC_infoArr.result_conv;%: [64×64 double]
        xd = CC_infoArr.xdispl;
        yd = CC_infoArr.ydispl;
        
        
        figure;
        
        if (d.pp.doFirstPass)
            im1c_FirstPass = CC_infoArr.im1c_FirstPass;
            im2c_FirstPass = CC_infoArr.im2c_FirstPass;
            result_conv_firstPass = CC_infoArr.result_conv_firstPass;%: [128×128 double]
            xd_FirstPass = CC_infoArr.xd_FirstPass;
            yd_FirstPass = CC_infoArr.yd_FirstPass;
                        
            subplot(231);
            imagesc(im1c_FirstPass);
            title('1 pass frame 2')
            axis image;
            subplot(232);
            imagesc(im2c_FirstPass);
            title('1 pass frame 2')
            axis image;
            subplot(233);
            imagesc(result_conv_firstPass);hold on;
            plot(xd_FirstPass + d.pp.wSize1(1)/2 + 1,yd_FirstPass + d.pp.wSize1(2)/2 + 1,'xr','markersize',15);
            plot( (d.pp.wSize1(1)/2 + 1) * [1 1], [ 0 d.pp.wSize1(2) ],'r' );
            plot([ 0 d.pp.wSize1(1) ], (d.pp.wSize1(2)/2 + 1) * [1 1],'r' );
            axis image;
            title('1 pass CCF')
        end
        subplot(234);
        imagesc(imc1);
        axis image;
        title('2 pass frame 2')
        subplot(235);
        imagesc(imc2);
        axis image;
        title('2 pass frame 2')
        subplot(236);        
        imagesc(result_conv);hold on;
        plot(xd + d.pp.wSize(1)/2 + 1,yd + d.pp.wSize(2)/2 + 1,'xr','markersize',15);
        plot( (d.pp.wSize(1)/2 + 1) * [1 1], [ 0 d.pp.wSize(2) ],'r' );
        plot([ 0 d.pp.wSize(1) ], (d.pp.wSize(2)/2 + 1) * [1 1],'r' );
        shading flat
        axis image;
        title('2 pass CCF')
        
    end
end

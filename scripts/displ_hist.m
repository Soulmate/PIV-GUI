
for s2n = 1:0.01:2
    
    fi = obj.p.fi;
    fi.local_filtering__on = true;
    fi.CC_ratio_limits = [1 s2n];
    obj.Set_fi_params(fi);
    obj.Process_fi_all();
    
    ts = obj.Get_time_series([]);
    xd = ts(:,3,:);
    yd = ts(:,4,:);
    clf
    subplot(211)
    hist(xd(:),100);
    subplot(212)
    hist(yd(:),100);
    title(num2str(s2n))
    drawnow();
end

po = obj.core.piv_processor.data.Get(1);

CC_info = po.CC_infoArr{3,3}

figure
subplot(211)
imagesc(CC_info.result_conv_firstPass);
subplot(212)
imagesc(CC_info.result_conv);


%%
po.CC_infoArr
xd_mat3 = cellfun(@(x) x.xdispl, po.CC_infoArr, 'uni',true)








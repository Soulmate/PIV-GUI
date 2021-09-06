classdef PIV_plot < handle
    %PIV_PLOT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        ax %оси на которых всё рисуется
        plot_params Plot_params
    end
    
    methods
        function plot_centers( obj, x, y, gp )
            
            plot(obj.ax, x(gp), y(gp),...
                obj.plot_params.grid_symbol,...
                'markersize',obj.plot_params.grid_symbol_size,...
                'color',obj.plot_params.grid_symbol_color);
        end
        %%        
        function plot_status( obj, x, y, s, horizontalAlignment)                        
            for i = 1:numel(s)
                text(obj.ax, x(i), y(i), num2str(s(i)), ...
                    'fontsize', 6, ...
                    'HorizontalAlignment',  horizontalAlignment,...
                    'VerticalAlignment', 'baseline','color','r');
            end
        end
        %%
        function plot_windows(obj, x, y, wSize )                      
            if numel(x) >= 2
                i = 2;
                rectangle(obj.ax,'Position',[x(i)-wSize(1)/2,y(i)-wSize(2)/2,wSize(1),wSize(2)],'edgecolor', 'g');
            end
            if numel(x) >= 1
                i = 1;
                rectangle(obj.ax,'Position',[x(i)-wSize(1)/2,y(i)-wSize(2)/2,wSize(1),wSize(2)],'edgecolor', 'r');
            end
        end
        %%
        function plot_pcolor(obj, x, y, u, v, gp, eqvidistant )
            switch obj.plot_params.pcolor_value
                case 'u'
                    value = u;
                case 'v'
                    value = v;
                case 'V'
                    value = sqrt(u.^2 + v.^2);
            end
            %             value_q = griddata(x(gp),y(gp),value(gp),x,y);
            value_q = value; value(~gp) = nan;
            % в случае эквидистантной сетки:
            if eqvidistant
                x_limits = [ x(1) x(end) ]; %вроде с матрицами должно правильно работать
                y_limits = [ y(1) y(end) ];
                b = imagesc( obj.ax, ...
                    x_limits, y_limits, value_q'); 
                set(b,'AlphaData',~isnan(value_q'));
            else
                pcolor(obj.ax,x,y,value_q); shading(obj.ax, obj.plot_params.pcolor_shading);                
            end
            
            colormap(obj.ax,obj.plot_params.pcolor_colormap);
            if obj.plot_params.pcolor_caxis_auto
                current_caxis = prctile(value(:),[5 95]);
            else
                current_caxis = obj.plot_params.pcolor_caxis;
            end
            caxis(obj.ax,current_caxis);
            if (obj.plot_params.pcolor_colorbar_on)
                colorbar(obj.ax);
            else
                colorbar(obj.ax,'off');
            end
        end
        %%
        function plot_quiver(obj, x, y, u, v, gp, color )
            stepped_selected = false(size(x)); %точки, выбранные после прореживания
            stepped_selected(...
                1 : obj.plot_params.quiver_step : end,...
                1 : obj.plot_params.quiver_step : end) = true;            
            gp(~stepped_selected) = false;
            
            if any(gp(:))
                if obj.plot_params.quiver_directions_only
                    V = sqrt(u.^2 + v.^2);
                    u = u./V;
                    v = v./V;
                end
                quiver(obj.ax,x(gp),y(gp),...
                    obj.plot_params.quiver_scale * u(gp),...
                    obj.plot_params.quiver_scale * v(gp),...
                    0,...
                    'Color', color)
            end
        end
        %%
        
        
        function plot_hist(obj, PIV_output, u_or_v )
            xd_range = [-1 1] * PIV_output.pp.wSize(1)/2;
            yd_range = [-1 1] * PIV_output.pp.wSize(2)/2;
            if u_or_v == 'u'
                hist(obj.ax, PIV_output.xdispl(gp),100)
                set(gca,'xlim',xd_range);
                xlabel('u, px/frame')
            end
            if u_or_v == 'v'
                hist(obj.ax, PIV_output.ydispl(gp),100)
                set(gca,'xlim',yd_range);
                xlabel('v, px/frame')
            end
        end
        %         function plot_profile(obj, PIV_output )
        %             %             %
        %             %             subplot(122);
        %             %             % ПРОФИЛИ!
        %             %             scale = 96.2;
        %             %             fps = 2000;
        %             %             p = PIV_output_arr{ti,1};
        %             %             pp = p.pp;
        %             %             piv_grid =  pp.piv_grid;
        %             %             wSize =     pp.wSize;
        %             %             y = piv_grid.yMat(1,:)' - surface_pos;
        %             %             y = y * scale / 1000;
        %             %             gp = p.status == 0;
        %             %             xd = p.xdispl;
        %             %             xd(~gp) = nan;
        %             %             xd_profile = nanmean(xd,1)';
        %             %             %     plot(xd_profile,y);
        %             %             semilogx(y,xd);
        %             %             view([90 -90])
        %             %             set(gca,'ylim',[-10 0]);
        %             %
        %             %             xlabel('Высота, мм')
        %             %             ylabel('Скорость, см/с')
        %             %             drawnow()
        %             %             %                 saveas(gcf,[outputFolder '\' expName '\' num2str(ti,'%05d') '.jpg']);
        %             %
        %         end
    end
end


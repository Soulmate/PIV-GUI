%герегирует тестовые изображения по параметрам, перечисленным в файле
clear Parameters
figure('name','f1');

Prarmeters.nPairs = 10;
Prarmeters.imSize = [512 512] ; %y x
Prarmeters.disp = [10 -10];%[15.508 17.195]; %x y
Prarmeters.dispScatt = [3 3]; %x y
Prarmeters.dens = 0.01; % штук на квадратный пиксель
Parameters.valMax = 1;  %максимальное значение
Parameters.valMin = 1; %минимальное значение
Parameters.pSizeMax = 3;
Parameters.pSizeMin = 0.1;
Parameters.noiseLevel = 0.1;
Parameters.expTimeRatio = 0; %отношение экспозиции к межкадровому промежутку
Parameters.multiasmpling = 4;

path = 'result1';

gauss2d = @ (x,y,x0,y0,sigma2,val) val*exp(-(x-x0)^2/2/sigma2 -(y-y0)^2/2/sigma2);

%%
mkdir(path);
numOfParticles = round(prod(Prarmeters.imSize)*Prarmeters.dens);
dispx = Prarmeters.disp(1) + Prarmeters.dispScatt(1) * (rand([numOfParticles, 1]) - 0.5);
dispy = Prarmeters.disp(2) + Prarmeters.dispScatt(2) * (rand([numOfParticles, 1]) - 0.5);

tic

for iPair = 1%:Prarmeters.nPairs
    %%
    
    
    x0 = rand([numOfParticles, 1]);
    y0 = rand([numOfParticles, 1]);
    pSize = rand([numOfParticles, 1]);
    
    
    x0 = x0*(Prarmeters.imSize(2) + abs(Prarmeters.disp(1))) - Prarmeters.disp(1);
    y0 = y0*(Prarmeters.imSize(1) + abs(Prarmeters.disp(2))) - Prarmeters.disp(2);
    pSize = pSize*(Parameters.pSizeMax-Parameters.pSizeMin) + Parameters.pSizeMin;
    
    clear x0s;
    clear y0s;
    x0s{1} = x0;
    y0s{1} = y0;
    x0s{2} = x0 + dispx;
    y0s{2} = y0 + dispy;    
    clear x0;
    clear y0;
    %%
    clear ims;
    for im_i = 1:2  
        x0 = x0s{im_i};
        y0 = y0s{im_i};
        
        im = zeros(Prarmeters.imSize*Parameters.multiasmpling);
        val = rand([numOfParticles, 1]);
        val = val*(Parameters.valMax-Parameters.valMin) + Parameters.valMin;
        for i = 1:numOfParticles
            d_i = sqrt(dispx(i)*dispx(i) + dispy(i)*dispy(i));
            expNumOfPoints = round(d_i * Parameters.expTimeRatio/pSize(i)*2);
            if expNumOfPoints < 1
                expNumOfPoints =1;
            end
            for expi = 1:expNumOfPoints %номер экспозиции
                if expNumOfPoints <= 1
                    x0_i = x0(i);
                    y0_i = y0(i);
                else
                    x0_i = x0(i) + dispx(i) *  Parameters.expTimeRatio * (expi - 1)/(expNumOfPoints - 1);
                    y0_i = y0(i) + dispy(i) *  Parameters.expTimeRatio * (expi - 1)/(expNumOfPoints - 1);
                end
                
                x0_i = x0_i*Parameters.multiasmpling;
                y0_i = y0_i*Parameters.multiasmpling;
                pSize_i = pSize(i)*Parameters.multiasmpling;
                
                
                AreaSize = pSize_i;
                minx = round((x0_i - AreaSize - 1));
                maxx = round((x0_i + AreaSize + 1));
                miny = round((y0_i - AreaSize - 1));
                maxy = round((y0_i + AreaSize + 1));
                minx = min(size(im,2),max(1,minx));
                maxx = min(size(im,2),max(1,maxx));
                miny = min(size(im,1),max(1,miny));
                maxy = min(size(im,1),max(1,maxy));
                
                s2 = (pSize_i/3)^2;%квадрат сигмы
                for x = minx:maxx
                    for y = miny:maxy
                        v =  gauss2d(x,y,x0_i,y0_i,s2,val(i));
                        im(y,x) = im(y,x) + v;
                    end
                end
            end
        end
        
        im = imresize(im, 1/Parameters.multiasmpling);
        im = min(1,im);        
        im = im + rand(size(im))*Parameters.noiseLevel;
        ims{im_i} = im;
    end
    toc
    %%
    im_i = 1;    
    while ~isempty(findobj('type','figure','name','f1')) 
        imshow(ims{im_i});
        hold on;
        pause(0.7);
        if im_i == 1
            im_i = 2;
            title('1');
        else
            im_i = 1;
            title('2');
        end
    end
end



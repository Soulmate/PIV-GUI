%герегирует тестовые изображения по параметрам, перечисленным в файле
clear Parameters
Prarmeters.nPairs = 10;
Prarmeters.imSize = [128 128] ; %x y
Prarmeters.disp = [5.508 7.195]; %x y
Prarmeters.dens = 0.01; % штук на квадратный пиксель
Parameters.valMax = 0.5;  %максимальное значение
Parameters.valMin = 0.1; %минимальное значение
Parameters.pSizeMax = 4;
Parameters.pSizeMin = 2;
Parameters.noiseLevel = 0.1;
Parameters.expRatio = 1;

path = 'result1';

gauss2d = @ (x,y,x0,y0,sigma,val) val*exp(-(x-x0)^2/2/sigma^2 -(y-y0)^2/2/sigma^2);
gauss2dr = @ (x,y,x0,y0,s1_2,s2_2,s12_2,val) val*exp(-(x-x0)^2/2/s1_2 -(y-y0)^2/2/s2_2 - (x-x0)*(y-y0)/2/s12_2);

%%
for iPair = 1%:Prarmeters.nPairs
    %%
    mkdir(path);
    numOfParticles = round(prod(Prarmeters.imSize)*Prarmeters.dens);
%     numOfParticles = 10;
    
    x0 = rand([numOfParticles, 1]);
    y0 = rand([numOfParticles, 1]);
    pSize = rand([numOfParticles, 1]);
    val = rand([numOfParticles, 1]);
    
    x0 = x0*Prarmeters.imSize(1);
    y0 = y0*Prarmeters.imSize(2);
    pSize = pSize*(Parameters.pSizeMax-Parameters.pSizeMin) + Parameters.pSizeMin;
    val = val*(Parameters.valMax-Parameters.valMin) + Parameters.valMin;
    
    %%
    
    im1 = zeros(Prarmeters.imSize(2),Prarmeters.imSize(1));
    for i = 1:numOfParticles
        AreaSize = pSize(i) * Parameters.expRatio;
        minx = round((x0(i) - AreaSize - 1));
        maxx = round((x0(i) + AreaSize + 1));
        miny = round((y0(i) - AreaSize - 1));
        maxy = round((y0(i) + AreaSize + 1));
        minx = min(Prarmeters.imSize(1),max(1,minx));
        maxx = min(Prarmeters.imSize(1),max(1,maxx));
        miny = min(Prarmeters.imSize(2),max(1,miny));
        maxy = min(Prarmeters.imSize(2),max(1,maxy));      
        
        for x = minx:maxx
            for y = miny:maxy
                
                a = pi/10;
                s1 = pSize(i)/3 * Parameters.expRatio; 
                s2 = pSize(i)/3;
                
                %квадраты сигм
                s1r_2 = s1*s2 /(s1*sin(a)^2+s2*cos(a)^2);
                s2r_2 = s1*s2 /(s1*cos(a)^2+s2*sin(a)^2);
                s12r_2 = - s1*s2/sin(2*a)/(s1+s2);
                
                v =  gauss2dr(x,y,x0(i),y0(i),s1r_2,s2r_2,s12r_2,val(i));               
                
%                 v = gauss2d(x,y,x0(i),y0(i),pSize(i)/3,val(i));
                im1(y,x) = im1(y,x) + v;
            end
        end
    end
    im1 = min(1,im1);
    imshow(im1);
end
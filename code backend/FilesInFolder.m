function filePaths = FilesInFolder( folderPath , imagesExt, doSort)
if ~exist('imagesExt','var')
    imagesExt = 'jpg';
end
if ~exist('doSort','var')
    doSort = false;
end
%% чтение папки с изображениями
if (~isempty(folderPath))
    dirStructure = dir ([folderPath '\*.' imagesExt]);
else
    dirStructure = dir (['*.' imagesExt]);
end
imagePathsUnsorted = {dirStructure.name}';
%сортировка
if (nargin > 2 && doSort)
    fileNumbers = cellfun(@(x) ExtractNumber(x), imagePathsUnsorted,'UniformOutput', true);
    [~, fileNumbersIdexes] = sort(fileNumbers);
    filePaths = imagePathsUnsorted(fileNumbersIdexes);
else
    filePaths = imagePathsUnsorted;
end
if (~isempty(folderPath))
filePaths = cellfun(@(x) [folderPath '\' x], filePaths,'UniformOutput', false);
end
end
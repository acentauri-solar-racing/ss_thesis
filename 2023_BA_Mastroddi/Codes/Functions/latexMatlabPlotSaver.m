function [] = latexMatlabPlotSaver(figureName, varargin)
%Save Matlab plot in the folder name where LaTex has access

% function [] = latexMatlabPlotSaver(figureName, saveFolderName)
% folderPathName = fullfile(saveFolderName, figureName);
% mkdir(folderPathName);
% figure2tikz('fileName', figureName, 'folderpath', folderPathName, 'saveMatlabFig', true, 'overwrite', false);

fig = gcf();
previousVisible = fig.Visible;
fig.Visible = 'on';

groundPath = uiGetDirectory('prompt', 'Select base directory for paper.', 'specifier', 'bachelorThesis');
figure2tikz('folderPath', fullfile(groundPath, 'img', figureName), 'fileName', figureName, 'saveMatlabFig', true, varargin{:})
close
% fig.Visible = previousVisible;

end
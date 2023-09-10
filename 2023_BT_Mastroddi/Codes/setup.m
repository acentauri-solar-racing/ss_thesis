clc
clearvars
close all

run('C:\Users\giaco\Git_Repositories\stpMatlab\matlab\setup.m')

pathThisSetupFile = mfilename('fullpath');
pathMainFolder = fileparts(pathThisSetupFile);
cd(pathMainFolder);

allPaths = split(genpath(pathMainFolder), pathsep());
addpath(strjoin(allPaths, pathsep()));
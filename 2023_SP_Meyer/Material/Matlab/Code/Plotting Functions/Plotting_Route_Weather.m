% This code was written with MATLAB R2022b. Errors may occur with other
% versions
% Written for the Semester Thesis of Severin Meyer (18-926-857) in FS23
%% Initialization:
clc
clear
clearvars
close all

%% Include Paths
addpath(genpath('.\..\'));

LW = 1.5;
LW_Plot = 1.5;
Line_Type = '--';
Line_Type_Red = ':r';
Line_Type_ONS = '--b';
Fond_Size = 15;
Fond_Size_Axis = 10;

Weather_Raw = load('WeatherIrradiance.mat');
Wind_Temp_Raw = load('Weather.mat').weather;
Route_Raw = load('RouteData.mat').route;

% Plotting G
G = Weather_Raw.irradiance.Gtotal([12001:12541, 12001+1*24*60:12541+1*24*60, 12001+2*24*60:12541+2*24*60, 12001+3*24*60:12541+3*24*60, 12001+4*24*60:12541+4*24*60]);
figure('Name','Global irradiance in time domain (Alice Springs)')
t_vec = (0:(length(G)-1))/60;
plot(t_vec,G);
grid on
box on
title('Global irradiance in time domain (Alice Springs)','FontSize',Fond_Size)
xlabel('Time [h]','FontSize',Fond_Size) 
ylabel('G [W/m^2]','FontSize',Fond_Size) 
xlim([0 t_vec(end)])
ylim([0 1300])
set(gca,'FontSize',Fond_Size_Axis)
title('Global irradiance in time domain (Alice Springs)','FontSize',Fond_Size)
xlabel('Race time [h]','FontSize',Fond_Size) 
ylabel('G [W/m^2]','FontSize',Fond_Size) 
% matlab2tikz('G_5Days_BW.tex');

% Plotting Wind
Wind = Wind_Temp_Raw.wind.frontWind(end,:);
figure('Name','Frontal wind in time domain')
plot(4.5:1:20.5,Wind,'DisplayName',"Adelaide",'LineWidth',LW_Plot);
grid on
box on 
xlim([4.5 20.5])
ylim([-6 10])
Wind = Wind_Temp_Raw.wind.frontWind(1,:);
hold on
plot(4.5:1:20.5,Wind,'DisplayName',"Darwin",'LineWidth',LW_Plot);
set(gca,'FontSize',Fond_Size_Axis)
title('Frontal wind in time domain','FontSize',Fond_Size)
xlabel('Time of day [h]','FontSize',Fond_Size) 
ylabel('Wind velocity [m/s]','FontSize',Fond_Size)
legend
%matlab2tikz('Wind.tex');

% Plotting Temp
Temp = Wind_Temp_Raw.temperature.tempMean(end,:);
figure('Name','Temperature in time domain')
plot(4.5:1:20.5,Temp,'DisplayName',"Adelaide",'LineWidth',LW_Plot);
grid on
box on
xlim([4.5 20.5])
ylim([10 35])
Temp = Wind_Temp_Raw.temperature.tempMean(1,:);
hold on
plot(4.5:1:20.5,Temp,'DisplayName',"Darwin",'LineWidth',LW_Plot);
set(gca,'FontSize',Fond_Size_Axis)
title('Temperature in time domain','FontSize',Fond_Size)
xlabel('Time of day [h]','FontSize',Fond_Size)
ylabel('Temperature [°C]','FontSize',Fond_Size) 
legend
%matlab2tikz('Temp.tex');


% Plotting elevation
figure('Name','Elevation in space domain')
plot(Route_Raw.dist/1000,Route_Raw.altiSmooth);
grid on
box on
xlim([0 Route_Raw.dist(end)/1000])
set(gca,'FontSize',Fond_Size_Axis)
title('Elevation in space domain','FontSize',Fond_Size)
xlabel('Distance [km]','FontSize',Fond_Size)
ylabel('Elevation [m]','FontSize',Fond_Size) 
%matlab2tikz('Elevation.tex');

% Plotting max speed
figure('Name','Maximal velocity in space domain')
plot(Route_Raw.dist/1000,Route_Raw.maxSpeed);
grid on
box on
xlim([0 Route_Raw.dist(end)/1000])
ylim([0 40])
set(gca,'FontSize',Fond_Size_Axis)
title('Maximal velocity in space domain','FontSize',Fond_Size)
xlabel('Distance [km]','FontSize',Fond_Size)
ylabel('Maximal velocity [m/s]','FontSize',Fond_Size) 
%matlab2tikz('MaxVelocity.tex');


% Plotting Inclination
figure('Name','Slope of road in space domain')
v1 = Route_Raw.dist;
Route_Raw.dist = round(v1,5);
plot(Route_Raw.dist(1:end-1)/1000,round(rad2deg(Route_Raw.inclSmooth),5));
grid on
box on
xlim([0 Route_Raw.dist(end)/1000])
set(gca,'FontSize',Fond_Size_Axis)
title('Inclination of road in space domain','FontSize',Fond_Size)
xlabel('Distance [km]','FontSize',Fond_Size)
ylabel('Inclination [deg]','FontSize',Fond_Size) 
%matlab2tikz('Inclination.tex');

% Plotting G with solar parameter
G = Weather_Raw.irradiance.Gtotal([30721:31261, 30721+1*24*60:31261+1*24*60, 30721+2*24*60:31261+2*24*60, 30721+3*24*60:31261+3*24*60, 30721+4*24*60:31261+4*24*60]);
figure('Name','Global irradiance in time domain (Alice Springs)')
t_vec = (0:(length(G)-1))/60;
plot(t_vec,G,'DisplayName',"Solar Parameter: "+1);
grid on
box on
xlim([0 t_vec(end)])
ylim([0 1300])
set(gca,'FontSize',Fond_Size_Axis)
title('Global irradiance in time domain (Alice Springs)','FontSize',Fond_Size)
xlabel('Time [h]','FontSize',Fond_Size) 
ylabel('G [W/m^2]','FontSize',Fond_Size) 
hold on
for i = flip(0.2:0.2:0.8)
    plot(t_vec,G*i,'DisplayName',"Solar Parameter: "+i);
    hold on
end
legend
%matlab2tikz('G_Solar_Sweep.tex');

% Plotting G for solar wall
G = 0;
for i = 1:12*60
    if(i>11*60)
        G(i)=1200;
    else
        G(i)=0;
    end
end
figure('Name','Global irradiance in time domain')
t_vec = (0:(length(G)-1))/60;
plot(t_vec,G,'LineWidth',LW,'DisplayName',"Solar Wall Position 1");
grid on
box on
xlim([0 t_vec(end)])
ylim([0 1300])
set(gca,'FontSize',Fond_Size_Axis)
title('Global irradiance in time domain','FontSize',Fond_Size)
xlabel('Time [h]','FontSize',Fond_Size) 
ylabel('G [W/m^2]','FontSize',Fond_Size) 
hold on
for p = 1:5
    G = 0;
    for i = 1:12*60
        if(i>11*60-30*p)
            G(i)=1200;
        else
            G(i)=0;
        end
    end
    plot(t_vec,G,'LineWidth',LW,'DisplayName',"Solar Wall Position "+(p+1));
    hold on
end
legend('Location','northwest')
%matlab2tikz('Solar_Wall2.tex');








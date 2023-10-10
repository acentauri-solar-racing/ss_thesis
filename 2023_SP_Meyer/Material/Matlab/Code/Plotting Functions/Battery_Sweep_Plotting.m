% This code was written with MATLAB R2022b. Errors may occur with other
% versions
% Written for the Semester Thesis of Severin Meyer (18-926-857) in FS23
%% Initialization:
clc
clear
clearvars
close all

%% Include Path of idscDPfunction
addpath(genpath('.\..\'));
%% Getting important data points
SoC_final = [];
t_final = [];
per = [0.2 0.3 0.4 0.5 0.6 0.7 0.8];
k = 1;
for q = 1:length(per)
    name = "Battery_Sweep_"+per(q)+".mat";
    load(name);
    SoC_final(k) = OptRes.states.E_bat(end)/params.E_bat_max;
    t_final(k) = OptRes.states.t(end);
    k = k + 1;
end

%% Plot SoC in Space
per = [0.2 0.3 0.4 0.5 0.6 0.7 0.8];
q = 1;
    name = "Battery_Sweep_"+per(q)+".mat";
    load(name);
    s = params.S_vec;
    E_bat_opt = OptRes.states.E_bat;
    V_opt = OptRes.states.V;
    t_opt = OptRes.states.t;
    P_mot_el_opt = OptRes.inputs.P_mot_el;
% Plotting SoC in Space Domain
    figure('Name','SoC in space domain')
    plot(s/1000,E_bat_opt/params.E_bat_max)
    grid on
    box on
    xlim([0 params.S_final/1000])
    ylim([0 1.1])
    yline(1,'--r')
    yline(0.1,'--r')
    xline(params.CS_vec*10,'--')
    title('SoC in space domain')
    xlabel('Distance [km]') 
    ylabel('SoC [%]') 
    hold on
for q = 2:length(per)
    name = "Battery_Sweep_"+per(q)+".mat";
    load(name);
    s = params.S_vec;
    E_bat_opt = OptRes.states.E_bat;
    V_opt = OptRes.states.V;
    t_opt = OptRes.states.t;
    P_mot_el_opt = OptRes.inputs.P_mot_el;
    plot(s/1000,E_bat_opt/params.E_bat_max)
    hold on
end

%% Plot SoC in Time
per = [0.2 0.3 0.4 0.5 0.6 0.7 0.8];
q = 1;
    name = "Battery_Sweep_"+per(q)+".mat";
    load(name);
    s = params.S_vec;
    E_bat_opt = OptRes.states.E_bat;
    V_opt = OptRes.states.V;
    t_opt = OptRes.states.t;
    P_mot_el_opt = OptRes.inputs.P_mot_el;
% Plotting SoC in Time Domain
    figure ('Name','SoC in time domain')
    plot(t_opt/3600,E_bat_opt/params.E_bat_max)
    grid on
    box on
    ylim([0 1.1])
    xline(params.ONS_times/3600,'--')
    yline(1,'--r')
    yline(0.1,'--r')
    title('SoC in time domain')
    xlabel('Time [h]') 
    ylabel('SoC [%]') 
    hold on
    t_end = OptRes.states.t(end);
for q = 2:length(per)
    name = "Battery_Sweep_"+per(q)+".mat";
    load(name);
    s = params.S_vec;
    E_bat_opt = OptRes.states.E_bat;
    V_opt = OptRes.states.V;
    t_opt = OptRes.states.t;
    P_mot_el_opt = OptRes.inputs.P_mot_el;
    plot(t_opt/3600,E_bat_opt/params.E_bat_max)
    hold on
    if OptRes.states.t(end) > t_end
        t_end = OptRes.states.t(end);
    end
end
 xlim([0 t_end/3600]);

%% Plot Velocity in Time
per = [0.2 0.3 0.4 0.5 0.6 0.7 0.8];
q = 1;
    name = "Battery_Sweep_"+per(q)+".mat";
    load(name);
    s = params.S_vec;
    E_bat_opt = OptRes.states.E_bat;
    V_opt = OptRes.states.V;
    t_opt = OptRes.states.t;
    P_mot_el_opt = OptRes.inputs.P_mot_el;
% Plotting Velocity in Time Domain
    figure ('Name','Velocity in time Domain')
    plot((t_opt(2:end)-t_opt(2))/3600,V_opt(2:end))
    grid on
    box on
    ylim([0 40])
    title('Velocity in time domain')
    xlabel('Time [h]') 
    ylabel('Velocity [m/s]') 
    hold on
    t_end = OptRes.states.t(end);
for q = 2:length(per)
    name = "Battery_Sweep_"+per(q)+".mat";
    load(name);
    s = params.S_vec;
    E_bat_opt = OptRes.states.E_bat;
    V_opt = OptRes.states.V;
    t_opt = OptRes.states.t;
    P_mot_el_opt = OptRes.inputs.P_mot_el;
    plot((t_opt(2:end)-t_opt(2))/3600,V_opt(2:end))
    hold on
    if OptRes.states.t(end) > t_end
        t_end = OptRes.states.t(end);
    end
    xlim([0 t_end/3600]);
end
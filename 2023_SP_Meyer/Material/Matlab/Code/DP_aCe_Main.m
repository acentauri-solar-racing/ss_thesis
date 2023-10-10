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

% sweep_vec = [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9]; % BATTERY SWEEP ---
% for BATTERY_SWEEP = 1:length(sweep_vec) % BATTERY SWEEP ---

% sweep_vec = [1 0.9 0.8 0.7 0.6 0.5 0.4 0.3 0.2 0.1 0]; % SOLAR SWEEP ---
% for SOLAR_SWEEP = 1:length(sweep_vec) % SOLAR SWEEP ---

% sweep_vec = [0.07 0.11]; % PARAMETER SWEEP ---
% for PARAMETER_SWEEP = 1:length(sweep_vec) % PARAMETER SWEEP ---
% 
% sweep_vec = 1:14; % SOLAR WALL ---
% for SOLAR_WALL = 1:length(sweep_vec) % SOLAR WALL ---
%% Getting Parameters
params = table2struct(Load_Parameters());

% for i = 1:length(params.Weather.G) % SOLAR Step ---
%     if( (i >= (sweep_vec(SOLAR_WALL)*(1800/500)) ) && (((sweep_vec(SOLAR_WALL)+1)*(1800/500)) >= i) ) % SOLAR WALL ---
%         params.Weather.G(i) = 1200; % SOLAR WALL ---
%     else % SOLAR WALL ---
%         params.Weather.G(i) = 0; % SOLAR WALL ---
%     end % SOLAR WALL ---
% end % SOLAR Step ---

% for i = 1:length(params.Weather.G) % SOLAR WALL ---
%     if(i > (50400/500 - sweep_vec(SOLAR_WALL)*1800/500)) % SOLAR WALL ---
%         params.Weather.G(i) = 1200; % SOLAR WALL ---
%     else % SOLAR WALL ---
%         params.Weather.G(i) = 0; % SOLAR WALL ---
%     end % SOLAR WALL ---
% end % SOLAR WALL ---

% params.Solar_Sweep_Coef = sweep_vec(SOLAR_SWEEP); % SOLAR SWEEP ---
% params.C_d = sweep_vec(PARAMETER_SWEEP); % PARAMETER SWEEP ---

%% Adding Simulation model
OptPrb = dpaProblem('SolarCarModel_DP',params);

%% Preparing DP
% Creating "Time" vector (working in space domain)
OptPrb.timeVector = params.S_vec;

% Adding states
OptPrb.addStateVariable('E_bat',params.N_E_bat,params.E_bat_max*0.1,params.E_bat_max);
OptPrb.addStateVariable('V',params.N_V,params.V_min/3.6,params.V_max/3.6);
OptPrb.addStateVariable('t',params.N_t,params.t_start,params.t_final);

% Adding input
OptPrb.addInputVariable('P_mot_el',params.N_P_mot_el,params.P_mot_el_min,params.P_mot_el_max); 

% Adding space vector as disturbance
OptPrb.addDisturbance('k',1:length(params.S_vec));

% Adding final state constraints
% OptPrb.setFinalStateConstraint('E_bat',params.E_bat_max*sweep_vec(BATTERY_SWEEP),params.E_bat_max*params.ue_E_bat); % BATTERY SWEEP ---
OptPrb.setFinalStateConstraint('E_bat',params.E_bat_max*params.le_E_bat,params.E_bat_max*params.ue_E_bat);

% Choosing DP settings
OptPrb.useMyGrid = false;
OptPrb.myInf = 10^5;
OptPrb.storeOptInputs = false; % used for plots, consider to set to false for RAM improvements

%% Running backwards DP
OptPrb.solve;

%% Running forwards simulation
OptRes = evaluate(OptPrb,'E_bat',params.E_bat_max,'V',params.V_start/3.6,'t',params.t_start);

% params.sweep_vec = sweep_vec; BATTERY SWEEP ---
% name = "Battery_Sweep_"+sweep_vec(BATTERY_SWEEP)+".mat"; % BATTERY SWEEP ---
% save(name,'OptPrb','OptRes','params'); % BATTERY SWEEP ---
% end % BATTERY SWEEP

% params.sweep_vec = sweep_vec; SOLAR SWEEP ---
% name = "Solar_Sweep_"+sweep_vec(SOLAR_SWEEP)+".mat"; % SOLAR SWEEP ---
% save(name,'OptPrb','OptRes','params'); % SOLAR SWEEP ---
% end % SOLAR SWEEP ---

% params.sweep_vec = sweep_vec; % PARAMETER SWEEP ---
% name = "Cd_Sweep_"+sweep_vec(PARAMETER_SWEEP)+".mat"; % PARAMETER SWEEP ---
% save(name,'OptPrb','OptRes','params'); % PARAMETER SWEEP ---
% end % PARAMETER SWEEP ---

% params.sweep_vec = sweep_vec; % SOLAR WALL ---
% name = "Solar_Block_"+sweep_vec(SOLAR_WALL)+".mat"; % SOLAR WALL ---
% save(name,'OptPrb','OptRes','params'); % SOLAR WALL ---
% end % SOLAR WALL ---

% save("Full_Race_Improved_Weather_20230625_03.mat",'OptRes','params'); % Full RACE ---
%% Plotting results
Plot_Data_DP(OptRes,params.S_vec,params);

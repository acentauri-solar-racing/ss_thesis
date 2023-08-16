%parameters file

%% General
par.s_step = 50;                % [m]
par.s_tot = 300000;             % [m] simulated distance

par.s_final = 2000000;           % [m] total distance (for parameters

par.N_horizon = 20;             % [-] Horizon length

par.v_start = 60/3.6;            % [m/s] Initial Velocity 
par.v_max = 120/3.6;             % [m/s] Largest possible velocity 
par.v_min = 55/3.6;              % [m/s] Smallest possible velocity 

% par.SoC_start = 0.7;
% par.SoC_end = 0.695;

%% Normalization
par.v_0 = 120/3.6;
par.E_bat_0 = 5200*3600;
par.P_mot_el_0 = 5000;
%% Longitudinal Vehicle Dynamics
par.rho_a = 1.17;           % [kg/m^3] air density 
par.Af = 0.8;               % [m^2] frontal area 
par.Cd = 0.09;              % [-] aero drag coeff 
par.Cr = 0.003;             % [-] roll fric coeff 
par.m_tot = 220;            % [kg] total mass 
par.g = 9.81;               % [m/s^2] gravitational acc
par.r_w = 0.2785;           % [m] wheel radius 
par.N_f = 4;                % [-] #front bearings
par.T_f = 0.0550;           % [Nm] friction torque in one front bearing
par.N_r = 1;                % [-] #back bearings
par.T_r = 0.15;             % [Nm] friction torque back bearing
par.m_car = 150;            % [kg] car mass
par.m_driver = 80;          % [kg] driver mass
par.Theta_rot = 1.1343;     % [kgm^2] Moment of Inertia rotating parts

%% Electric Motor
par.gamma_gb = 1;           % [-] transmission gear box
par.e_mot = 0.97;           % [-] Motor efficiency
par.P_0 = 30;               % [W] Idle losses
par.P_el_max = 5000;        % [W] Maximal electric power
par.P_el_min = -5000;       % [W] Minimal electric power
par.T_mot_max = 45;         % [Nm] Maximal Torque
par.T_mot_min = -45;        % [Nm] Minimal Torque

%Photvoltaic Module
par.nu = -3.47;             % [-]
par.kappa = -0.0594;        % [s/m]
par.A_PV = 4;               % [-] solar panel area
par.eta_PV = 0.244;         % [-] solar panel efficiency
par.eta_wire = 0.98;        % [-] wiring efficiency
par.eta_MPPT = 0.99;        % [-] MPPT efficiency
par.eta_mismatch = 0.98;    % [-] Mismatch efficiency
par.theta_STC = 298.15;     % [K] Standard Condition Temperature
par.G_0 = 1000;             % [W/m^2] Reference Global Irradiance
par.lambda_PV = 0.0029;     % [1/K] Power loss coefficient

%% Battery Pack
par.U_bat_oc = 126;         % [V] open circuit voltage
par.R_bat = 0.075;          % [Ohm] Internal Resistance
par.E_bat_max = 5200*3600;  % [W*s = J] Maximal energy capacity
par.I_bat_max = 78.4;       % [A] max current
par.I_bat_min = -39.2;      % [A] min current
par.P_bat_max = 9878.4;     % [W] max power
par.P_bat_min = -4939.4;    % [W] min power
par.SoC_max = 1;            % [-] max safe SoC
par.SoC_min = 0.1;          % [-] min safe SoC
par.eta_coul = 1;           % [-] Coulumbic efficiency

%% Route and Weather 
% Loading Route Data
par.Route = load_route(par.s_step,par.s_final,par);
par.Route.max_v(par.Route.max_v < 16) = 60/3.6;
% Loading Weather Data
% par.Weather = Load_Weather(par);
par.E_bat_target_1000km = load("SoC_target_DP.mat").E_bat*3600 % [W]
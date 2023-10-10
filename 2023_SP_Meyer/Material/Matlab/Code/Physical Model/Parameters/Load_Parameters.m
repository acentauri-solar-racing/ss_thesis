% This code was written with MATLAB R2022b. Errors may occur with other
% versions
% Written for the Semester Thesis of Severin Meyer (18-926-857) in FS23

%% Main function
function P = Load_Parameters()
    % Creating Table
    P = table();
    
    % Adding Parameters
        %% Set for new DP
        % Space
        P.S_start = 0; % Initial distance (m)
        P.S_step = 10000; % Distance step size (m)
        P.S_EF_Step = 200; % Distance step size euler forward (m)
        P.S_final = 800000; % Final distance (m)

        % Battery
        P.ue_E_bat = 1; % Upper end target SoC (%)
        P.le_E_bat = 0.1; % Lower end target SoC (%)
        P.N_E_bat = 20+1; % Number of discretization points for E_bat state

        % Velocity
        P.V_start = 65; % Initial Velocity (km/h)
        P.V_max = 120; % Largest possible velocity (km/h)
        P.V_min = 60; % Smallest possible velocity (km/h)
        P.N_V = 10+1; % Number of discretization points for V state

        % Time
        P.t_start = 0; % Initial time (s)
        P.t_divider = 1000; % Time divider (s)
        P.t_S_divider = 25; % S divider

        % Input
        P.P_mot_el_max = 2600; % Largest possible input (W)
        P.P_mot_el_min = 100; % Smallest possible input (W)
        P.N_P_mot_el = 20+1; % Number of discretization points for input

        %% General
        % DP Setup Space
        P.S_vec = P.S_start:P.S_step:P.S_final; % Space vector

        % DP Setup Time (with CS time augmentation)
        P.t_final = P.S_final/P.t_S_divider ; % Time horizon (s) 
        P.CS_location = [320, 590, 990, 1200, 1500, 1770, 2180, 2440, 2720] * 1000;
        P.CS_vec = [320, 590, 990, 1200, 1500, 1770, 2180, 2440, 2720] * 1000 /P.S_step;
        P.t_final = P.t_final + 1800*(sum(P.CS_location<=P.S_final,'all')); % CS adapted time horizon (s) 
        P.N_t = round(P.t_final/P.t_divider+1); % Number of discretization points for t state
        P.t_vec = linspace(P.t_start,P.t_final,P.N_t); % Time vector
        P.t_step = P.t_vec(2) - P.t_vec(1); % Time step size (s)

        % Solar Sweep Coef
        P.Solar_Sweep_Coef = 1;

        % PV Parameters
        P.A_PV = 4; % PV area (m2)
        P.eta_PV = 0.244; % PV efficiency
        P.eta_wire = 0.98; % PV wire efficiency
        P.eta_MPPT = 0.99; % PV MPPT efficiency
        P.eta_mismatch = 0.98; % PV mismatch
        P.lambda_PV = -0.0029; % Power loss coef (/K);
        P.temp_STC = 25; % Standard-condition temperature (C)

        % P_V_const Parameters
        P.rho = 1.17; % Air density (kg/m3)
        P.A_aero = 0.85; % Frontal aerodynamic area (m2)
        P.C_d = 0.09; % Drag coef
        P.g = 9.8067; % Acceleration of gravity (m/s2)
        P.C_r = 0.003; % Roll friction coef
        P.N_front = 4; % Number for frontal bear rings
        P.N_rear = 1; % Number for rear bear rings
        P.T_front = 0.055; % Front wheels bearing friction moment (Nm)
        P.T_rear = 0.2; % Rear wheels bearing friction moment (Nm)
        P.r_w = 0.2785; % Wheel radius (m)
        P.mass = 240; % Car mass with driver (kg)

        % P_mot_mech Parameters
        P.e_mot = 0.97; % E-motor efficiency
        P.P_0 = 30; % Idle power (W)

        % Battery Parameters
        P.E_bat_max = 5200; % Energy in Battery when fully charged (Wh)

        % Loading Route Data
        P.Route = Load_Route(P.S_step,P.S_final,P);

        % Loading Weather Data
        P.Weather = Load_Weather(P);

        % Over-Night Stops
        P.ONS_E = Load_ONS_E(P); % Energy supplied by ONS (Wh)
        P.ONS_times = [9*3600 9*3600*2 9*3600*3 9*3600*4 9*3600*5];

%         for i = 1:length(P.Weather.G) % SOLAR FULL RACE ---
%             P.Weather.G(i) = 766.46; % SOLAR FULL RACE ---
%         end % SOLAR FULL RACE ---
% 
%         for i = 1:length(P.Weather.G_min) % SOLAR FULL RACE ---
%             P.Weather.G_min(i) = 766.46; % SOLAR FULL RACE ---
%         end % SOLAR FULL RACE ---
% 
%         for i = 1:length(P.Weather.Weather_Raw.Gtotal) % SOLAR FULL RACE ---
%             P.Weather.Weather_Raw.Gtotal(i) = 766.46; % SOLAR FULL RACE ---
%         end % SOLAR FULL RACE ---

        % Control Stops [318, 590, 989, 1195, 1497, 1773, 2184, 2436, 2722, 3027] 
        P.CS_E = Load_CS_E(P); % Energy supplied by CS (Wh)
end
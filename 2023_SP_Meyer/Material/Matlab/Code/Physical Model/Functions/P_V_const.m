% This code was written with MATLAB R2022b. Errors may occur with other
% versions
% Written for the Semester Thesis of Severin Meyer (18-926-857) in FS23

%% Main Function
% P_V_const
function PVC = P_V_const(dpState,params,k)
    % Calculations
    PVC = (F_aero(dpState,params,k) + F_grade(params,k) + F_roll(params,k) + F_bear(params)).* dpState.V;
end

%% Sub-Functions independent of Road and Weather
% F_aero
function FA = F_aero(dpState,params,k)
    % Calculations
    FA = 0.5 .* params.rho .* params.A_aero .* params.C_d .* V_eff_front(dpState,params,k).^2;
end

% F_grade
function FG = F_grade(params,k)
    % Calculations
    FG = params.mass .* params.g .* sin(params.Route.incl(k));
end

% F_roll
function FR = F_roll(params,k)
    % Calculations
    FR = params.mass .* params.g .* params.C_r .* cos(params.Route.incl(k));
end

% F_bear
function FB = F_bear(params)
    % Calculations
    FB = (params.N_front .* params.T_front ./ params.r_w + params.N_rear .* params.T_rear ./ params.r_w);
end


%% Functions dependent on Weather
% V_eff_front
function VE = V_eff_front(dpState,params,k)
    % Calculations
     if (params.N_E_bat == 1)
        [~,closestIndex] = min(abs(params.t_vec-dpState.t(1,1,1,:)));
        V_wind(1,1,1,:) = params.Weather.frontWind(k,closestIndex);
     else
        V_wind = repmat(params.Weather.frontWind(k,:),params.N_E_bat,1,params.N_V,params.N_P_mot_el);
        V_wind = permute(V_wind, [1 3 2 4]);
     end
     VE = dpState.V + V_wind;
end
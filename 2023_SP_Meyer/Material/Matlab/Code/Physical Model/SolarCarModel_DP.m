% This code was written with MATLAB R2022b. Errors may occur with other
% versions
% Written for the Semester Thesis of Severin Meyer (18-926-857) in FS23

%% Main Function
% SolarCarModel_DP
function [dpState, dpCost, dpIsFeasible, dpOutput] = SolarCarModel_DP(dpState, dpInput, dpDisturbance, dpTs, parameters)
    % Choosing integration method (1 or 2)
    n = 2;
    
    % Getting matrix dimensions
    [parameters.N_E_bat, parameters.N_V, parameters.N_t, parameters.N_P_mot_el] = size(dpState.t);

    % Storing t(k) before overwriting it to t(k+1) for ONS condition
    t_min1 = dpState.t;
    
    % Calculating states(k+1)
    switch n
        case 1 % EF_Normal
            % Calculating derivatives
            E_bat_dot = (P_PV(dpState.t,parameters).*parameters.Solar_Sweep_Coef - dpInput.P_mot_el) ./ dpState.V;
            V_dot = (P_mot_mech(dpInput.P_mot_el,parameters) - P_V_const(dpState.V,parameters,dpDisturbance.k))./ ... 
                (parameters.mass.*dpState.V.^2);
            t_dot = 1 ./ dpState.V;

            % Calculating states(k+1)
            dpState.E_bat = dpState.E_bat + E_bat_dot*dpTs/3600;
            dpState.V = dpState.V + V_dot*dpTs;
            dpState.t = dpState.t + t_dot*dpTs;

        case 2 % EF_Substeps
            % Calculating E_bat derivative 
            E_bat_dot = (P_PV(dpState.t,parameters).*parameters.Solar_Sweep_Coef - dpInput.P_mot_el) ./ dpState.V;

            % Calculating E_bat state(k+1)
            dpState.E_bat = dpState.E_bat + E_bat_dot*dpTs/3600;

            for i = 0:parameters.S_EF_Step:(dpTs-parameters.S_EF_Step)
                % Calculating V derivative 
                V_dot = (P_mot_mech(dpInput.P_mot_el,parameters) - P_V_const(dpState,parameters,dpDisturbance.k))./ ... 
                        (parameters.mass.*dpState.V.^2);
                
                % Calculating V state(k+1)
                dpState.V = dpState.V + V_dot*parameters.S_EF_Step;

                % Calculating t derivative 
                t_dot = 1 ./ dpState.V;

                % Calculating t state(k+1)
                dpState.t = dpState.t + t_dot*parameters.S_EF_Step;
            end      
    end

    % Implementing CSs
    if(any(dpDisturbance.k-1 == parameters.CS_vec))
        if (parameters.N_E_bat == 1)
%             t_temp = dpState.t(1,1,1,1);
%             [~,closestIndex] = min(abs(parameters.t_vec-t_temp));
%             CS_Energy = repmat(parameters.CS_E.E(closestIndex),parameters.N_E_bat,1,parameters.N_V,parameters.N_P_mot_el);
%             CS_Energy = permute(CS_Energy, [1 3 2 4]);
            [~,closestIndex] = min(abs(parameters.t_vec-dpState.t(1,1,1,:)));
            CS_Energy(1,1,1,:) = parameters.CS_E.E(closestIndex);
        else
            CS_Energy = repmat(parameters.CS_E.E,parameters.N_E_bat,1,parameters.N_V,parameters.N_P_mot_el);
            CS_Energy = permute(CS_Energy, [1 3 2 4]);
        end
        dpState.E_bat = dpState.E_bat + CS_Energy.*parameters.Solar_Sweep_Coef;
        dpState.t = dpState.t + 1800;
    end

    % Implementing ONSs
    if(parameters.N_E_bat == 1)
        for i = 1:5
            bool = (t_min1 <= parameters.ONS_times(i) & dpState.t > parameters.ONS_times(i));
            dpState.E_bat = dpState.E_bat + bool * parameters.ONS_E.E(i).*parameters.Solar_Sweep_Coef;
        end
    else
        dpState.E_bat = dpState.E_bat + parameters.ONS_E.E_M.*parameters.Solar_Sweep_Coef;
    end

    % Preventing battery overload
    dpState.E_bat(dpState.E_bat > parameters.E_bat_max) = parameters.E_bat_max;

    % Cost
    dpCost = 1./dpState.V;

    % Feasibility
    V_max = parameters.Route.max_V(dpDisturbance.k);
    dpIsFeasible = Constraints(dpState,V_max); % rename

    % Output
    dpOutput = [];

end
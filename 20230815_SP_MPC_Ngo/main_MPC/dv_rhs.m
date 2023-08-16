%right hand side of the velocity state

% INPUT
% par: parameters struct
% states [n_states x 1]: states vector SX.sym('')
% controls [n_controls x 1]: controls vector SX.sym('')
% var [n_vars x 1]: variables vector SX.sym('')

function dv = dv_rhs(par, states, controls, var)
    
    % states x and control u
    v = states(1);              % velocity
    E_bat = states(2);            % state of charge
    P_mot_el = controls(1);     % electric motor power
    P_brake = controls(2);

    % space dependent parameters 
    alpha = var(1);             % road inclination
    G = var(2);                 % irradiation
    v_front = var(3);           % front wind velocity
    v_side = var(4);            % side wind velocity
    theta_amb = var(5);

    v_eff_front = v_front + v;
    v_eff_side = v_side;
    v_eff = sqrt(v_eff_side^2 + v_eff_front^2);

    % longitudinal power losses
    P_a = 0.5* par.rho_a * par.Cd * par.Af * (v_eff_front)^2 * v;                 % aerodynamic loss
    P_g = par.m_tot * par.g * sin(alpha) * v;                                     % inclination loss
    P_r = par.m_tot * par.g * par.Cr * cos(alpha) * v;                            % rolling friction loss
    P_b = (par.N_f * par.T_f / par.r_w + par.N_r * par.T_r / par.r_w) * v;        % bearing loss

    % electric motor traction power
    P_mot_mec = P_mot_mec_sigmoid(P_mot_el, par.e_mot, par.P_0, 0.01);        % smooth and continuous derivable
    %P_mot_mec = P_mot_el .* par.e_mot - par.P_0;
    

    % velocity dynamics
    dv = (P_mot_mec - P_a - P_g - P_r - P_b + P_brake) / (par.m_tot * v);
end



function smooth_fun = P_mot_mec_sigmoid(P_mot_el, e_mot, P_0, k)
    % Sigmoid approximation for the transition step
    sigmoid = 1 ./ (1 + exp(-k * (P_mot_el - P_0)));
    
    % Approximation for y = P_mot_el * a - b if P_mot_el >= b
    part1 = P_mot_el .* e_mot - P_0;
    
    % Approximation for y = P_mot_el / a - b if P_mot_el < b
    part2 = P_mot_el ./ e_mot - P_0;
    
    % Smoothly interpolate between the two parts using the sigmoid
    smooth_fun = sigmoid .* part1 + (1 - sigmoid) .* part2;
end
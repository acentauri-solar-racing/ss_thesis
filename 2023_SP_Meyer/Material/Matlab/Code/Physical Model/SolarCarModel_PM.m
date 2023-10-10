% This code was written with MATLAB R2022b. Errors may occur with other
% versions
% Written for the Semester Thesis of Severin Meyer (18-926-857) in FS23

%% Main Function
% SolarCarModel
function [E_bat_dot,V_dot,t_dot] = SolarCarModel(V,s,t,P_mot_el,params)
    %P_mot_el = P_PV(t,params);
    E_bat_dot = (P_PV(t,params) - P_mot_el) / V;
    V_dot = (P_mot_mech(P_mot_el,params) - P_V_const(V,s,params))/(params.mass*V^2);
    t_dot = 1 / V;
end
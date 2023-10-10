% This code was written with MATLAB R2022b. Errors may occur with other
% versions
% Written for the Semester Thesis of Severin Meyer (18-926-857) in FS23

%% Main Function
% P_mot_mech
function PMM = P_mot_mech(P_mot_el,params)
    % Calculations
        if(P_mot_el >= params.P_0)
            PMM = P_mot_el .* params.e_mot - params.P_0;
        else
            PMM = P_mot_el ./ params.e_mot - params.P_0;
        end
end
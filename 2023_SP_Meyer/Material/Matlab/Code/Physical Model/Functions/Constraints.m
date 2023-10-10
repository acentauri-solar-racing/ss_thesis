% This code was written with MATLAB R2022b. Errors may occur with other
% versions
% Written for the Semester Thesis of Severin Meyer (18-926-857) in FS23

%% Main Function
% Constraints
function Constraints = Constraints(dpState,V_max)
    if (V_max >= 16.67)
        V_con = (dpState.V <= V_max) & (dpState.V > (60/3.6));
    else
        V_con = (dpState.V <= V_max); 
    end
    Constraints = V_con;
end
% This code was written with MATLAB R2022b. Errors may occur with other
% versions
% Written for the Semester Thesis of Severin Meyer (18-926-857) in FS23

%% Main Function
% P_PV
function PPV = P_PV(t,params)
    % Calculations
    PPV = params.A_PV .* get_G(t,params) .* params.eta_PV .* params.eta_wire .* params.eta_MPPT .* params.eta_mismatch .* eta_CF(params);
end



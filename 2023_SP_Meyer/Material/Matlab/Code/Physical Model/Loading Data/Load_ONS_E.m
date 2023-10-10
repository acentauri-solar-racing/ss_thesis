% This code was written with MATLAB R2022b. Errors may occur with other
% versions
% Written for the Semester Thesis of Severin Meyer (18-926-857) in FS23

%% Main Function
function ONS_Energy = Load_ONS_E(params)
    ONS_Energy_vec = zeros(params.N_t,1)';

    for i = 1:5
        ONS_Energy.t(i) = (31261+(i-1)*24*60);

        ONS_E = 0;
        for j = ONS_Energy.t(i):ONS_Energy.t(i)+15*60
            ONS_E = ONS_E + params.A_PV .* params.Weather.Weather_Raw.Gtotal(j) .* params.eta_PV .* params.eta_wire .* params.eta_MPPT .* params.eta_mismatch .* eta_CF(params);
        end
        ONS_Energy.t(i) = (ONS_Energy.t(i)-30721)*60;
        [~,closest_t_index] = min(abs(params.t_vec-ONS_Energy.t(i)));
        ONS_Energy.E(i) = ONS_E/60;
        ONS_Energy_vec(closest_t_index) = ONS_Energy.E(i);
    end

    ONS_Energy.E_M = repmat(ONS_Energy_vec,params.N_E_bat,1,params.N_V,params.N_P_mot_el);
    ONS_Energy.E_M = permute(ONS_Energy.E_M, [1 3 2 4]);
end



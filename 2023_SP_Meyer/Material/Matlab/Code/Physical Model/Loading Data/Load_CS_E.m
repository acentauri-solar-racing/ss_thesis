% This code was written with MATLAB R2022b. Errors may occur with other
% versions
% Written for the Semester Thesis of Severin Meyer (18-926-857) in FS23

%% Main Function
function CS_Energy = Load_CS_E(params)
    for i = 1:length(params.t_vec)
        CS_Energy.t(i) = params.t_vec(i);
        [~,closestIndex] = min(abs(params.t_vec(i)-params.Weather.t_min));

        CS_E = 0;
        for j = closestIndex:closestIndex+29
            CS_E = CS_E + params.A_PV .* params.Weather.G_min(j) .* params.eta_PV .* params.eta_wire .* params.eta_MPPT .* params.eta_mismatch .* eta_CF(params);
        end

        CS_Energy.E(i) = CS_E/60;
    end
end



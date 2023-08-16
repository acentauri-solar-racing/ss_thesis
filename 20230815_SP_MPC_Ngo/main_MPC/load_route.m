% This code was written with MATLAB R2022b. Errors may occur with other
% versions
% Original code for the Semester Thesis of Severin Meyer (18-926-857) in
% FS23, adapted by Tony Ngo (19-915-958) in 27.07.2023

%% Main Function
function Route_Final = load_route(S_step, S_final,par)
    Route_Raw = load('RouteData.mat').route;
    Route_Final = [];
    for i = 0:1:S_final/S_step
        [~,closestIndex_k] = min(abs(i*S_step-Route_Raw.dist));
        [~,closestIndex_k_1] = min(abs((i+1)*S_step-Route_Raw.dist));
        if closestIndex_k < closestIndex_k_1
            Route_Final.incl(i+1) = mean(Route_Raw.inclSmooth(closestIndex_k:(closestIndex_k_1-1)));
            if par.v_max > mean(Route_Raw.maxSpeed(closestIndex_k:(closestIndex_k_1-1)))
                Route_Final.max_v(i+1) = mean(Route_Raw.maxSpeed(closestIndex_k:(closestIndex_k_1-1)));
            else
                Route_Final.max_v(i+1) = par.v_max;
            end
        else
            Route_Final.incl(i+1) = mean(Route_Raw.inclSmooth(closestIndex_k));
            if par.v_max > mean(Route_Raw.maxSpeed(closestIndex_k))
                Route_Final.max_v(i+1) = mean(Route_Raw.maxSpeed(closestIndex_k));
            else
                Route_Final.max_v(i+1) = par.v_max;
            end
        end
        if(Route_Final.max_v(i+1) > 18)
            Route_Final.min_v(i+1) = 60/3.6;
        else
            Route_Final.min_v(i+1) = 40/3.6;
        end
    end
end

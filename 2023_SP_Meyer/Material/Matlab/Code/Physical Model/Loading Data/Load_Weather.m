% This code was written with MATLAB R2022b. Errors may occur with other
% versions
% Written for the Semester Thesis of Severin Meyer (18-926-857) in FS23

%% Main Function
function Weather = Load_Weather(params)
    % Loading data
    Weather_Raw = load('WeatherIrradiance.mat').irradiance;
    Weather_Raw_wt = load('Weather.mat');
    Weather.Weather_Raw = Weather_Raw;
    
    % Getting G Values
    Weather.t_min = (0:5*9*60+4)*60;
    Weather.G_min = Weather_Raw.Gtotal([30721:31261, 30721+1*24*60:31261+1*24*60, 30721+2*24*60:31261+2*24*60, 30721+3*24*60:31261+3*24*60, 30721+4*24*60:31261+4*24*60]);
    for i = 1:length(params.t_vec)
        [~,closestIndex1] = min(abs(params.t_vec(i)-Weather.t_min));
        [~,closestIndex2] = min(abs((params.t_vec(i)+params.t_step)-Weather.t_min));
        Weather.time(i) = params.t_vec(i);
        Weather.G(i) = mean(Weather.G_min(closestIndex1:closestIndex2));
    end

    % Getting Wind Values
    dist_windtemp_raw = Weather_Raw_wt.weather.temperature.dist;
    time_windtemp_raw = (-60*60*3.5:60*60:60*60*12.5);
    time_windtemp_day = (0:1*60:9*60*60);
    time_windtemp_fullrace = (0:1*60:45*60*60);
    Weather.temp = [];
    Weather.frontWind = [];

    for i = 1:length(params.S_vec)
        % Interpolating temperature and wind data to DP space vector
        temp_raw = interp1(dist_windtemp_raw,Weather_Raw_wt.weather.temperature.tempMean,params.S_vec(i));
        wind_raw = interp1(dist_windtemp_raw,[Weather_Raw_wt.weather.wind.frontWind; Weather_Raw_wt.weather.wind.frontWind(end,:)],params.S_vec(i));
        % Interpolating temperature and wind data to one minute time vector
        % running one day
        temp_day = interp1(time_windtemp_raw,temp_raw,time_windtemp_day);
        frontWind_day = interp1(time_windtemp_raw,wind_raw,time_windtemp_day);
        % Stacking data to full race
        temp_fullrace_temp = [temp_day temp_day(2:end) temp_day(2:end) temp_day(2:end) temp_day(2:end)];
        frontWind_fullrace_temp = [frontWind_day frontWind_day(2:end) frontWind_day(2:end) frontWind_day(2:end) frontWind_day(2:end)];
        % Interpolating temperature and wind data to DP time vector
        Weather.temp = [Weather.temp; interp1(time_windtemp_fullrace,temp_fullrace_temp,params.t_vec)];
        Weather.frontWind = [Weather.frontWind; interp1(time_windtemp_fullrace,frontWind_fullrace_temp,params.t_vec)];
    end
end



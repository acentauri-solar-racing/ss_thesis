function irradiance = irradianceInterpolant(time, weatherSim)

persistent interpolantIrradiance

if isempty(interpolantIrradiance)
%     weatherSim = load("WeatherSim.mat").weatherSim;
    interpolantIrradiance = griddedInterpolant(weatherSim.irradiance.timeSec, weatherSim.irradiance.GtotalSec);
end % if

irradiance = interpolantIrradiance(time);
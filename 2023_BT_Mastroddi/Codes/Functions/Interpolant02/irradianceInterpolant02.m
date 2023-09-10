function irradiance = irradianceInterpolant02(time)

persistent interpolantIrradiance

if isempty(interpolantIrradiance)
    weatherSim = load("SimulationData.mat").weatherSim;
    interpolantIrradiance = griddedInterpolant(weatherSim.irradiance.timeSec, weatherSim.irradiance.GtotalSec);
end % if

irradiance = interpolantIrradiance(time);
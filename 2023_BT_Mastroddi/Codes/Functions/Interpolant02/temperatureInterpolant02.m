function temperature = temperatureInterpolant02(time, position)

persistent interpolantTemperature

if isempty(interpolantTemperature)
    weatherSim = load("SimulationData").weatherSim;
    [timeGrid, distGrid] = ndgrid(weatherSim.temperature.timeSec, weatherSim.temperature.dist);
    interpolantTemperature = griddedInterpolant(timeGrid, distGrid, weatherSim.temperature.tempMean');
end % if

temperature = interpolantTemperature(time, position);
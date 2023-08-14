function temperature = temperatureInterpolant(time, position, weatherSim)

persistent interpolantTemperature

if isempty(interpolantTemperature)
    [timeGrid, distGrid] = ndgrid(weatherSim.temperature.timeSec, weatherSim.temperature.dist);
    interpolantTemperature = griddedInterpolant(timeGrid, distGrid, weatherSim.temperature.tempMean');
end % if

temperature = interpolantTemperature(time, position);
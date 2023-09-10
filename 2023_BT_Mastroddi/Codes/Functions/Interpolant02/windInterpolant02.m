function wind = windInterpolant02(time, position)

persistent interpolantWind

if isempty(interpolantWind)
    weatherSim = load("SimulationData").weatherSim;
    [timeGrid, distGrid] = ndgrid(weatherSim.wind.timeSec, weatherSim.wind.dist);
    interpolantWind = griddedInterpolant(timeGrid, distGrid, weatherSim.wind.windMean');
end % if

wind = interpolantWind(time, position);
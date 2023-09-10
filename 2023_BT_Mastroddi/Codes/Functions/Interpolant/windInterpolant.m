function wind = windInterpolant(time, position, weatherSim)

persistent interpolantWind

if isempty(interpolantWind)
    [timeGrid, distGrid] = ndgrid(weatherSim.wind.timeSec, weatherSim.wind.dist);
    interpolantWind = griddedInterpolant(timeGrid, distGrid, weatherSim.wind.windMean');
end % if

wind = interpolantWind(time, position);
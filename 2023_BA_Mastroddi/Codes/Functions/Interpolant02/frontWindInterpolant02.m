function frontWind = frontWindInterpolant02(time, position)

persistent interpolantFrontWind

if isempty(interpolantFrontWind)
    weatherSim = load("SimulationData").weatherSim;
    [timeGrid, distGrid] = ndgrid(weatherSim.wind.timeSec, weatherSim.wind.dist(1:end-1));
    interpolantFrontWind = griddedInterpolant(timeGrid, distGrid, weatherSim.wind.frontWind');
end % if

frontWind = interpolantFrontWind(time, position);
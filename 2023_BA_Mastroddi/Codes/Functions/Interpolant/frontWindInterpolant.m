function frontWind = frontWindInterpolant(time, position, weatherSim)

persistent interpolantFrontWind

if isempty(interpolantFrontWind)
    [timeGrid, distGrid] = ndgrid(weatherSim.wind.timeSec, weatherSim.wind.dist(1:end-1));
    interpolantFrontWind = griddedInterpolant(timeGrid, distGrid, weatherSim.wind.frontWind');
end % if

frontWind = interpolantFrontWind(time, position);
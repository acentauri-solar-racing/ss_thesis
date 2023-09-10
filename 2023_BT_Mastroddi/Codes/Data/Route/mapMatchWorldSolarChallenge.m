clc
clearvars
close all

%% Load data
loadedData = load('DataForFabio.mat').dataForFabio;

%% Visualize raw data
figure
hold on;box on;grid on
plotTrajectory(loadedData.Brouter.long, loadedData.Brouter.lati, 'Brouter')
plotTrajectory(loadedData.weatherData.long, loadedData.weatherData.lati, 'Weather')
plotGeoMap()
clickableLegend()
xlabel('Longitude [°]')
ylabel('Latitude [°]')

%% Perform "Map Matching"
localCoordinateSystem = findLocalProjectionUtm(loadedData.Brouter.lati / 180*pi, loadedData.Brouter.long / 180*pi);

[~, ~, indsFirstToSecond, indsSecondToFirst] = matchGeographicTrajectories(loadedData.Brouter.lati / 180*pi, loadedData.Brouter.long / 180*pi, ...
    loadedData.weatherData.lati / 180*pi, loadedData.weatherData.long / 180*pi, ...
    localCoordinateSystem, true);

%% Calculate interpolation grid

distanceBetweenBrouterPoints = haversine(loadedData.Brouter.lati / 180*pi, loadedData.Brouter.long / 180*pi);
distanceVector = [0; cumsum(distanceBetweenBrouterPoints)];

interpolationTimeVec = (6.5 : 1 : 18.5)' * 3600;
interpolationDistVec = distanceVector(indsFirstToSecond);

%% Create an "artificial" velocity profile
constVelocity = distanceVector(end) / (interpolationTimeVec(end) - interpolationTimeVec(1));
timeProfile = interpolationTimeVec(1):100:interpolationTimeVec(end);
distProfile = constVelocity * (timeProfile - timeProfile(1));

%% Visualize results
figure
subplot(2, 1, 1)
hold on;box on;grid on
plot(distProfile / 1e3, interp2(interpolationTimeVec, interpolationDistVec, loadedData.weatherData.tempMean, 6.5 * 3600, distProfile), 'DisplayName', 'at 06:30')
plot(distProfile / 1e3, interp2(interpolationTimeVec, interpolationDistVec, loadedData.weatherData.tempMean, timeProfile, distProfile), 'DisplayName', sprintf('driving at v_{const} = %.1f m/s', constVelocity))
clickableLegend
xlabel('distance [km]')
ylabel('temperature [C]')

subplot(2, 1, 2)
hold on;box on;grid on
plot(timeProfile / 3600, interp2(interpolationTimeVec, interpolationDistVec, loadedData.weatherData.tempMean, timeProfile, 0), 'DisplayName', 'at start')
plot(timeProfile / 3600, interp2(interpolationTimeVec, interpolationDistVec, loadedData.weatherData.tempMean, timeProfile, distProfile), 'DisplayName', sprintf('driving at v_{const} = %.1f', constVelocity))
clickableLegend
xlabel('time [h]')
ylabel('temperature [C]')


%% functions

function plotTrajectory(long, lat, name)

h = hggroup('DisplayName', sprintf('%s trajectory', name));
h.Annotation.LegendInformation.IconDisplayStyle = 'on';

plot(h, long(1), lat(1), 'go', 'DisplayName', sprintf('%s start', name), 'MarkerSize', 10)
plot(h, long(end), lat(end), 'ro', 'DisplayName', sprintf('%s finish', name), 'MarkerSize', 10)
plot(h, long, lat, 'LineWidth', 2, 'DisplayName', sprintf('%s trajectory', name))


end % function
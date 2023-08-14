clearvars;
close all;

cd("C:\Users\giaco\Git_Repositories\Bachelor_Arbeit\Codes\Data\Weather");
load("WeatherData.mat");
load("WeatherIrradiance.mat");

weather = struct();
weather.irradiance = irradiance;
weather.irradianceTokai = irradianceTokai;
weather.temperature = temperature;
weather.wind = wind;

%% equidistant temperature and wind
distEqui = linspace(temperature.dist(1), temperature.dist(end), length(temperature.dist))';

tempMeanEqui = interp1(temperature.dist, temperature.tempMean, distEqui);
windMeanEqui = interp1(wind.dist, wind.windMean, distEqui);
frontWindEqui = interp1(wind.dist(1:end-1), wind.frontWind, distEqui(1:end-1));
sideWindEqui = interp1(wind.dist(1:end-1), wind.sideWind, distEqui(1:end-1));

%% check conversions
ylimVec = [distEqui(1), distEqui(end)];

%temperature to check if conversion to equidistant is accurate
fig = figure;
set(fig,'defaultAxesColorOrder',[[0 0 0]; [1 0 0]]);
yyaxis left
hold on
plot(temperature.tempMean(:,8), temperature.dist, 'DisplayName', 'Normal distance')
ylim(ylimVec)
xlabel('Temperature [°]');
ylabel('Distance [m]');
clickableLegend
legend('Location','northwest')
grid on
box on
yyaxis right
plot(tempMeanEqui(:,8), distEqui, 'DisplayName', 'Equidistant distance')
ylim(ylimVec)
ylabel('Distance [m]');
hold off

%wind to check if conversion to equidistant is accurate
fig = figure;
set(fig,'defaultAxesColorOrder',[[0 0 0]; [1 0 0]]);
yyaxis left
hold on
plot(wind.windMean(:,8), wind.dist, 'DisplayName', 'Normal distance')
ylim(ylimVec)
xlabel('Wind [m/s]');
ylabel('Distance [m]');
clickableLegend
legend('Location','northwest')
grid on
box on
yyaxis right
plot(windMeanEqui(:,8), distEqui, 'DisplayName', 'Equidistant distance')
ylim(ylimVec)
ylabel('Distance [m]');
hold off

%% data allocation
weather.wind.windMean = windMeanEqui;
weather.wind.frontWind = frontWindEqui;
weather.wind.sideWind = sideWindEqui;
weather.wind.dist = distEqui;

weather.temperature.tempMean = tempMeanEqui;
weather.temperature.dist = distEqui;

%% save data
% save("Weather", "weather")
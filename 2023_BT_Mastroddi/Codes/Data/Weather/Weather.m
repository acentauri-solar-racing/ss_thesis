clearvars;
close all;

cd("C:\Users\giaco\Git_Repositories\Bachelor_Arbeit\Codes\Data\Weather");
load("WeatherData1990_2021.mat");
load("WeatherIrradiance1D.mat");

weather = struct();

weather.irradiance = irradiance;
weather.temperature = temperature;
weather.wind = wind;
weather.irradiance1D = irradiance1D;
weather.irradiance1DTokai = irradiance1DTokai;

%% save data
save("Weather", "weather")
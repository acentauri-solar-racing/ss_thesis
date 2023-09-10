function [weatherSim] = weather2weatherSim(interestDay, enhanceFactor, startInterestDay, stopInterestDay, plotIsRequested)
% Prepare the weather data of irradiance, wind and temperature for the
% interest day, namely by converting all the times in seconds and chop the
% days, so that the nights are taken out.
%
% Input: day of interest as datetime;
%        enhance factor as double: when charging in the morning and in the
%        afternoon, the solar panels are inclined, resulting in more energy
%        convertible. Good values between 1 and 3;
%        startInterestDay as string: "8", "10", or "15minSunrise";
%        stopInterestDay as string: "17" or "15minSunset";
%
% Output: weatherSim as a struct with irradiance, irradiance enhanced, wind
%         temperature data

if ~isa(plotIsRequested, "logical")
    disp("Wrong input type for plotIsRequested: logical")
elseif ~isa(startInterestDay, "string") || ~isa(stopInterestDay, "string")
    disp("Wrong input type for startInterestDay or stopInterestDay: string")
end % if

persistent weather;
toAdd = struct();
weatherSim = struct();

if isempty(weather)
    [~, weather, ~, ~] = loadData();
end % if

%% Irradiance
%Window to recharge with the sun: driving and standing
startDriving_8 = datetime(year(interestDay), month(interestDay), day(interestDay),8,0,0);
startDriving_10 = datetime(year(interestDay), month(interestDay), day(interestDay),10,0,0);
stopDriving_17 = datetime(year(interestDay), month(interestDay), day(interestDay),17,0,0);

switch startInterestDay
    case "8"
        morningStart = startDriving_8;
        startDriving = startDriving_8;
    case "10"
        morningStart = startDriving_10;
        startDriving = startDriving_10;
    case "15minSunrise"
        morningStart = weather.irradiance.bef15minSunrise.datetime(day(interestDay));
        startDriving = startDriving_8;
    otherwise
        disp("Wrong startInterestDay. Either '8' or '15minSunrise'")
end % switch

switch stopInterestDay
    case "17"
        afternoonStop = stopDriving_17;
    case "15minSunset"
        afternoonStop = weather.irradiance.aft15minSunset.datetime(day(interestDay));
    otherwise
        disp("Wrong stopInterestDay. Either '17' or '15minSunset'")
end % switch

horizonOfInterest = weather.irradiance.time >= morningStart & weather.irradiance.time <= afternoonStop;

%Window to recharge with the sun: only driving
horizonDriving = weather.irradiance.time >= startDriving & weather.irradiance.time <= stopDriving_17;
horizonDrivingOpposite = ~horizonDriving;

%Window to recharge with the sun: only standing
horizonIrradianceStop = horizonDrivingOpposite .* horizonOfInterest;

%Corrected total irradiance with inclined panels when standing
horizonIrradianceGtotalCorrected = weather.irradiance.Gtotal.*horizonOfInterest + enhanceFactor*weather.irradiance.Gtotal.*horizonIrradianceStop;

%Time and total irradiance as datetime and W/m^2
horizonTime = weather.irradiance.time(horizonOfInterest);
horizonGtotal = horizonIrradianceGtotalCorrected(horizonOfInterest);
horizon_8_17 = double(horizonDriving(horizonOfInterest));

%Time vector for the simulation in seconds
durationSec = seconds(afternoonStop - morningStart);
weatherSim.irradiance.timeSec = [1:durationSec]';

%Total irradiance vector for the simulation
horizonTimeSec = 60 * [1:length(horizonTime)]' - 60; %time vector of 1 minute = 60 seconds
weatherSim.irradiance.GtotalSec = interp1(horizonTimeSec, horizonGtotal, weatherSim.irradiance.timeSec);

%Boolean vector
weatherSim.irradiance.driving_8_17_Sec = floor(interp1(horizonTimeSec, horizon_8_17, weatherSim.irradiance.timeSec)); %to have only 1 or 0


%% Wind and temperature
%Position vector (simply passed, no change needed)
weatherSim.wind.dist = weather.wind.dist;
weatherSim.temperature.dist = weather.temperature.dist;

%Define working vectors as duration and convert to seconds
weatherDataDurVec = weather.wind.timeDur;
weatherDataDurVecSec = seconds(weatherDataDurVec);

morningStartDur = hours(hour(morningStart)) + minutes(minute(morningStart));
morningStartDurSec = seconds(morningStartDur);
afternoonStopDur = hours(hour(afternoonStop)) + minutes(minute(afternoonStop));
afternoonStopDurSec = seconds(afternoonStopDur);

%Find horizon and create time vector
horizon = weatherDataDurVecSec >= morningStartDurSec & weatherDataDurVecSec <= afternoonStopDurSec;
weatherSim.temperature.timeSec = [morningStartDurSec; weatherDataDurVecSec(horizon); afternoonStopDurSec] - morningStartDurSec;
weatherSim.temperature.timeSec(1,1) = 1; %to correct for simulation
weatherSim.wind.timeSec = weatherSim.temperature.timeSec; %equal for both dataset

%Constant night temperatur and wind for interp2
constNight.tempMean = mean((weather.temperature.tempMean(:,1) + weather.temperature.tempMean(:,end))/2);
constNight.windMean = mean((weather.wind.windMean(:,1) + weather.wind.windMean(:,end))/2);
constNight.frontWind = mean((weather.wind.frontWind(:,1) + weather.wind.frontWind(:,end))/2);
constNight.sideWind = mean((weather.wind.sideWind(:,1) + weather.wind.sideWind(:,end))/2);

%Create toAdd struct where the first and last column for the weather data are saved and added to a chopped data
toAddWeatherNames = fields(weather);
toAddWeatherLen = length(fieldnames(weather));

for k = 1:toAddWeatherLen
    toAddNames = fields(weather.(toAddWeatherNames{k})); %extract temperature and wind
    toAddLen = length(fieldnames(weather.(toAddWeatherNames{k})));

    if toAddWeatherNames{k} == "temperature" || toAddWeatherNames{k} == "wind"
        for i = 1:toAddLen
            sizeTmp = size(weather.(toAddWeatherNames{k}).(toAddNames{i})); %different size: 594 or 595
        
            if sizeTmp(2) > 10 %creating toAdd struct for wind and temperature data of interest
                tmpDistance = linspace(1,sizeTmp(1),sizeTmp(1))'; %distance vector only for interp2

                %interpolation for first and last data of wind and temperature
                toAdd.(toAddNames{i}).first = interp2(weatherDataDurVecSec, tmpDistance, weather.(toAddWeatherNames{k}).(toAddNames{i}), morningStartDurSec, tmpDistance, 'linear', constNight.(toAddNames{i}));
                toAdd.(toAddNames{i}).last = interp2(weatherDataDurVecSec, tmpDistance, weather.(toAddWeatherNames{k}).(toAddNames{i}), afternoonStopDurSec, tmpDistance, 'linear', constNight.(toAddNames{i}));
        
                %chop external valus and add first and last column using toAdd
                if toAddNames{i} == "tempMean"
                    weatherSim.temperature.(toAddNames{i}) = [toAdd.(toAddNames{i}).first, weather.(toAddWeatherNames{k}).(toAddNames{i})(:,horizon), toAdd.(toAddNames{i}).last];
                else %wind data
                    weatherSim.wind.(toAddNames{i}) = [toAdd.(toAddNames{i}).first, weather.(toAddWeatherNames{k}).(toAddNames{i})(:,horizon), toAdd.(toAddNames{i}).last];
                end % if
            end % if
        end % for
    end % if
end % for

%% Check
% sizeTmpTempMean = size(weather.temperature.tempMean);
% tmpDistTempMean = linspace(1,sizeTmpTempMean(1),sizeTmpTempMean(1))';
% toAdd.tempMean.first = interp2(weatherDataDurVecSec, tmpDistTempMean, weather.temperature.tempMean, morningStartDurSec, tmpDistTempMean, 'linear', constNight.tempMean);
% toAdd.tempMean.last = interp2(weatherDataDurVecSec, tmpDistTempMean, weather.temperature.tempMean, afternoonStopDurSec, tmpDistTempMean, 'linear', constNight.tempMean);
% weatherSim.temperature.check = [toAdd.tempMean.first, weather.temperature.tempMean(:,horizon), toAdd.tempMean.last];

%% Plot if requested
if plotIsRequested
    %irradiance to check the horizons
    figure
    hold on
    plot(weather.irradiance.time, weather.irradiance.Gtotal, 'DisplayName', 'Irradiance')
    xline(morningStart, '--k', 'DisplayName', 'morningStart')
    xline(afternoonStop, '--k', 'DisplayName', 'afternoonStop')
    plot(weather.irradiance.time, 500*horizonOfInterest, 'DisplayName', 'horizonOfInterest')
    plot(weather.irradiance.time, 500*horizonDriving, 'DisplayName', 'horizonDriving')
    plot(weather.irradiance.time, 500*horizonDrivingOpposite, 'DisplayName', 'horizonDrivingOpposite')
    plot(weather.irradiance.time, 500*horizonIrradianceStop, 'DisplayName', 'horizonIrradianceStop')
    ylabel('Global irradiance [W/m^2]');
    clickableLegend
    legend()
    grid on
    box on
    hold off

    %irradiance to check if conversion to second is accurate
    fig = figure;
    set(fig,'defaultAxesColorOrder',[[0 0 0]; [1 0 0]]);
    yyaxis left
    hold on
    plot(horizonGtotal, horizonTime, 'DisplayName', 'Time')
    ylim([horizonTime(1), horizonTime(end)]);
    xlabel('Global irradiance [W/m^2]');
    ylabel('Time [s]');
    clickableLegend
    legend('Location','west')
    grid on
    box on
    yyaxis right
    plot(weatherSim.irradiance.GtotalSec, weatherSim.irradiance.timeSec, 'DisplayName', 'Simulation time')
    ylim([weatherSim.irradiance.timeSec(1), weatherSim.irradiance.timeSec(end)]);
    plot(horizonGtotal, horizonTimeSec, 'DisplayName', 'Simulation time horizon')
    ylim([horizonTimeSec(1), horizonTimeSec(end)]);
    ylabel('Simulation time [s]');
    hold off

%     %temperature to check interp2
%     figure
%     [DURVEC, DIST] = meshgrid(weatherDataDurVec, weather.temperature.dist);
%     hold on
%     surf(DIST/1000, DURVEC, weather.temperature.tempMean, 'DisplayName', 'Temperature')
%     surf(DIST, DURVEC, weather.temperature.tempMean.*repelem(horizon',595,1), 'DisplayName', 'Temperature horizon')
%     plot3(weather.temperature.dist, repelem(morningStartDur, length(weather.temperature.dist), 1), repelem(30, length(weather.temperature.dist), 1), 'r', 'DisplayName', 'Start')
%     plot3(weather.temperature.dist, repelem(afternoonStopDur, length(weather.temperature.dist), 1), repelem(30, length(weather.temperature.dist), 1), 'r', 'DisplayName', 'Stop')
%     xlabel('Distance [km]');
%     ylabel('Time [hr]');
%     zlabel('Temperature [°]');
%     clickableLegend
%     legend()
%     grid on
%     box on
%     hold off

    %temperature to check bounds and conversion to seconds
    fig = figure;
    set(fig,'defaultAxesColorOrder',[[0 0 0]; [1 0 0]]);
    yyaxis left
    hold on
    plot(weather.temperature.tempMean(1,:)', weatherDataDurVec, 'DisplayName', 'Time')
    ylim([weatherDataDurVec(1), weatherDataDurVec(end)]);
    xlabel('Temperature [°]');
    ylabel('Time [hr]');
    clickableLegend
    legend('Location','northwest')
    grid on
    box on
    yyaxis right
    plot(weather.temperature.tempMean(1,:)', weatherDataDurVecSec, 'DisplayName', 'Simulation time')
    yline(morningStartDurSec, '--b', 'DisplayName', 'Start')
    yline(afternoonStopDurSec, '--b', 'DisplayName', 'Stop')
    ylim([weatherDataDurVecSec(1), weatherDataDurVecSec(end)]);
    ylabel('Simulation time [s]');
    hold off

    %temperature to check simulation values
    fig = figure;
    set(fig,'defaultAxesColorOrder',[[0 0 0]; [1 0 0]]);
    yyaxis left
    hold on
    plot(weather.temperature.tempMean(1,:)', weatherDataDurVec(:,1), 'DisplayName', 'Time')
    ylim([morningStartDur, afternoonStopDur]);
    xlim([min(weatherSim.temperature.tempMean(1,:)), max(weatherSim.temperature.tempMean(1,:))])
    xlabel('Temperature [°]');
    ylabel('Time [hr]');
    clickableLegend
    legend('Location','northwest')
    grid on
    box on
    yyaxis right
    plot(weatherSim.temperature.tempMean(1,:)', weatherSim.temperature.timeSec, 'DisplayName', 'Simulation time')
    ylim([weatherSim.temperature.timeSec(1), weatherSim.temperature.timeSec(end)]);
    ylabel('Simulation time [s]');
    hold off

end % if
end % fct

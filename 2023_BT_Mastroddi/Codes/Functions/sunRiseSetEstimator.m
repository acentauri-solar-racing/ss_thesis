function [bef15Sunrise, sunrise, sunset, aft15Sunset] = sunRiseSetEstimator(interestDay)
% Estimate sunrise and sunset time of the day of interest by looking at the
% irradiance data
% 
% Input: interestDay as datetime
% 
% Output: sunrise and sunset time, as well as 15 min before sunrise and 15
%         after sunset time. All as datetime

persistent weather;

if isempty(weather)
    [~, weather, ~, ~] = loadData();
end % if

dur15min = minutes(15);
%Find sunrise and sunset times
chosenDay = day(weather.irradiance.time) == day(interestDay);
chosenDayTime = weather.irradiance.time(chosenDay);

sun = weather.irradiance.Gtotal(chosenDay) > 0;

indexSunrise = find(diff(sun) == 1, 1, 'first');
indexSunset = find(diff(sun) == -1, 1, 'last') + 1; %corrected due to function diff definition

bef15Sunrise = chosenDayTime(indexSunrise) - dur15min;
sunrise = chosenDayTime(indexSunrise);
sunset = chosenDayTime(indexSunset);
aft15Sunset = chosenDayTime(indexSunset) + dur15min;

end % fct
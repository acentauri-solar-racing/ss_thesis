function [timeOpt, velMeanOpt] = optimalTimeVelocityEstimator(Eloss, Ebudget)
% Return the intersection between the energy loss vector and the energy
% budget vector
% 
% Input: Eloss as double vector
%        Ebudget as double vector
% 
% Output: optimal time as double
%         optimal velocity as double

persistent driver;

if isempty(driver)
    [~, ~, ~, driver] = loadData();
end % if

timeOpt = find(Eloss <= Ebudget, 1, 'first');
fprintf('Optimal driving time: %3.2f h \n', timeOpt / 3600)

velMeanOpt = driver.finishLocDist / timeOpt;
fprintf('Optimal velocity: %3.2f km/h', velMeanOpt * 3.6)

end % fct
%--------------------------------------------------------------------------
%   ETH Zurich, IDSC, Project: dpa
%--------------------------------------------------------------------------
%
%   Calculate corrected values between boundary line and closest state point
%
%   [corrValues_btwL, corrValues_btwU, betweenLower, betweenUpper] = calcBoudaryCorrection(obj, nextStateGrids, Values_next, endUpStateGrids, k)
%
%   Inputs:     OptPrb              Optimization problem as a dpaProblem
%               nextStateGrids      State grid (cell array)
%               Values_next         Values at next time step (cell array)
%               endUpStateGrids     Sample points (cell array)
%               k                   time step
%
%   Outputs:    corrCost_btwL       Corrected cost at lower boundary line
%               corrCost_btwU       Corrected cost at upper boundary line
%               betweenLower        Indices with corrected cost at lower boundary line
%               betweenUpper        Indices with corrected cost at upper boundary line
%
%
%   Authors:
%   Hansi Ritzmann      (JR)    jritzman@ethz.ch
%   Stijn van Dooren    (SV)    stijnva@ethz.ch
%   Andreas Ritter      (AR)    anritter@idsc.mavt.ethz.ch
%   Dario Nastasi       (DN)    nastasid@ethz.ch
%   Hokwang Choi        (HC)    hochoi@ethz.ch
%   Kerim Barhoumi      (KB)    bkerim@ethz.ch
%   Ashwin Sandeep      (AS)    asandeep@student.ethz.ch
%
%   Revision:
%   12.05.2022  KB  Method created based on existing code

function [corrValues_btwL, corrValues_btwU, betweenLower, betweenUpper] = calcBoundaryCorrection(obj, nextStateGrids, Values_next, endUpStateGrids, k)

% Interpolate end-up-states taking into account the boundary line
if strcmp(obj.boundaryMethod,'line') && obj.useMyGrid

    % Extract boundary line properties
    upperLine = obj.boundaryVars.upper.x(k+1);
    upperCost = obj.boundaryVars.upper.J(k+1);
    lowerLine = obj.boundaryVars.lower.x(k+1);
    lowerCost = obj.boundaryVars.lower.J(k+1);

    % Find grid point just inside boundary line
    lowestFeas = find(nextStateGrids{1} > lowerLine,1,'first');
    highestFeas = find(nextStateGrids{1} < upperLine,1,'last');

    % Find grid end-up-states between boundary line and closest state to boundary line
    betweenLower = find(endUpStateGrids{1} <= nextStateGrids{1}(lowestFeas) & ...
                        endUpStateGrids{1} >= lowerLine);
    betweenUpper = find(endUpStateGrids{1} >= nextStateGrids{1}(highestFeas) & ...
                        endUpStateGrids{1} <= upperLine);

    % Interpolate corrected costs taking the boundary line into account
    corrValues_btwL = interpn([lowerLine, nextStateGrids{1}(lowestFeas)], ...
                            [lowerCost, Values_next(lowestFeas)], ...
                            endUpStateGrids{1}(betweenLower));

    corrValues_btwU = interpn([nextStateGrids{1}(highestFeas),upperLine], ...
                            [Values_next(highestFeas), upperCost], ...
                            endUpStateGrids{1}(betweenUpper));

end % if
end % function

% EOF
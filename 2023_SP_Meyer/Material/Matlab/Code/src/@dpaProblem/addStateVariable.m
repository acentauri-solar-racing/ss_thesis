%--------------------------------------------------------------------------
%   ETH Zurich, IDSC, Project: dpa
%--------------------------------------------------------------------------
%
%   Add state variable to optimization problem as dpaStateVar. This defines
%   the grids which are used to solve the problem.
%
%   addStateVariable(OptPrb, varName, nGridPoints, minValue, maxValue)
%
%   Inputs:     OptPrb          Optimization problem as a dpaProblem
%               varName         String containing the name of the state
%               nGridPoints     Number of sampling points
%               minValue        Lower limit as sclar or vector
%               maxValue        Upper limit as sclar or vector
%
%   See also dpaProblem/ADDINPUTVARIABLE, dpaProblem/ADDDISTURBANCE

%   Authors:
%   Hansi Ritzmann      (JR)    jritzman@ethz.ch
%   Stijn van Dooren    (SD)    stijnva@ethz.ch
%   Andreas Ritter      (AR)    anritter@idsc.mavt.ethz.ch
%   Dario Nastasi       (DN)    nastasid@ethz.ch
%   Hokwang Choi        (HC)    hochoi@ethz.ch
%   Ashwin Sandeep      (AS)    asandeep@student.ethz.ch
%
%   Revision:
%   14.02.2019  DN  created
%   16.01.2020  SD  improved pre-processing of state limits
%   10.06.2021  AS  moved checks for upper/lower bound to dpaEveryVar.m
%   10.06.2021  AS  deleted extension of scalar limits as this is unnecessary

function addStateVariable(obj, varName, nGridPoints, minValue, maxValue)
% Add the variable to the system and simultaneously ensure that the name
% has not been used before.
assert(all(~strcmp({obj.stateVars.name},varName)),... 
    'dpa:dpaProblem:StateAlreadyUsed','State name is already used');

% Define the new state variable
obj.stateVars(end+1) = dpaStateVar(varName,nGridPoints, minValue, maxValue);

end % function

% EOF
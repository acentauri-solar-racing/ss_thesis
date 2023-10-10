%--------------------------------------------------------------------------
%   ETH Zurich, IDSC, Project: dpa
%--------------------------------------------------------------------------
%
%   This function sets the final state constraint with a given variable
%   name and min/max values.
%
%   setFinalStateConstraint(OptPrb, varName, minFinalVal, maxFinalVal)
%
%   Inputs:     OptPrb          Optimization problem as a dpaProblem
%               varName         String containing the name of the state
%               minFinalVal     Minimal value of terminal set
%               maxFinalVal     Maximal value of terminal set
%
%   See also dpaProblem/ADDSTATEVARIABLE, dpaProblem/SETINITIALSTATE

%   Authors:
%   Hansi Ritzmann      (JR)    jritzman@ethz.ch
%   Stijn van Dooren    (SV)    stijnva@ethz.ch
%   Andreas Ritter      (AR)    anritter@idsc.mavt.ethz.ch
%   Dario Nastasi       (DN)    nastasid@ethz.ch
%   Hokwang Choi        (HC)    hochoi@ethz.ch
%   Ashwin Sandeep      (AS)    asandeep@student.ethz.ch
%
%   Revision:
%   14.02.2019  DN  created
%   16.06.2021  AS  index of state variable found here rather than using findVariable.m
%   16.06.2021  AS  added additional assert to check state limits for robustness
%   02.07.2021  AS  state targets set together using a function rather than separate set methods

function setFinalStateConstraint(obj, varName, minFinalVal, maxFinalVal)
% Find the index of the given state variable.
allVarNamesOfThisType = {obj.stateVars.name};
ind = find(strcmp(allVarNamesOfThisType, varName));
assert(isscalar(ind), 'dpa:UnknownVariable', ...
    'There is no state variable %s.', varName);
[obj.stateVars(ind).targetMin, obj.stateVars(ind).targetMax] = ...
    set_target(obj.stateVars(ind),minFinalVal, maxFinalVal);
end % function
%--------------------------------------------------------------------------
%   ETH Zurich, IDSC, Project: dpa
%--------------------------------------------------------------------------
%
%   Get state limits.
%
%   [minState, maxState] = getStateLimit(OptPrb)
%
%   Inputs:     OptPrb      Optimization problem as dpaProblem
%
%   Outputs:    minState   Lower limit as cell for each state
%               maxState   Upper limit as cell for each state
%
%   See also dpaProblem/GETSTATEVARS, dpaProblem/GETINPUTVARS

%   Authors:
%   Hansi Ritzmann      (JR)    jritzman@ethz.ch
%   Stijn van Dooren    (SV)    stijnva@ethz.ch
%   Andreas Ritter      (AR)    anritter@idsc.mavt.ethz.ch
%   Dario Nastasi       (DN)    nastasid@ethz.ch
%   Hokwang Choi        (HC)    hochoi@ethz.ch
%
%   Revision:
%   14.02.2019  DN  created

function [minState, maxState] = getStateLimit(OptPrb)
    minState = cell(1,length(OptPrb.stateVars));
    maxState = cell(1,length(OptPrb.stateVars));
    
    for iState = 1:length(OptPrb.stateVars)
        minState{iState} = OptPrb.stateVars(iState).min;
        maxState{iState} = OptPrb.stateVars(iState).max;
    end
end
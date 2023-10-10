%--------------------------------------------------------------------------
%   ETH Zurich, IDSC, Project: dpa
%--------------------------------------------------------------------------
%
%   Get input limits.
%
%   [minState, maxState] = getInputLimit(OptPrb)
%
%   Inputs:     OptPrb      Optimization problem as dpaProblem
%
%   Outputs:    minState   Lower limit as cell for each input
%               maxState   Upper limit as cell for each input
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

function [minInput, maxInput] = getInputLimit(OptPrb)
    minInput = cell(1,length(OptPrb.inputVars));
    maxInput = cell(1,length(OptPrb.inputVars));
    
    for iInput = 1:length(OptPrb.inputVars)
        minInput{iInput} = OptPrb.inputVars(iInput).min;
        maxInput{iInput} = OptPrb.inputVars(iInput).max;
    end
end
%--------------------------------------------------------------------------
%   ETH Zurich, IDSC, Project: dpa
%--------------------------------------------------------------------------
%
%   Checking whether state targets are feasible.
%
%   targetIsAllowed = isStateTargetFeasible(obj, stateGrids)
%
%   Inputs:     obj                 dpaStateVar which contains the 
%                                   terminal state
%               stateGrids          Terminal state grids
%
%   Outputs:    targetIsAllowed     Boolean indicating which target states 
%                                   are allowed
%
%   See also dpaStateVar/ISSTATEFEASIBLE, dpaProblem/GETFINALCONSTRCOST

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

function targetIsAllowed = isStateTargetFeasible(obj, stateGrids)
targetIsAllowed = [];

for iVar = 1:length(obj)
    % Get the grid of this state variable.
    thisVarName = obj(iVar).name;
    thisVarGrid = stateGrids.(thisVarName);
    
    % Compare the current grid to the limits.
    stateIsAboveLimit = thisVarGrid > obj(iVar).targetMax;
    stateIsBelowLimit = thisVarGrid < obj(iVar).targetMin;
    stateIsFeasible = (~stateIsAboveLimit & ~stateIsBelowLimit);
    
    % Speed up the computation time by removing the need to preassign the
    % full size of the variable targetIsAllowed.
    if iVar == 1
        targetIsAllowed = stateIsFeasible;
    else
        targetIsAllowed = (targetIsAllowed & stateIsFeasible);
    end % if
end % for
end % function
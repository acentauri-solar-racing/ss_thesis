%--------------------------------------------------------------------------
%   ETH Zurich, IDSC, Project: dpa
%--------------------------------------------------------------------------
%
%   Checking whether states are feasible.
%
%   gridPointIsFeasible = isStateFeasible(obj, stateGrids, k)
%
%   Inputs:     obj                     dpaStateVar which contains the 
%                                       information about the current state
%               stateGrids              Current state grids
%               k                       time step k
%
%   Outputs:    gridPointIsFeasible     Boolean indicating which states are
%                                       feasible
%
%   See also dpaStateVar/ISSTATETARGETFEASIBLE

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
%   14.07.2019  HC  time step k is introduced to solve the object copy problem

function gridPointIsFeasible = isStateFeasible(obj, stateGrids, k)
gridPointIsFeasible = [];

for iState = 1:length(obj)
    if isscalar(obj(iState).max) && isscalar(obj(iState).min)
        stateIsAboveLimit = stateGrids{iState} > obj(iState).max;
        stateIsBelowLimit = stateGrids{iState} < obj(iState).min;
    else
        stateIsAboveLimit = stateGrids{iState} > obj(iState).max(k);
        stateIsBelowLimit = stateGrids{iState} < obj(iState).min(k);
    end
    stateIsFeasible = (~stateIsAboveLimit & ~stateIsBelowLimit);
    
    if iState == 1
        gridPointIsFeasible = stateIsFeasible;
    else
        gridPointIsFeasible = (gridPointIsFeasible & stateIsFeasible);
    end % if
end % for
end % function
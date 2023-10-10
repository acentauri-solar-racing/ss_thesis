%--------------------------------------------------------------------------
%   ETH Zurich, IDSC, Project: dpa
%--------------------------------------------------------------------------
%
%   Generate costs corresponding to terminal state constraint, i.e. 
%   indicator function where the cost for all state values within the 
%   feasible terminal set are zero and all others are myInf.
%
%   gN = getFinalConstrCost(obj,myInf)
%
%   Inputs:     obj         Optimization problem as a dpaProblem
%               myInf       Customizable infinity
%
%   Outputs:    gN          Final cost as vector
%
%   See also dpaProblem/getFinalConstrCost_levelset

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
%   30.06.2021  AS  replaced createDPGridVars with createDPGrids and moved to dpaProblem


function gN = getFinalConstrCost(obj)
sizeStateGrids = [obj.stateVars.nGridPoints];
if length(obj.stateVars) == 1
    gN = zeros(sizeStateGrids,1,'like',obj.myInf);
else
    gN = zeros(sizeStateGrids,'like',obj.myInf);
end

% Create grids of state variables.
final_time = cellfun(@length, {obj.stateVars(:).max});
stateGrids = createDPGrids(obj, max(final_time), 'states', 'arrays');
% Set initial cost to infinity outside of target region.
gN(~isStateTargetFeasible(obj.stateVars, stateGrids)) = obj.myInf;
end % function
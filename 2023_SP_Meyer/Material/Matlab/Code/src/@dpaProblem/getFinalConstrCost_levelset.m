%--------------------------------------------------------------------------
%   ETH Zurich, IDSC, Project: dpa
%--------------------------------------------------------------------------
%
%   Generate costs for terminal state where all states within the terminal
%   set are zero and all others grow linearly as proposed in the paper
%   using Euclidean distance.
%
%   gN = getFinalCost_levelset(obj)
%
%   Inputs:     obj         Optimization problem as a dpaProblem
%
%   Outputs:    gN          Final cost as vector
%
%   See also dpaProblem/getFinalConstrCost

%   Authors:
%   Hansi Ritzmann      (JR)    jritzman@ethz.ch
%   Stijn van Dooren    (SV)    stijnva@ethz.ch
%   Andreas Ritter      (AR)    anritter@idsc.mavt.ethz.ch
%   Dario Nastasi       (DN)    nastasid@ethz.ch
%   Hokwang Choi        (HC)    hochoi@ethz.ch
%   Ashwin Sandeep      (AS)    asandeep@student.ethz.ch
%
%   Revision:
%   20.06.2019  HC  created
%   30.06.2021  AS  replaced createDPGridVars with createDPGrids and moved to dpaProblem

function gN = getFinalConstrCost_levelset(obj)
sizeStateGrids = [obj.stateVars.nGridPoints];
if length(obj.stateVars) == 1
    gN = zeros(sizeStateGrids,1);
else
    gN = zeros(sizeStateGrids);
end

% Create grids of state variables.
final_time = cellfun(@length, {obj.stateVars(:).max});
stateGrids = createDPGrids(obj, max(final_time), 'states', 'arrays');
% Get the terminal target constraints.
Min = [obj.stateVars(:).targetMin];
Max = [obj.stateVars(:).targetMax];

% Get the points which are not in the terminal set.
for i = 1:length(obj.stateVars)
    current_grids = stateGrids.(obj.stateVars(i).name);
    out_of_targetSet = current_grids(~isStateTargetFeasible(obj.stateVars, stateGrids));
    whole_grids(:,i) = out_of_targetSet; %#ok<AGROW>
end

Min = kron(Min, ones(length(out_of_targetSet),1));
Max = kron(Max, ones(length(out_of_targetSet),1));

% Calculate the minimum distance from the terminal set.
lower = Min-whole_grids;
upper = whole_grids-Max;
lower(lower <= 0 & upper <= 0) = 0;
upper(upper <= 0 & upper <= 0) = 0;
out_of_set = lower + upper;

% Euclidean distance.
min_dist = vecnorm(out_of_set')';

% Assign values to the terminal cost function
gN(~isStateTargetFeasible(obj.stateVars, stateGrids)) = min_dist;
end % function
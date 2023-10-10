%--------------------------------------------------------------------------
%   ETH Zurich, IDSC, Project: dpa
%--------------------------------------------------------------------------
%
%   Calculate boundary line. Works only for single state problems.
%
%   [upper, lower] = calcBoundaryLine(OptPrb)
%
%   Inputs:     OptPrb      Optimization problem as dpaProblem
%
%   Outputs:    upper       Struct containing upper boundary line with
%                           members Line and Cost
%               lower       Struct containing lower boundary line with
%                           members Line and Cost
%
%   See also dpaProblem/INVMODEL

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
%   14.02.2019  DN  created
%   28.05.2019  HC  revision(bug fix for the wrong indexing)
%   12.06.2019  HC  revision(Time-varying inputs considered)
%   24.01.2021  KB  Extend dpInput & dpState to full dimensions
%                   (1 ... x n_u1 x n_u2 x ...) for the model function call,
%                   reduce after the results to (n_u1 x n_u2 x ...)
%   08.02.2021  KB  Modifications for model function vector inputs.
%   26.02.2021  JR  Bug fix (allow use of constant disturbance)
%   14.04.2021  JR  Fix bug in cost calculation when using terminal state cost
%   03.05.2021  JR  Fix bug in input calculation (allow for more than 1 input)
%   16.06.2021  AS  Deleted calculating inputs for boundary line as this is no
%                   longer required due to deletion of allContiforwardFun.m
%   30.06.2021  AS  Replaced createDPGridVars with createDPGrids

function [upper, lower] = calcBoundaryLine(obj)
% Initialize progress display
if obj.showVerbose
    fprintf('Calculating boundary line. Please wait... %3i%% ',0);
end % if

% Determine problem length
N = length(obj.timeVector);

% Initialize boundary lines
if all([obj.stateVars(:).stateIsConst])
    upper.Line = obj.stateVars.max*ones(1,N);
    lower.Line = obj.stateVars.min*ones(1,N);
    stateMax = upper.Line;
    stateMin = lower.Line;
else
    upper.Line = obj.stateVars.max';
    lower.Line = obj.stateVars.min';
    stateMax = upper.Line;
    stateMin = lower.Line;
end
upper.Cost = zeros(1,N);
lower.Cost = zeros(1,N);

% Set target for final time step
upper.Line(N) = obj.stateVars.targetMax;
lower.Line(N) = obj.stateVars.targetMin;
maxStateCell = {upper.Line(N)};
minStateCell = {lower.Line(N)};

% Initialize structs for model function
dpMaxState = cell2struct(maxStateCell,{obj.stateVars.name},2);
dpMinState = cell2struct(minStateCell,{obj.stateVars.name},2);

% Initialize disturbance for each time step
currentDstrbCell = cell(1,length(obj.dstrbVars));

% Calculate final state cost
if ~isempty(obj.finalStateCostFcn)
    upper.Cost(end) = obj.finalStateCostFcn(upper.Line(N));
    lower.Cost(end) = obj.finalStateCostFcn(lower.Line(N));
end

for k = fliplr(1:N-1)
    dpTs = obj.timeVector(k+1) - obj.timeVector(k);
    
    % Extract current disturbance
    for d = 1:length(obj.dstrbVars)
        if isscalar(obj.dstrbVars(d).signal)
            currentDstrbCell{d} = obj.dstrbVars(d).signal;
        else
            currentDstrbCell{d} = obj.dstrbVars(d).signal(k);
        end
    end % for
    currentDstrb = cell2struct(currentDstrbCell,{obj.dstrbVars(:).name},2);
    
    if obj.vectorMode
        % vector inputs to model function
        dpInput = createDPGrids(obj, k, 'inputs','vectors');
        
        % Invert all inputs from upper and lower limit from previous time step
        [dpMaxState, dpCostUpper, dpFeasibleMax] = invModel(obj,dpMaxState,dpInput,currentDstrb,dpTs);
        [dpMinState, dpCostLower, dpFeasibleMin] = invModel(obj,dpMinState,dpInput,currentDstrb,dpTs);
    else
        % full dimensional matrices inputs to model function
        dpInput = createDPGrids(obj, k, 'inputs','arrays');
        inputCell = struct2cell(dpInput);
        
        % extend dpState to full dimension with ones in input dimensions
        % corresponds to size(dpInput)
        dpMaxState_extend = structfun(@(field)repmat(field,size(inputCell{1})),dpMaxState,'UniformOutput',false);
        dpMinState_extend = structfun(@(field)repmat(field,size(inputCell{1})),dpMinState,'UniformOutput',false);

        % Invert all inputs from upper and lower limit from previous time step
        [dpMaxState, dpCostUpper, dpFeasibleMax] = invModel(obj,dpMaxState_extend,dpInput,currentDstrb,dpTs);
        [dpMinState, dpCostLower, dpFeasibleMin] = invModel(obj,dpMinState_extend,dpInput,currentDstrb,dpTs);
    end % if vectorMode
    
    % Create grids
    maxStateCell = struct2cell(dpMaxState);
    minStateCell = struct2cell(dpMinState);
    
    % Extract feasible states
    maxFeasible = maxStateCell{1} <= stateMax(k);
    minFeasible = minStateCell{1} >= stateMin(k);
    
    % Out of the feaslible states, extract max/min states
    [maxState, indMax] = max(maxStateCell{1}(dpFeasibleMax&maxFeasible));
    [minState, indMin] = min(minStateCell{1}(dpFeasibleMin&minFeasible));
    
    % If there are no feasible states, set costs to myInf
    if isempty(indMax)
        if ~any(dpFeasibleMax(:))
                error('Problem is infeasible');
        else
            maxStateCell{1} = max(maxStateCell{1}(dpFeasibleMax));
            upper.Cost(k) = obj.myInf;
        end
        
    % Else set state to the maximum and take input and cost-to-go accordingly
    else
        thisCost = dpCostUpper(dpFeasibleMax&maxFeasible);
        upper.Cost(k) = upper.Cost(k+1) + thisCost(indMax);
        maxStateCell{1} = maxState;
    end % if
    
    % Same procedure for lower boundary line
    if isempty(indMin)
        if ~any(dpFeasibleMin(:))
                error('Problem is infeasible');
        else
        minStateCell{1} = min(minStateCell{1}(dpFeasibleMin));
        lower.Cost(k) = obj.myInf;
        end
    else
        thisCost = dpCostLower(dpFeasibleMin&minFeasible);
        lower.Cost(k) = lower.Cost(k+1) + thisCost(indMin);
        minStateCell{1} = minState;
    end % if
    
    % Ensure that maximum cost is myInf
    if upper.Cost(k) > obj.myInf
        upper.Cost(k) = obj.myInf;
    end
    if lower.Cost(k) > obj.myInf
        lower.Cost(k) = obj.myInf;
    end % if
    
    % Make sure that states are within bounds
    maxStateCell{1} = min([maxStateCell{1},stateMax(k)]);
    minStateCell{1} = max([minStateCell{1},stateMin(k)]);
    
    % Extend boundary line
    upper.Line(k) = maxStateCell{1};
    lower.Line(k) = minStateCell{1};
    
    % Create structs for next time step
    dpMaxState = cell2struct(maxStateCell,{obj.stateVars.name},2);
    dpMinState = cell2struct(minStateCell,{obj.stateVars.name},2);
    
    % Display progress
    if obj.showVerbose
        fprintf('\b\b\b\b\b%3i%% ', round((N-k)/(N-1)*100));
    end % if
    
end % for

% Display finished calculations
if obj.showVerbose
    % fprintf('\b\b\b\b\bdone\r');
    fprintf('\n\n');
end % if

end % function

% EOF
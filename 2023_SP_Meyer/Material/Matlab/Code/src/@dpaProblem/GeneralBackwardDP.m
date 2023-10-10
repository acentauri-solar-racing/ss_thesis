%--------------------------------------------------------------------------
%   ETH Zurich, IDSC, Project: dpa
%--------------------------------------------------------------------------
%
%   This backward function is designed to apply the DP-algorithm to the
%   general case and evaluates the optimal control law for every state
%   and every time step.
%   Here is a list of what the function should be able to handle:
%   - variable timesteps                [done]
%   - timevariant disturbance           [done]
%   - variable state limits:            
%       - fixed grid on                 [done]
%       - fixed grid off                [done]
%    - variable inputs values for:
%       - continuous                    [done]
%       - discrete                      [done]
%   - boundary line                     [done]
%
%   [J, optInputs] = GeneralBackwardDP(obj)
%
%   Inputs:     obj             Optimization problem as a dpaProblem
%
%   Outputs:    J               Cost-to-go for all time steps and states
%               optInputs       Optimal inputs for all time steps 
%                               and states
%
%   See also dpaProblem/LevelsetMethodBackwardDP

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
%   12.06.2019  HC  revision(include time-varying input limits)
%   02.02.2021  KB  Modifications for model function vector inputs
%   20.02.2021  KB  Modification of dimension check
%   21.02.2021  KB  Changes to thisState for interpolations with 3+ states
%   14.04.2021  JR  Fix incomplete implmentation of final state cost
%   17.05.2021  AS  J and indOptInputs calculated directly rather than
%                   using minOverInputs (deleted function) 
%   17.05.2021  AS  Disturbance signal generated using getDstrbVars.m rather
%                   than createDPTimeVars.m (deleted function)
%   30.06.2021  AS  Replaced output indOptInputs with optInputs
%   30.06.2021  AS  Replaced createDPGridVars with createDPGrids and createDPGridsBackward
%   15.12.2021  JR  Update conditions for using simple method (allow
%                   constant disturbance and 'Line' with useMyGrid)
%   22.02.2022  JR  Update cost-to-go interpolation of simple method to
%                   account for the boundary line with UseMyGrid
%   10.05.2022  KB  Add input regularisation for simple method

function [J, optInputs] = GeneralBackwardDP(obj)
% In this function, any variable with the prefix "this" refers to the 
% current time step k, the prefix "next" the time step k+1.

% Initialize progress display
if obj.showVerbose
    Nmsg = obj.displayProgressMessage(0,0,inf,'backwards',0);
end % if

% Determine problem length
N = length(obj.timeVector);

% Get full dimensions
full_dim1 = [obj.stateVars(:).nGridPoints];
full_dim2 = [obj.inputVars(:).nGridPoints];
full_dim = [full_dim1 full_dim2];

% Create current state variables
if obj.useMyGrid || ~strcmp(obj.boundaryMethod,'line')
    thisStateGrids = struct2cell(createDPGrids(obj, N, 'states','arrays'));
else
    thisStateGrids = {linspace(obj.boundaryVars.lower.x(end),obj.boundaryVars.upper.x(end),obj.stateVars.nGridPoints)};
end
if obj.vectorMode
    if obj.useMyGrid || ~strcmp(obj.boundaryMethod,'line')
        thisStateVectors = struct2cell(createDPGrids(obj, N, 'states', 'vectors'));
        % reshape vector-matrices to col-vectors for interpolations
        thisStateVectors = cellfun(@(x) reshape(x,[numel(x),1]),thisStateVectors,'UniformOutput',false);
    else
        thisStateVectors = {linspace(obj.boundaryVars.lower.x(end),obj.boundaryVars.upper.x(end),obj.stateVars.nGridPoints)};
    end
end

% Initialize disturbance for each timestep
currentDstrbCell = cell(1,length(obj.dstrbVars));

% Initialize cell of cost matrices
if ~isempty(obj.finalStateCostFcn)
    if obj.useMyGrid || ~strcmp(obj.boundaryMethod,'line')
        gN = min( obj.finalStateCostFcn(thisStateGrids{:}) + getFinalConstrCost(obj), obj.myInf );
    else
        boundaryGrids = linspace(obj.stateVars.targetMin, obj.stateVars.targetMax, obj.stateVars.nGridPoints);
        gN = obj.finalStateCostFcn(boundaryGrids);
    end
else
    if obj.useMyGrid || ~strcmp(obj.boundaryMethod,'line')
        gN = getFinalConstrCost(obj);
    else
        gN = zeros([obj.stateVars.nGridPoints],1,'like',obj.myInf);
    end
end
J = [cell(1, N-1), gN];

% Initialize cell of optimal input indices
cell_dim = [1,1];
cell_dim(1:length(full_dim1)) = full_dim1;
optLastInput = cell(length(obj.inputVars),1);
for i = 1:length(obj.inputVars)
    optLastInput{i,1} = repmat(obj.inputVars(i).lastInput,cell_dim);
end
optInputs = [cell(1, N-1), {optLastInput}];

% When time steps, state grids, and input grids are fixed, there is no
% disturbance or the disturbance is constant, use the Simple method.
% (if the boundary method is used useMyGrid==true must hold)
% Simple method : call model function just once
if max(diff(obj.timeVector))- min(diff(obj.timeVector))<300*eps && all([obj.stateVars(:).stateIsConst])...
        && all([obj.inputVars(:).inputIsConst]) && (isempty(obj.dstrbVars) || all([obj.dstrbVars(:).dstrbIsConst])) ...
        && (~strcmp(obj.boundaryMethod,'line') || obj.useMyGrid)
    
    % Initialize cell array of optimal input indices
    indOptInputs = cell(1, N-1);
    
    % Call model function only once with the constant sample time and constant disturbance
    dpTs = mean(diff(obj.timeVector));
    
    % Generate grids for state variables and input variables
    if obj.vectorMode
        [dpState, dpInput] = createDPGridsBackward(obj, 1, 'vectors');
    else
        [dpState, dpInput] = createDPGridsBackward(obj, 1, 'arrays');
    end
    
    % Generate disturbance signals
    dpDstrb = getDstrbVars(obj);
    
    % Call model function
    [dpStateNew, dpCost, dpIsFeasible, ~] = obj.modelFunction(dpState, ...
        dpInput, dpDstrb, dpTs, obj.modelParameters);
    % Check order of states in dpStateNew
    dpStateNew = orderfields(dpStateNew,{obj.stateVars(:).name});
    
    % Check dimensions of dpStateNew, dpCost & dpIsFeasible
    dpStateNewDimCheck = structfun(@(x) (all(size(x) == full_dim)),dpStateNew,'UniformOutput',false);
    cellfun(@(x) assert(x,'Model function returned not full dimensional dpStateNew.'),...
        struct2cell(dpStateNewDimCheck),'UniformOutput',false);
    assert(all(size(dpCost) == full_dim),'Model function returned not full dimensional dpCost.');
    assert(all(size(dpIsFeasible) == full_dim),'Model function returned not full dimensional dpIsFeasible.');
    
    % Identify where the model ends up after that iteration
    endUpStateGrids = struct2cell(dpStateNew);
    
    % Manipulate the cost such that infeasible states are respected
    gridPointIsFeasible = isStateFeasible(obj.stateVars, endUpStateGrids, 1);
    dpCost(~dpIsFeasible | ~gridPointIsFeasible) = obj.myInf;

    % Check that dpCost is not NaN
    assert(~any(isnan(dpCost(:))),'Model function returned NaN as stage cost.');
    
    % Create interpolant for cost-to-go (NaNs are going to be replaced)
    if length(obj.stateVars) == 1
        dummyValues = nan(1,[obj.stateVars.nGridPoints]);
        Interpolant = griddedInterpolant(thisStateGrids{1}, dummyValues);
    else
        dummyValues = nan([obj.stateVars.nGridPoints]);
        Interpolant = griddedInterpolant(thisStateGrids{:}, dummyValues);
    end
    
    % extract boundary line
    if strcmp(obj.boundaryMethod,'line')
        upperLine = obj.boundaryVars.upper.x;
        upperCost = obj.boundaryVars.upper.J;
        lowerLine = obj.boundaryVars.lower.x;
        lowerCost = obj.boundaryVars.lower.J;
    end
    
    % Time loop (Intermediate calculation step for time indices N-1 to 1)
    mytimer = tic;
    for k = fliplr(1:N-1)
        % Replace the values of the interpolant with the current cost-to-go
        Interpolant.Values = J{k+1};
        
        % Manipulate the cost such that infeasible states are respected
        if strcmp(obj.boundaryMethod,'line')
            stateIsAboveLimit = endUpStateGrids{1} > upperLine(k+1);
            stateIsBelowLimit = endUpStateGrids{1} < lowerLine(k+1);
            gridPointIsFeasible = (~stateIsAboveLimit & ~stateIsBelowLimit);
            dpCostCorr = dpCost;
            dpCostCorr(~gridPointIsFeasible) = obj.myInf;
        else
            dpCostCorr = dpCost;
        end % if
        
        % Add the interpolated cost of the last iteration to the cost-to-go
        JFull = dpCostCorr + Interpolant(endUpStateGrids{:});

        % Calc corrected cost taking into account the boundary line & useMyGrid
        if strcmp(obj.boundaryMethod,'line') && obj.useMyGrid
            [corrCost_btwL, corrCost_btwU, betweenLower, betweenUpper] = calcBoundaryCorrection(obj, thisStateGrids, J{k+1}, endUpStateGrids, k);
            JFull(betweenLower) = corrCost_btwL + dpCostCorr(betweenLower);
            JFull(betweenUpper) = corrCost_btwU + dpCostCorr(betweenUpper);
        end

        % Add input-regularisation cost
        J_reg = calcRegCost(obj, dpInput, thisStateGrids, optInputs{k+1}, endUpStateGrids, k);
        JFull = JFull + J_reg;

        % Limit the maximum cost to the customizable infinity cost
        JFull(JFull > obj.myInf) = obj.myInf;
        % NaNs occur when an element of endUpStateGrids is outside the nextStateGrids
        JFull(isnan(JFull)) = obj.myInf;
        
        % Find the minimum cost-to-go.
        JFull = reshape(JFull, [full_dim1, prod(full_dim2)]);
        [J{k}, indOptInputs{k}] = min(JFull, [], ndims(JFull));
        
         if obj.storeOptInputs == true
            % extract optimal inputs
            [StateDims{1:length(obj.stateVars)}] = obj.stateVars(:).nGridPoints;
            [InputDims{1:length(obj.inputVars)}] = obj.inputVars(:).nGridPoints;
            InputDims = cellfun(@(x)1:x,InputDims,'UniformOutput',false);
            if obj.vectorMode
                % get subscripts from linear index
                [InputVecIdx{1:length(obj.inputVars)}] = ind2sub(full_dim2,indOptInputs{k});
            end
            for Ind = 1:length(obj.inputVars)
                 if obj.vectorMode
            %        vector mode
                     optInp.(obj.inputVars(Ind).name) = reshape(dpInput.(obj.inputVars(Ind).name)(InputVecIdx{Ind}),size(indOptInputs{k}));
                else
            %        array mode
                     InputGrid = dpInput.(obj.inputVars(Ind).name)(StateDims{:},InputDims{:});
                     optInp.(obj.inputVars(Ind).name) = reshape(InputGrid(indOptInputs{k}),size(indOptInputs{k}));
                 end
            end
            optInputs{k} = struct2cell(optInp);
        else
            optInputs{k} = [];
        end
        
        % catch infeasible problem
        assert( any(J{k}(:)<obj.myInf), ...
            'dpa:BackwardInfeasible', ...
            sprintf('Infeasible problem detected during backward calculation (k=%0.0f).',k) );
        
        % Display progress
        pctComplete = (N-k)/(N-1)*100;
        avgCalcTime = toc(mytimer)/(N-k);
        estTimeRemaining = avgCalcTime*(k-1);
        if obj.showVerbose
            Nmsg = obj.displayProgressMessage(pctComplete,...
                avgCalcTime,estTimeRemaining,'backwards',Nmsg);
        end % if
    end % for
    
else % general case
    % Time loop (Intermediate calculation step for time indices N-1 to 1)
    mytimer = tic;
    
    % In vector mode, replace grids with vectors
    if obj.vectorMode
        thisStateGrids = thisStateVectors;
    end
    
    for k = fliplr(1:N-1)
        dpTs = obj.timeVector(k+1) - obj.timeVector(k);
        
        % Keep this grids and state variables from previous time step as next
        % grids and state variables
        nextStateGrids = thisStateGrids;

        % Update the state variables only when the limits are time-varying
        if ~all([obj.stateVars(:).stateIsConst]) || ~(obj.useMyGrid || ~strcmp(obj.boundaryMethod,'line'))
            if ~(obj.useMyGrid || ~strcmp(obj.boundaryMethod,'line'))
                thisStateGrids = {linspace(obj.boundaryVars.lower.x(k),...
                    obj.boundaryVars.upper.x(k), obj.stateVars.nGridPoints)};
                
                % Vector mode: calculate dpState directly
                if obj.vectorMode
                    dpState = struct(obj.stateVars(:).name, thisStateGrids{1}');
                end
            else
                if obj.vectorMode
                    thisStateGrids = struct2cell(createDPGrids(obj, k, 'states', 'vectors'));
                    % reshape vector-matrices to col-vectors for interpolations
                    thisStateGrids = cellfun(@(x) reshape(x,[numel(x),1]),thisStateGrids,'UniformOutput',false);
                else
                    thisStateGrids = struct2cell(createDPGrids(obj, k, 'states','arrays'));
                 end
            end
        end % if
        
        % Generate grids for state variables and input variables.
        if ~all([obj.stateVars(:).stateIsConst]) || ~all([obj.inputVars(:).inputIsConst]) ||...
                ~(obj.useMyGrid || ~strcmp(obj.boundaryMethod,'line')) || ~exist('dpState','var')
            if ~(obj.useMyGrid || ~strcmp(obj.boundaryMethod,'line')) && ~obj.vectorMode
                if ~all([obj.inputVars(:).inputIsConst]) || ~exist('dpInput','var')
                    thisInputGrids = arraygrid(obj.inputVars, k);
                end

                % Regenerate dpState & dpInput as one of them probably changed
                if iscell(thisInputGrids) % multiple inputs
                    dpInput_grids = cell(size(thisInputGrids));
                    [dpState_grid, dpInput_grids{:}] = ndgrid(thisStateGrids{1}, thisInputGrids{:});
                    dpState = struct(obj.stateVars(:).name, dpState_grid);
                    dpInput = cell2struct(dpInput_grids, {obj.inputVars.name}, 2);
                else % single input
                    [dpState_grid, dpInput_grid] = ndgrid(thisStateGrids{1},thisInputGrids);
                    dpState = struct(obj.stateVars(1).name, dpState_grid);
                    dpInput = struct(obj.inputVars(1).name, dpInput_grid);
                end % if iscell
            elseif ~(obj.useMyGrid || ~strcmp(obj.boundaryMethod,'line')) && obj.vectorMode
                % Vector mode
                % calculate only dpInput (dpState already exists)
                dpInput = createDPGrids(obj, k, 'inputs', 'vectors');
            else
                if obj.vectorMode
                    [dpState, dpInput] = createDPGridsBackward(obj, k, 'vectors');
                else
                    [dpState, dpInput] = createDPGridsBackward(obj, k, 'arrays');
                end
            end
        end % if

        % Extract current disturbance
        if ~all([obj.dstrbVars(:).dstrbIsConst])
            for d = 1:length(obj.dstrbVars)
                if length(obj.dstrbVars(d).signal)==1
                    currentDstrbCell{d} = obj.dstrbVars(d).signal;
                else
                    currentDstrbCell{d} = obj.dstrbVars(d).signal(k);
                end
            end % for
            currentDstrb = cell2struct(currentDstrbCell,{obj.dstrbVars(:).name},2);
        elseif ~exist('currentDstrb','var')
            for d = 1:length(obj.dstrbVars)
                currentDstrbCell{d} = obj.dstrbVars(d).signal(end);
            end % for
            currentDstrb = cell2struct(currentDstrbCell,{obj.dstrbVars(:).name},2);
        end % if

        % run backward function
        [J{k}, optInputs{k}] = generalBackwardFun(obj, dpState, ...
            dpInput, currentDstrb, dpTs, nextStateGrids, J{k+1}, k, optInputs{k+1});
        
        % catch infeasible problem
        assert( any(J{k}(:)<obj.myInf), ...
            'dpa:BackwardInfeasible', ...
            sprintf('Infeasible problem detected during backward calculation (k=%0.0f).',k) );
        
        % Display progress
        pctComplete = (N-k)/(N-1)*100;
        avgCalcTime = toc(mytimer)/(N-k);
        estTimeRemaining = avgCalcTime*(k-1);
        if obj.showVerbose
            Nmsg = obj.displayProgressMessage(pctComplete,...
                avgCalcTime,estTimeRemaining,'backwards',Nmsg);
        end % if
        
    end % for
end % if

% Display finished calculations
if obj.showVerbose
    obj.displayProgressMessage(100,avgCalcTime,toc(mytimer),'backwards',Nmsg);
    fprintf('\nDP backwards done\r');
    fprintf('\n');
end % if

end % function

% EOF
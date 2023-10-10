%--------------------------------------------------------------------------
%   ETH Zurich, IDSC, Project: dpa
%--------------------------------------------------------------------------
%
%   This backward function is designed to apply the DP-algorithm to the
%   level set method case and evaluates the optimal control law for every 
%   state and every time step.
%   Here is a list of what the function should be able to handle:
%   - variable timesteps                [done]
%   - timevariant disturbance           [done]
%   - variable state limits:            
%       - fixed grid on                 [done]
%       - fixed grid off                [done]
%    - variable inputs values for:
%       - continuous                    [done]
%       - discrete                      [done]
%   - level set method                  [done]
%
%   [J, I, optInputs] = LevelsetMethodBackwardDP(obj)
%
%   Inputs:     OptPrb          Optimazition problem as a dpaProblem
%
%   Outputs:    J               Cost-to-go for all time steps and states
%               I               level set values for all time steps and
%                               states
%               optInputs       Optimal inputs for all time steps 
%                               and states
%
%   See also dpaProblem/GeneralBackwardDP

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
%   20.06.2019  HC  created
%   01.02.2021  KB  Modifications for model function vector inputs
%   20.02.2021  KB  Changes to thisState for interpolations with 3+ states
%   14.04.2021  JR  Fix incomplete implementation of final state cost
%   10.06.2021  AS  Levelset function is initialized here (levelset_function_init is deleted)
%   30.06.2021  AS  Replaced output indOptInputs with optInputs
%   30.06.2021  AS  Replaced createDPGridVars with createDPGrids and createDPGridsBackward
%   24.05.2022  KB  Add assert for not implemented input regularisation

function [J, I, optInputs] = LevelsetMethodBackwardDP(obj)
% In this function, any variable with the prefix "this" refers to the 
% time step k , the prefix "next" the time step k+1.

% Assert for not implemented input regularisation
sumWeights = 0;
for i = 1:length(obj.inputVars)
    sumWeights = sumWeights + sum(obj.inputVars(i).weight(:));
end
assert(sumWeights == 0,'Input regularisation not implemented for levelset method!')

% Initialize progress display
if obj.showVerbose
    Nmsg = obj.displayProgressMessage(0,0,inf,'backwards',0);
end % if

% Determine problem length
N = length(obj.timeVector);

% Current state variable and state grid
thisStateGrids = struct2cell(createDPGrids(obj, N, 'states','arrays'));
if obj.vectorMode
    thisStateVectors = struct2cell(createDPGrids(obj, N, 'states','vectors'));
    % reshape vector-matrices to col-vectors for interpolations
    thisStateVectors = cellfun(@(x) reshape(x,[numel(x),1]),thisStateVectors,'UniformOutput',false);
end


% Initialize disturbance for each timestep
currentDstrbCell = cell(1,length(obj.dstrbVars));

% Initialize cell of cost matrices and optimal input indices.
if ~isempty(obj.finalStateCostFcn)
    gN = min( obj.finalStateCostFcn(thisStateGrids{:}) + getFinalConstrCost_levelset(obj), obj.myInf );
else
    gN = min( getFinalConstrCost_levelset(obj), obj.myInf );
end
J = [cell(1, N-1), gN];

% Get the terminal target constraints.
Min = [obj.stateVars(:).targetMin];
Max = [obj.stateVars(:).targetMax];

% Create grids of state variables.
levelset_N = cellfun(@length, {obj.stateVars(:).max});
stateGrids = createDPGrids(obj, max(levelset_N), 'states','arrays');

% Reshape the grid into vector and evaluate the level-set function.
for i = 1:length(obj.stateVars)
    current_grids = stateGrids.(obj.stateVars(i).name);
    whole_grids(:,i) = current_grids(:); %#ok<AGROW>
end

Min = kron(Min, ones(length(current_grids(:)),1));
Max = kron(Max, ones(length(current_grids(:)),1));

% Assign values to the terminal cost function.
h_x = max([max(Min-whole_grids,[],2),max(whole_grids-Max,[],2)],[],2);
h_x = reshape(h_x, size(current_grids));
I=[cell(1, N-1),h_x];

optInputs = cell(1, N-1);

% In vector mode, replace grids with vectors
if obj.vectorMode
    thisStateGrids = thisStateVectors;
end

% Time loop (Intermediate calculation step for time indices N-1 to 1)
mytimer = tic;
for k = fliplr(1:N-1)
    dpTs = obj.timeVector(k+1) - obj.timeVector(k);
    
    % Update state variable, input variable and state grids backwardly.
    nextStateGrids = thisStateGrids;
    
    % Update state variables only when the limits are time-varying
    if ~all([obj.stateVars(:).stateIsConst])
        if obj.vectorMode
            thisStateGrids = struct2cell(createDPGrids(obj, k, 'states','vectors'));
            % reshape vector-matrices to col-vectors for interpolations
            thisStateGrids = cellfun(@(x) reshape(x,[numel(x),1]),thisStateGrids,'UniformOutput',false);
        else
            thisStateGrids = struct2cell(createDPGrids(obj, k, 'states','arrays'));
        end
    end % if
    
    % Generate grids for state variables and input variables.
    if ~all([obj.stateVars(:).stateIsConst]) || ~all([obj.inputVars(:).inputIsConst]) || ~exist('dpState','var')
        if obj.vectorMode
            [dpState, dpInput] = createDPGridsBackward(obj, k, 'vectors');
        else
            [dpState, dpInput] = createDPGridsBackward(obj, k, 'arrays');
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

    % Update cost-to-go & level set function
    [J{k}, I{k}, optInputs{k}] = levelsetBackwardFun(obj, dpState, dpInput, ...
        currentDstrb, dpTs, nextStateGrids, I{k+1}, J{k+1}, k);
    
    % Display progress
    pctComplete = (N-k)/(N-1)*100;
    avgCalcTime = toc(mytimer)/(N-k);
    estTimeRemaining = avgCalcTime*(k-1);
    if obj.showVerbose
        Nmsg = obj.displayProgressMessage(pctComplete,...
            avgCalcTime,estTimeRemaining,'backwards',Nmsg);
    end % if
    
end % for

% Display finished calculations
if obj.showVerbose
    obj.displayProgressMessage(100,avgCalcTime,toc(mytimer),'backwards',Nmsg);
    fprintf('\nDP backwards done\r');
    fprintf('\n');
end % if

end % function

% EOF
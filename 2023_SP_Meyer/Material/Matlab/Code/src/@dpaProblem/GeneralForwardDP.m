%--------------------------------------------------------------------------
%   ETH Zurich, IDSC, Project: dpa
%--------------------------------------------------------------------------
%
%   This forward function is designed to apply the DP-algorithm to the 
%   general case and evaluates the optimal state trajectory, cost-to-go and
%   inputs.
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
%   [J, X, U, D, dpOutput] = GeneralForwardDP(obj, dpStateInit)
%
%   Inputs:     obj             Optimization problem as a dpaProblem object
%               dpStateInit     Inital state as a struct 
%
%   Outputs:    J               Cost-to-go for all time steps along the
%                               optimal trajectory
%               X               Optimal state trajectory
%               U               Optimal inputs
%               D               Disturbance
%               dpOutputs       Outputs from modle function
%
%   See also dpaProblem/LevelsetMethodForwardDP

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
%   28.05.2019  HC  revision(cost-to-go should not have NaN values)
%   12.06.2019  HC  revision(Time-varying inputs considered)
%   05.02.2020  JR  remove indOptInputs and add D
%   24.03.2020  JR  use allDiscreteForwardFun as soon as a single input is
%                   discrete (partialContiForwardFun removed)
%   24.01.2021  KB  Replace call of createDPGridVars to get dpInput with
%                   all state- and input-dimensions (1 ... x n_u1 x n_u2 x ...)
%   05.02.2021  KB  Modifications for model function vector inputs
%   16.06.2021  AS  Deleted differentiating between continuous and discrete inputs
%                   as same forward function is used irrespective of input type
%   30.06.2021  AS  replaced createDPGridVars with createDPGrids
%   07.07.2021  AS  moved function to dpaProblem and deleted pol as input
%                   argument as part of OptPrb/OptPol fusion
%   08.07.2021  AS  deleted calculation of the variable thisStateGrids as it is unused

function [J, X, U, D, dpOutput] = GeneralForwardDP(obj, dpStateInit)
% In this function, any variable with the prefix "this" refers to the 
% current time step k, the prefix "next" the time step k+1.

% Initialize progress display
if obj.showVerbose
    Nmsg = obj.displayProgressMessage(0,0,inf,'forwards',0);
end % if

% Determine problem length
N = length(obj.timeVector);

% Create appropriate state grids
if ~(obj.useMyGrid || ~strcmp(obj.boundaryMethod,'line'))
    nextStateGrids = {linspace(obj.boundaryVars.lower.x(1),...
        obj.boundaryVars.upper.x(1), obj.stateVars.nGridPoints)};
else
    nextStateGrids = struct2cell(createDPGrids(obj, 1, 'states', 'arrays'));
end

dpState = dpStateInit;

% Initialize cell of optimal cost matrices, states, inputs,  disturbances, 
% and dpOutputs
J = cell(1, N);
X = cell(1, N);
U = cell(1, N-1);
D = cell(1, N-1);
dpOutput = cell(1, N-1);

% Store initial state
X{1} = dpState;

% Initialize disturbance
currentDstrbCell = cell(1,length(obj.dstrbVars));

% Time loop (Intermediate calculation step for time indices 1 to N-1)
mytimer = tic;
for k = 1:N-1
    dpTs = obj.timeVector(k+1) - obj.timeVector(k);
    
    % Update state variables only when the limits are time-varying
    if ~all([obj.stateVars(:).stateIsConst]) || ~(obj.useMyGrid || ~strcmp(obj.boundaryMethod,'line'))
        if ~(obj.useMyGrid || ~strcmp(obj.boundaryMethod,'line'))
            nextStateGrids = {linspace(obj.boundaryVars.lower.x(k+1),...
                obj.boundaryVars.upper.x(k+1), obj.stateVars.nGridPoints)};
        else
            nextStateGrids = struct2cell(createDPGrids(obj, k+1, 'states','arrays'));
        end
    end
    
    % Generate grids for input variables
    if ~all([obj.inputVars(:).inputIsConst]) || ~exist('dpInput','var')
        if obj.vectorMode
            dpInput = createDPGrids(obj, k, 'inputs','vectors');
        else
            dpInput = createDPGrids(obj, k, 'inputs','arrays');
        end
        inputCell = struct2cell(dpInput);
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
            currentDstrbCell{d} = obj.dstrbVars(d).signal(1);
        end % for
        currentDstrb = cell2struct(currentDstrbCell,{obj.dstrbVars(:).name},2);
    end % if
    
    % Apply the forward function
    [J{k}, X{k+1}, U{k}, dpOutput{k}] = ...
        generalForwardFun(obj, nextStateGrids, dpState, inputCell, currentDstrb, dpTs, k);
         
    % Update the state
    dpState = X{k+1};
    
    % Check feasibility
    if(J{k} >= obj.myInf)
        error('Cost-to-go is infinity. The problem seems to be infeasible.');
    end
    
    % Save disturbance
    D{k} = currentDstrb;
    
    % Display progress
    pctComplete = k/(N-1)*100;
    avgCalcTime = toc(mytimer)/k;
    estTimeRemaining = avgCalcTime*(N-1-k);
    if obj.showVerbose
        Nmsg = obj.displayProgressMessage(pctComplete,...
            avgCalcTime,estTimeRemaining,'forwards',Nmsg);
    end % if
    
end % for

% evaluate cost-to-go at final time, i.e. final state cost
finalStateGrid = struct2cell(createDPGrids(obj, N, 'states','arrays'));
finalState = struct2cell(X{end});
J{end} = interpn(finalStateGrid{:}, obj.costToGo{end}, finalState{:});

% Display finished calculations
if obj.showVerbose
    obj.displayProgressMessage(100,avgCalcTime,toc(mytimer),'forwards',Nmsg);
    fprintf('\nDP forwards done\r');
    fprintf('\n');
end % if

end % function

% EOF
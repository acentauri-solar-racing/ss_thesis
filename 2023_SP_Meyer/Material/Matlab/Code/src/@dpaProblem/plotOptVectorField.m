%--------------------------------------------------------------------------
%   ETH Zurich, IDSC, Project: dpa
%--------------------------------------------------------------------------
%
%   Plot vector field of state gradients, when optimal control law is 
%   applied (works only for single state problems). 
%
%   Inputs:     obj                 Optimization problem as a dpaProblem
%               results             Struct containing the output of the
%                                   forward evaluation
%               stepSizeTime        Integer to specify coarseness of vector
%                                   field w.r.t timeVector (needs to be >= 1)
%               stepSizeState       Integers to specify coarseness of vector
%                                   field w.r.t state grid (needs to be >= 1)

%
%   See also dpaProblem/PLOTOPTTRAJ, dpaProblem/PLOTOPTCONTROLLAW

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
%   04.02.2020  JR  restructured to iterative evaluation of model function
%   29.06.2021  AS  made changes to be compatible with new results providing
%                   results as struct
%   30.06.2021  AS  replaced createDPGridVars with createDPGrids
%   07.07.2021  AS  deleted pol as an input argument as part of OptPrb/OptPol fusion

function fig = plotOptVectorField(obj, results, stepSizeTime, stepSizeState)

% Check properties of problem
assert(length(obj.stateVars) == 1,['Plot of optimal control law only ',...
    'available for single state problem']);
assert(~isempty(obj.optInputs{1}),['Optimal inputs are not available. ', ...
    'Please store the optimal inputs by changing the property obj.storeOptInputs to true.'])
% Check if stepSizeTime is an integer
assert(stepSizeTime == floor(stepSizeTime),'Step size for time needs to be an integer')
% Check if stepSizeState is an integer
assert(stepSizeState == floor(stepSizeState),'Step size for state needs to be an integer')

% Identify indices of the state grid to be shown in the plot
stepIndicesTime  = 1:stepSizeTime:length(obj.timeVector)-1;
stateGrid = struct2cell(obj.getStateVars);
stepIndicesState = 1:stepSizeState:size(stateGrid{1},2);

% get dpTs vector
dpTs = diff(obj.timeVector);

% Extract state limits
[minState, maxState] = obj.getStateLimit;

% evaluate model to determine diffState
StateMat = nan(length(stepIndicesTime),length(stepIndicesState));
diffStateMat = nan(length(stepIndicesTime),length(stepIndicesState));
for Ind = 1:length(stepIndicesTime)
    
    % Create input struct
    inputGrid = cell(1,length(obj.inputVars));
    for IndU = 1:length(obj.inputVars)
        inputGrid{IndU} = obj.optInputs{stepIndicesTime(Ind)}{IndU,1}(stepIndicesState)';
    end % for
    dpInput = cell2struct(inputGrid,{obj.inputVars.name},2);
    
    % Create state struct
    useMyGrid = obj.useMyGrid || ~strcmp(obj.boundaryMethod,'line');
    if ~useMyGrid
        assert(strcmp(obj.boundaryMethod,'line'),['No reference grid exists.',...
            ' useMyGrid or boundary line method should be used.']);
        stateCell = {linspace(obj.boundaryVars.lower.x(stepIndicesTime(Ind)),...
            obj.boundaryVars.upper.x(stepIndicesTime(Ind)), obj.stateVars.nGridPoints)};
    else
        stateCell = struct2cell(createDPGrids(obj, stepIndicesTime(Ind), 'states', 'arrays'));
        stateCell{1,1} = stateCell{1,1}';
    end % if
    StateMat(Ind,:) = stateCell{1}(stepIndicesState);
    dpState = cell2struct({stateCell{1}(stepIndicesState)},{obj.stateVars.name},2);
    
    % Create disturbance struct
    currentDstrbCell = cell(1,length(obj.dstrbVars));
    % Extract current disturbance
    for IndD = 1:length(obj.dstrbVars)
        if length(obj.dstrbVars(IndD).signal)==1
            currentDstrbCell{IndD} = obj.dstrbVars(IndD).signal;
        else
            currentDstrbCell{IndD} = obj.dstrbVars(IndD).signal(stepIndicesTime(Ind));
        end
    end % for
    currentDstrb = cell2struct(currentDstrbCell,{obj.dstrbVars(:).name},2);
    
    % Evaluate model function 
    [dpStateNew,~,~,~] = obj.modelFunction(dpState,dpInput,currentDstrb,...
        dpTs(stepIndicesTime(Ind)),obj.modelParameters);
    
    % Calculate diffState
    endUpStateCell = struct2cell(dpStateNew);
    diffStateMat(Ind,:) = endUpStateCell{1} - StateMat(Ind,:);
    
end % for

% Check wheather to plot optimal states
isResult = false;
if ~isempty(results)
    % Check properties of results
    assert(isfield(results,'states'),['Results must contain a member ',...
        'named ''states''']);
    
    isResult = true;
    
    % Put optimal states in matrix form
    stateCell = struct2cell(results.states);
end % if

% build grid matrices
TMat = repmat(obj.timeVector(stepIndicesTime),1,length(stepIndicesState));
dpTsMat = repmat(dpTs(stepIndicesTime),1,length(stepIndicesState));

% Create figure
fig = figure;

% Initialize legend label with state name
legendLabels = {'Optimal Vector Field'};
hold on;

% Plot vector field
quiver(TMat, StateMat,...
    dpTsMat*stepSizeTime,...
    diffStateMat*stepSizeTime,...
    'AutoScale','off',...
    'ShowArrowHead','off',...
    'Marker','*',...
    'MarkerSize',3);

if isResult
    plot(obj.timeVector,[stateCell{:}],'k');
    % Extend legend labels
    legendLabels = [legendLabels, {'Optimal Path'}];
end % if

% Add title
title('Vector Field');
% Add axis labels
xlabel('Time');
ylabel(obj.stateVars.name);
% Adjust axis limits
xlim([obj.timeVector(1) obj.timeVector(end)]);
ylim([min(minState{1}) max(maxState{1})]);
% Show legend
legend(legendLabels{:})

end % function
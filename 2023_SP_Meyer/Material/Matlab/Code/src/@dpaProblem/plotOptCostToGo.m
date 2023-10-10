%--------------------------------------------------------------------------
%   ETH Zurich, IDSC, Project: dpa
%--------------------------------------------------------------------------
%
%   Inputs:     obj          Optimization problem as a dpaProblem
%               results      Struct containing the output of the
%                            forward evaluation
%
%   See also dpaProblem/PLOTOPTTRAJ, dpaProblem/PLOTOPTINPUT,
%   dpaProblem/PLOTVECTORFIELD

%   Authors:
%   Hansi Ritzmann      (JR)    jritzman@ethz.ch
%   Stijn van Dooren    (SV)    stijnva@ethz.ch
%   Andreas Ritter      (AR)    anritter@idsc.mavt.ethz.ch
%   Dario Nastasi       (DN)    nastasid@ethz.ch
%   Hokwang Choi        (HC)    hochoi@ethz.ch
%   Ashwin Sandeep      (AS)    asandeep@student.ethz.ch
%
%   Revision:
%   03.02.2020  JR  created, based on plotOptControlLaw.m
%   29.06.2021  AS  made changes to be compatible with new OptRes providing
%                   results as struct
%   07.07.2021  AS  deleted pol as an input argument as part of OptPrb/OptPol fusion

function fig = plotOptCostToGo(obj,results)

% Check properties of problem
assert(length(obj.stateVars) == 1,['Plot of optimal cost-to-go only ',...
    'available for single state problem']);

% Initialize state grid (y-values)
stateGrid = struct2cell(obj.getStateVars);
% Adjust state grid size
if size(stateGrid{1},1) == 1
    stateGrid{1} = repmat(stateGrid{1},length(obj.timeVector)-1,1);
else
    stateGrid{1} = stateGrid{1}(1:end-1,:);
end % if

% Create time grid (x-values)
[T,~] = ndgrid(obj.timeVector(1:end-1),stateGrid{1}(1,:));

% Create optimal cost-to-go grid
Cost2Go = zeros(size(T));
for i = 1:length(obj.timeVector(1:end-1))
    Cost2Go(i,:) = obj.costToGo{i};
end % for

% Check whether to plot optimal states
isResult = false;
if nargin == 2
    % Check properties of results
    assert(isfield(results,'states'),['Results must contain a member ',...
        'named ''states''']);
    
    isResult = true;

    % Put optimal states in matrix form
    stateCell = struct2cell(results.states);
end % if

% Create figure
fig = figure;
hold on; box on;

% plot optimal cost-to-go
surf(T,stateGrid{1},Cost2Go);
shading flat; colorbar;

% Add title and axis labels
title('Optimal Cost-to-go')
xlabel('Time');
ylabel(obj.stateVars.name);

% If available, plot optimal states
if isResult
    plot3(obj.timeVector,stateCell{:},...
        2*max(max(Cost2Go))*ones(size(obj.timeVector)),'k','LineWidth',2);
    % Adjust axis limits
    xlim([obj.timeVector(1) obj.timeVector(end)]);
else
    % Adjust axis limits
    xlim([obj.timeVector(1) obj.timeVector(end-1)]);
end % if

end % function

% EOF
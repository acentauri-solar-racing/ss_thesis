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
%   14.02.2019  DN  created
%   12.06.2019  HC  revision (Time-varying inputs considered)
%   23.10.2019  SD  bugfix + fig handle + better labels + resize figure
%   29.06.2021  AS  made changes to be compatible with new OptRes providing
%                   results as struct
%   07.07.2021  AS  deleted pol as an input argument as part of OptPrb/OptPol fusion

function fig = plotOptControlLaw(obj,results)
% Check properties of problem
assert(length(obj.stateVars) == 1,['Plot of optimal control law only ',...
    'available for single state problem']);
assert(~isempty(obj.optInputs{1}),['Optimal inputs are not available. ', ...
    'Please store the optimal inputs by changing the property Optobj.storeOptInputs to true.'])

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

% Initialize input values (z-values)
optInput = zeros(size(T));

% Check wheather to plot optimal states
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
nInputs = length(obj.inputVars);
for iInput = 1:nInputs
    % Extract optimal control law
    for i = 1:length(obj.timeVector(1:end-1))
        optInput(i,:) = obj.optInputs{i}{iInput};
    end % for
    
    % Choose plot
    ax(iInput) = subplot(1,nInputs,iInput); %#ok<AGROW>
    hold on; box on;
    surf(T,stateGrid{1},optInput);
    shading flat; colorbar;
    
    % Add title and axis labels
    title(obj.inputVars(iInput).name)
    xlabel('Time');
    ylabel(obj.stateVars.name);
    
    % If available, plot optimal states
    if isResult
        plot3(obj.timeVector,stateCell{:},...
            2*max(max(optInput))*ones(size(obj.timeVector)),'k','LineWidth',2);
        % Adjust axis limits
        xlim([obj.timeVector(1) obj.timeVector(end)]);
    else
        % Adjust axis limits
        xlim([obj.timeVector(1) obj.timeVector(end-1)]);
    end % if
end % for

% Link axes
linkaxes(ax,'xy');

% Resize
w = fig.Position(3);
f = 0.5*(nInputs-1);
fig.Position(3) = w*nInputs;
fig.Position(1) = fig.Position(1) - f*w;

end % function

% EOF
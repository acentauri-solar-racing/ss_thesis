%--------------------------------------------------------------------------
%   ETH Zurich, IDSC, Project: dpa
%--------------------------------------------------------------------------
%
%   Inputs:     obj          Optimization problem as a dpaProblem
%               results      Struct containing the output of the
%                            forward evaluation
%
%   See also dpaProblem/PLOTOPTINPUT, dpaProblem/PLOTOPTCONTROLLAW

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
%   23.10.2019  SD  fig handle + removed title + resize figure
%   29.06.2021  AS  made changes to be compatible with new OptRes providing
%                   results as struct
%   07.07.2021  AS  deleted pol as an input argument as part of OptPrb/OptPol fusion

function fig = plotOptTraj(obj,results)
% Check properties of results
assert(isfield(results,'states'),['Results must contain a member named ',...
    '''states''']);

% Extract state limits
[minState, maxState] = obj.getStateLimit;

% Create figure
fig = figure;
nStates = length(obj.stateVars);
for iState = 1:nStates
    % Initialize legend label with state name
    legendLabels = {obj.stateVars(iState).name};
    
    % Choose plot
    ax(iState) = subplot(1,nStates,iState);%#ok<AGROW>
    hold on; box on;
    % Plot optimal state 
    plot(obj.timeVector,results.states.(subsref(fieldnames(results.states),substruct('{}',{iState}))));
    
    % If available, plot boundary line
    if strcmp(obj.boundaryMethod,'line')
        % Extract boundary line
        [upperLine, lowerLine] = getBoundaryLine(obj);
        % Plot boundary line
        plot(obj.timeVector,upperLine,'k');
        plot(obj.timeVector,lowerLine,'k');
        % Extend legend labels
        legendLabels = [legendLabels, {'upper BL', 'lower BL'}];%#ok<AGROW>
    end % if
    
    % If state grid is constant, make state limits vectors
    if isscalar(minState{iState})
        minState{iState} = repmat(minState{iState},1,length(obj.timeVector));
    end % if
    if isscalar(maxState{iState})
        maxState{iState} = repmat(maxState{iState},1,length(obj.timeVector));
    end % if
    
    % Plot state limits
    plot(obj.timeVector,maxState{iState},'r--');
    plot(obj.timeVector,minState{iState},'r-.');
    % Extend legend labels
    legendLabels = [legendLabels, {'upper state limit', 'lower state limit'}];%#ok<AGROW>
    
    % Add axis labels
    xlabel('Time');
    ylabel(obj.stateVars(iState).name);
    % Adjust axis limits
    xlim([obj.timeVector(1) obj.timeVector(end)]);
    % Show legend
    legend(legendLabels{:});
end % for

% Link x-axis
linkaxes(ax,'x');

% Resize
w = fig.Position(3);
f = 0.5*(nStates-1);
fig.Position(3) = w*nStates;
fig.Position(1) = fig.Position(1) - f*w;

end % function

% EOF
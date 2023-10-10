%--------------------------------------------------------------------------
%   ETH Zurich, IDSC, Project: dpa
%--------------------------------------------------------------------------  
%
%   Inputs:     obj          Optimization problem as a dpaProblem
%               results      Struct containing the output of the
%                            forward evaluation
%
%   See also dpaProblem/PLOTOPTCONTROLLAW,dpaProblem/PLOTOPTTRAJ

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
%                   results as structs
%   07.07.2021  AS  deleted pol as an input argument as part of OptPrb/OptPol fusion

function fig = plotOptInput(obj,results)
% Check properties of results
assert(isfield(results,'inputs'),['Results must contain a member named ',...
    '''inputs''']);

% Extract input limits
[minInput, maxInput] = obj.getInputLimit;

% Create figure
fig = figure;
nInputs = length(obj.inputVars);
for iInput = 1:nInputs
    % Choose plot
    ax(iInput) = subplot(1,nInputs,iInput); %#ok<AGROW>
    hold on; box on;
    % Plot optimal input 
    plot(obj.timeVector(1:end-1),results.inputs.(subsref(fieldnames(results.inputs),substruct('{}',{iInput}))));
    
    % If input grid is constant, make input limits vectors
    if isscalar(minInput{iInput})
        minInput{iInput} = repmat(minInput{iInput},1,length(obj.timeVector)-1);
    end % if
    if isscalar(maxInput{iInput})
        maxInput{iInput} = repmat(maxInput{iInput},1,length(obj.timeVector)-1);
    end % if
    
    % Plot input limits
    plot(obj.timeVector(1:length(maxInput{iInput})),maxInput{iInput},'r--');
    plot(obj.timeVector(1:length(minInput{iInput})),minInput{iInput},'r-.');
    
    % Add axis labels
    xlabel('Time');
    ylabel(obj.inputVars(iInput).name);
    % Adjust axis limits
    xlim([obj.timeVector(1) obj.timeVector(end-1)]);
    % Show legend
    legend(obj.inputVars(iInput).name, 'upper input limit','lower input limit')
end % for

% Link x-axis
linkaxes(ax,'x');

% Resize
w = fig.Position(3);
f = 0.5*(nInputs-1);
fig.Position(3) = w*nInputs;
fig.Position(1) = fig.Position(1) - f*w;
  
end % function

% EOF
%--------------------------------------------------------------------------
%   ETH Zurich, IDSC, Project: dpa
%--------------------------------------------------------------------------
%
%   This function checks the basic properties of the dpaProblem object. If
%   there is any problem with the dpaProblem, there will be an error.
%   Otherwise the function will return nothing. This function is publicly
%   available, so if it is run in the command window and no error is
%   displayed, the dpaProbem is good to go.
%
%   sanity_check(obj)
%
%   Input:      obj       dpaProblem object which needs to be checked
%
%   See also dpaProblem/dpaProblem.m

%   Authors:
%   Hansi Ritzmann      (JR)    jritzman@ethz.ch
%   Stijn van Dooren    (SD)    stijnva@ethz.ch
%   Andreas Ritter      (AR)    anritter@idsc.mavt.ethz.ch
%   Dario Nastasi       (DN)    nastasid@ethz.ch
%   Hokwang Choi        (HC)    hochoi@ethz.ch
%   Kerim Barhoumi      (KB)    bkerim@ethz.ch
%
%   Revision:
%   14.02.2019  DN  created
%   16.01.2020  SD  small clean-up
%   10.06.2021  AS  changed the check for upper/lower state limit sizes
%   16.06.2021  AS  deleted assert for inputType
%   09.03.2022  KB  Add check for length of input weight
%   15.03.2022  KB  Add check for length of input boundaries
%   03.05.2022  KB  Change check for length of input boundaries & lastInput

function sanity_check(obj)
assert(~isempty(obj.timeVector),'Time vector has not been specified');

assert(~isempty(obj.stateVars),['No state has been added. Please use the ', ...
    'addStateVariable() function.']);

assert(~isempty(obj.inputVars),['No input has been added. Please use the ', ...
    'addInputVariable() function.']);

assert(issorted(obj.timeVector,'monotonic') && all(diff(obj.timeVector)>0),...
    'Time vector has to be monotonically increasing');

for i = 1:length(obj.stateVars)
    assert(length(obj.stateVars(i).min) == length(obj.timeVector) || ...
        length(obj.stateVars(i).min) == 1,['Min and max of each state have to be ' ...
        'either a scalar or a vector the same length as the time vector.']);
end

for i = 1:length(obj.inputVars)
    assert(length(obj.inputVars(i).min) == 1 || ...
        length(obj.inputVars(i).min) == length(obj.timeVector)-1, ...
        ['Min and max of each state have to be either a scalar or a vector ' ...
        'with length by one shorter than the time vector (N-1).']);
end

% Input regularisation: check lastInput
for i = 1:length(obj.inputVars)
    if any(obj.inputVars(i).weight) % input regularisation
        if isscalar(obj.inputVars(i).max) && isscalar(obj.inputVars(i).min) % scalar input bounds
            if obj.inputVars(i).lastInput > obj.inputVars(i).max(end) || obj.inputVars(i).lastInput < obj.inputVars(i).min(end)
                warning(['The lastInput = ' num2str(obj.inputVars(i).lastInput) ...
                    ' is outside of the input bounds (min = ' ...
                    num2str(obj.inputVars(i).min(end)) ' / max = ' ...
                    num2str(obj.inputVars(i).max(end)) ').']);
            end
        else % vector input bounds
            if obj.inputVars(i).lastInput > obj.inputVars(i).max(end) || obj.inputVars(i).lastInput < obj.inputVars(i).min(end)
                warning(['The lastInput = ' num2str(obj.inputVars(i).lastInput) ...
                    ' is outside of the last input bound entry (min = ' ...
                    num2str(obj.inputVars(i).min(end)) ' / max = ' ...
                    num2str(obj.inputVars(i).max(end)) ').']);
            end
        end
    end
end

for i = 1:length(obj.inputVars)
    assert(length(obj.inputVars(i).weight) == length(obj.timeVector)-1 || ...
        length(obj.inputVars(i).weight) == 1,['Weight of each input has to be ' ...
        'either a scalar or a vector with length of the time vector minus two (N-1).']);
end

assert((strcmp(obj.boundaryMethod,'line') && length(obj.stateVars) == 1) || ...
    ~strcmp(obj.boundaryMethod,'line'),['Boundary line only available ',...
    'for single state problems']);

% warning if LevelSet method is selected for a problem with 1 state
NStates = length(obj.stateVars);
if NStates==1 && strcmpi(obj.boundaryMethod,'levelset')
    warning('For single state systems, consider using the Boundary-Line method.')
end

end % function

% EOF
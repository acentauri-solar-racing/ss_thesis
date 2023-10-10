%--------------------------------------------------------------------------
%   ETH Zurich, IDSC, Project: dpa
%--------------------------------------------------------------------------
%
%   Execute forward DP algorithm to get the optimal state trajectory, 
%   inputs, and cost-to-go. This function checks the properties of the
%   problem and selects a forward function accordingly.
%
%   result = evaluate(obj,varargin)
%
%   Inputs:     obj         Optimization problem as a dpaProblem object
%               varargin    State names and their initial values
%
%   Outputs:    result      Optimal state trajectory, inputs and cost-to-go
%                           at every time step (defined by timeVector) as a
%                           struct
%
%   See also dpaProblem/SOLVE

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
%   19.06.2019  HC  revision (Level set method included)
%   16.06.2021  AS  added functionality for setting initial states
%   29.06.2021  AS  changed output format of results from cell arrays to structs
%   30.06.2021  AS  added the functionality of sanity_check.m as the function is removed
%   07.07.2021  AS  moved function to dpaProblem and deleted pol as input
%                   argument as part of OptPrb/OptPol fusion

function result = evaluate(obj,varargin)
% Check for correct inputs
assert(nargin>=3,['This function requires the following inputs - ',...
    'problem object and names and initial values of all states.']);
i =1;
while i < length(varargin)
    assert(ischar(varargin{i}) && isnumeric(varargin{i+1}) &&...
        isscalar(varargin{i+1}) && isfinite(varargin{i+1}),...
        ['All states should have a name followed by its initial value ',...
        'which must be finite numeric. ']);
    i = i+2;
end

% Find the index of the given state variable.
allVarNamesOfThisType = {obj.stateVars.name};
i =1;
while i < length(varargin)
    ind = find(strcmp(allVarNamesOfThisType, varargin(i)));
    assert(isscalar(ind), 'dpa:UnknownVariable', ...
        'There is no state variable %s.', varargin(i));
    % Set the initial value and by doing so check if the value is valid.
    val = varargin{i+1};
    obj.stateVars(ind).init = val;
    i=i+2;
end

sanity_check(obj);

assert(~isempty(obj.costToGo),['Optimal control law is not available. ', ...
    'Please run the solve function first.'])

assert(~any(isempty([obj.stateVars.init])),['At least one initial ',...
    'state is missing.']);

forwardTimer = tic;

% Create struct with initial values of the optimization problem
varNames = {obj.stateVars(:).name};
initVals = {obj.stateVars(:).init};
dpStateInit = cell2struct(initVals, varNames, 2);

if strcmp(obj.boundaryMethod,'levelset')
    runForwardFunction = @LevelsetMethodForwardDP;
else
    runForwardFunction = @GeneralForwardDP;
end

[J, X, U, D, dpOutput] = runForwardFunction(obj, dpStateInit);

% extract result data as structs
result.usedForwardFunction = func2str(runForwardFunction);
result.evaluationDuration = toc(forwardTimer);
result.time = obj.timeVector';
result.costToGo = cell2mat(J);
result.states = getDPOutput(X);
result.inputs = getDPOutput(U);
result.disturbances = getDPOutput(D);
result.outputs = getDPOutput(dpOutput);

end % function

function ResVec = getDPOutput(ResCell)
    
    %check if result data is available for the problem
    if isempty(ResCell{1}) || isempty(fieldnames(ResCell{1}))
        ResVec = [];
    else
    
        % get fields and convert cell array to structure array
        fields = fieldnames(ResCell{1});
        StructArray = cell2mat(ResCell);

        % check whether result struct contains substructs
        ContainsSubStruct = false;
        for Ind = 1:length(fields)
            ContainsSubStruct = ContainsSubStruct || isstruct(ResCell{1}.(fields{Ind}));
        end

        % extract data from cell array
        if ContainsSubStruct

            % get subfields
            subfields = fieldnames(ResCell{1});
            % check whether full depth has been reached
            fulldepth = false(size(subfields));
            for Ind = 1:length(subfields)
                fulldepth(Ind) = ~isstruct(ResCell{1}.(subfields{Ind}));
            end
            % recursive search in depth
            while any(~fulldepth)
                % find new subfields
                IndNotFullDepth = find(~fulldepth,1);
                subfieldsNew =  fieldnames(eval(['ResCell{1}.' subfields{IndNotFullDepth}]));
                for Ind = 1:length(subfieldsNew)
                    subfieldsNew{Ind} = [subfields{IndNotFullDepth} '.' subfieldsNew{Ind}];
                end
                % check whether full depth has been reached
                fulldepthNew = false(size(subfieldsNew));
                for Ind = 1:length(subfieldsNew)
                    fulldepthNew(Ind) = ~isstruct(eval(['ResCell{1}.' subfieldsNew{Ind}]));
                end
                % augment subfields and fulldepth
                subfields = vertcat(subfields{1:IndNotFullDepth-1}, subfieldsNew, subfields{IndNotFullDepth+1:end});
                fulldepth = vertcat(fulldepth(1:IndNotFullDepth-1), fulldepthNew, fulldepth(IndNotFullDepth+1:end));
            end

            % extract data
            for IndSubField = 1:length(subfields)
                testVal = eval(['ResCell{1}.' subfields{IndSubField}]);
                if isscalar(testVal) && ( isnumeric(testVal) || islogical(testVal) )
                    eval(['ResVec.' subfields{IndSubField} ' = cell2mat(cellfun(@(x)x.' subfields{IndSubField} ',ResCell,''UniformOutput'',0));'])
                else
                    warning(['The fields of the model output must contain scalar numerical/logical values or a struct. ' ...
                        'The field ''%s'' contains neither, and was exluded from the DP output.'],subfields{IndSubField})
                end
            end

        else

            % extract data
            for Ind = 1:length(fields)
                testVal = StructArray(1).(fields{Ind});
                if isscalar(testVal) && ( isnumeric(testVal) || islogical(testVal) )
                    % extract numeric/logical values
                    ResVec.(fields{Ind}) = [StructArray(:).(fields{Ind})];
                else
                    warning(['The fields of the model output must contain scalar numerical/logical values or a structs. ' ...
                        'The field ''%s'' contains neither, and was exluded from the DP output.'],fields{Ind})
                end
            end

        end
    end
        
end

% EOF
%--------------------------------------------------------------------------
%   ETH Zurich, IDSC, Project: dpa
%--------------------------------------------------------------------------
%
%   This function checks the model function and outputs the function handle
%
%   functionHandle = parseModelFunction(modelFunction)
%
%   Inputs:     modelFunction   model function as a function handle or char
%
%   Outputs:    functionHandle  corresponding function handle

%   Authors:
%   Hansi Ritzmann      (JR)    jritzman@ethz.ch
%   Stijn van Dooren    (SV)    stijnva@ethz.ch
%   Andreas Ritter      (AR)    anritter@idsc.mavt.ethz.ch
%   Dario Nastasi       (DN)    nastasid@ethz.ch
%   Hokwang Choi        (HC)    hochoi@ethz.ch
%
%   Revision:
%   14.02.2019  DN  created

function functionHandle = parseModelFunction(modelFunction)
% Convert string to function handle
if ischar(modelFunction)
    % Treat special if the given function name is at different location.
    [filepath, filename] = fileparts(modelFunction);
    if isempty(filepath)
        functionHandle = str2func(filename);
    else
        currentDirection = cd;
        cd(filepath);
        functionHandle = str2func(filename);
        cd(currentDirection);
    end % if
elseif isa(modelFunction, 'function_handle')
    % Check if the given function handle has the proper format
    funcDetails = functions(modelFunction);
    assert(~strcmp(funcDetails.type, 'anonymous'), ...
        'dpa:InvalidModelFunction', ...
        ['The given function handle is an anonymous function. Only ', ...
        'function handles without any input arguments are accepted, ', ...
        'where the syntax is given by e.g. @myFunction.']);
    functionHandle = modelFunction;
else
    error('dpa:InvalidModelFunction', ['To define the model ', ...
        'function either give a function handle or a char string ', ...
        '(can also be a relative or absolute file path).']);
end % if

% Check if the identified function handle is a matlab function
try
    nInputArgs = nargin(functionHandle);
    nOutputArgs = nargout(functionHandle);
catch ME
    if strcmp(ME.identifier, 'MATLAB:narginout:functionDoesnotExist')
        if ischar(modelFunction)
            error('dpa:InvalidModelFunction', ...
                ['The given function with the given char string %s ', ...
                'does either not exist or it is not a valid matlab ', ...
                'function.'], modelFunction);
        else
            error('dpa:InvalidModelFunction', ...
                ['The given function handle @%s does either not ', ...
                'exist or it is not a valid matlab function.'], ...
                func2str(modelFunction));
        end % if
    else
        throwAsCaller(ME);
    end % if
end % try

% Check the number of input arguments and the number of output arguments.
assert(nInputArgs >= 1, 'dpa:InvalidModelFunction', ...
    ['The given model function must have at least one input argument', ...
    '(has %i instead).'], nInputArgs);
assert(any(nOutputArgs == [3, 4]), 'dpa:InvalidModelFunction', ...
    ['The given model function has a wrong number of output ', ...
    'arguments (%i instead of 3 or 4).'], nOutputArgs);

end % function

% EOF
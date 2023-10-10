%--------------------------------------------------------------------------
%   ETH Zurich, IDSC, Project: dpa
%--------------------------------------------------------------------------
%
%   This class contains all the information about the optimization problem
%   and all the tools neccessary to solve it. The constructor initializes
%   the model function.
%
%   OprPrb = dpaProblem(modelFunction, modelParameters)
%
%   Inputs:     modelFunction   Model as a string indication the function
%                               name or a function handle
%               modelParameters Parameters for the model function
%
%   Outputs:    OptPrb          Optimization problem as dpaProblem

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
%   14.02.2019  DN  Created
%   19.06.2019  HC  Revision(include levelset property, update findInput.m)
%   24.01.2021  KB  Changed inputs in header of createDPGridVars
%   28.01.2021  KB  Add property 'modelInputsVectors'
%   15.05.2021  AS  Deleted property showWarnings
%   15.05.2021  AS  Deleted properties showWaitbar and waitbarHandle
%   15.05.2021  AS  Changed set method of showVerbose to use islogical instead of parseFlag (deleted function) 
%   17.05.2021  AS  Added set method for modelInputsVectors and renamed the property to vectorMode
%   09.06.2021  AS  Deleted all dependent properties and their get methods
%   30.06.2021  AS  Added the property storeOptInputs and its set method
%   07.07.2021  AS  Added properties solveDuration, costToGo, levelset, optInputs, usedBackwardFunction
%                   as part of OptPrb/OptPol fusion

classdef dpaProblem < handle
    
    properties (Access=public)
        showVerbose = true;
        myInf = 1e4;                % Custom infinity cost
        boundaryMethod = 'none';    % Chose 'line' or 'levelset' for calculating the boundary line and 'none' otherwise
        nMaxIterInversion = 10;     % Maximal amount of iterations when estimating the inverse model
        maxTolInversion = 1e-8;     % Maximum error tolarance of the model inversion
        useMyGrid = false;          % True/False wheather use user defined state limits or use boundary line as state limits
        timeVector = [];            % This is the time vector used for solving the DP-problem
        vectorMode = false;         % True/False whether use matrices or vectors as inputs to the model function
        storeOptInputs = false;     % True/False whether to store optimal inputs during backward evaluation
    end % public properties
    
    properties (Access=?dpaProblem)
        modelFunction               % Function handle containing the model
        finalStateCostFcn           % Function handle to initialize the cost-to-go
        inputVars = dpaInputVar();  % Class containing properties of the input variables
        stateVars = dpaStateVar();  % Class containing properties of the state variables
        dstrbVars = dpaDstrbVar();  % Class containing properties of the disturbance variables
        boundaryVars = [];          % Struct with members upper and lower
    end % private properties
    
    properties (SetAccess=?dpaProblem, GetAccess=public)
        modelParameters = {};       % Parameters defined in main problem file
        solveDuration = [];         % Measures evaluation time of the backward function
        costToGo = {};              % Cost-to-go for every state in the state grid
        levelset = {};              % Cost-to-go for level set function
        optInputs = {};             % Optimal inputs for every state in the state grid
        usedBackwardFunction = [];  % String with the name of the backward function
    end % restricted properties
    
    methods
        function obj = dpaProblem(modelFunction, modelParameters, varargin)
            obj.modelFunction = modelFunction;
            if nargin == 1 || isempty(modelParameters)
                obj.modelParameters = struct();
            elseif nargin == 2
                obj.modelParameters = modelParameters;
            else
                error('dpa:WrongNumberOfInputs', ...
                    'Give either 1 or 2 input arguments.');
            end % if
        end % constructor function
    end % constructor method
    
    methods
        function set.showVerbose(obj, value)
            assert(islogical(value),...
                'dpa:WrongInputArgument',...
                'Give a logical (true/false)');
            obj.showVerbose = value;
        end % set.showVerbose
        
        function set.myInf(obj, value)
            assert(isnumeric(value) && value >= 0 && ~isnan(value), ...
                'dpa:WrongInputArgument', ...
                'Give a numeric and positive number.');
            obj.myInf = value;
        end % set.myInf
        
        function set.boundaryMethod(obj, string)
            assert(ischar(string) && ...
                any(strcmpi(string, {'none', 'line', 'levelset'})), ...
                'dpa:WrongInputArgument', ...
                'Give char string equal to none, line, or levelset.');
            obj.boundaryMethod = lower(string);
        end % set.boundaryMethod
        
        function set.useMyGrid(obj, value)
            assert(islogical(value),...
                'dpa:WrongInputArgument',...
                'Give a logical (true/false)');
            obj.useMyGrid = value;
        end % set.fixedGrid
        
        function set.nMaxIterInversion(obj, value)
            assert(isnumeric(value) && value >= 0 && isfinite(value) && ...
                round(value) == value, ...
                'dpa:WrongInputArgument', ...
                'Give a numeric number (integer).');
            obj.nMaxIterInversion = value;
        end % set.nMaxIterInversion
        
        function set.maxTolInversion(obj, value)
            assert(isnumeric(value) && value >= 0 && isfinite(value), ...
                'dpa:WrongInputArgument', ...
                'Give a numeric and positive number.');
            obj.maxTolInversion = value;
        end % set.maxTolInversion
        
        function set.modelFunction(obj, fnc)
            fnc = obj.parseModelFunction(fnc);
            assert(isa(fnc, 'function_handle'), ...
                'dpa:Internal', 'Give a function handle.');
            obj.modelFunction = fnc;
        end % set.modelFunction
        
        function set.finalStateCostFcn(obj, fnc)
            assert(isa(fnc, 'function_handle'), ...
                'dpa:Internal', 'Give a function handle.');
            obj.finalStateCostFcn = fnc;
        end % set.finalcostFunction
        
        function set.modelParameters(obj, par)
            assert(isstruct(par), 'dpa:Internal', 'Give a struct.');
            obj.modelParameters = par;
        end % set.modelParameters
        
        function set.inputVars(obj, varArray)
            assert(isa(varArray, 'dpaInputVar') && isrow(varArray), ...
                'dpa:Internal', 'Give a array of dpaInputVar objects.');
            obj.inputVars = varArray;
        end % set.inputVars
        
        function set.stateVars(obj, varArray)
            assert(isa(varArray, 'dpaStateVar') && isrow(varArray), ...
                'dpa:Internal', 'Give a array of dpaStateVar objects.');
            obj.stateVars = varArray;
        end % set.stateVars
        
        function set.dstrbVars(obj, varArray)
            assert(isa(varArray, 'dpaDstrbVar') && isrow(varArray), ...
                'dpa:Internal', 'Give a array of dpaDstrbVar objects.');
            obj.dstrbVars = varArray;
        end % set.dstrbVars
        
        function set.boundaryVars(obj, var)
            obj.boundaryVars = var;
        end % set.bounaryVars
        
        function set.timeVector(obj, varArray)
            assert(min(size(varArray)) == 1, 'dpa:Internal', ...
                'Time vector has to be a vector')
            assert(all(isnumeric(varArray)) && all(isfinite(varArray)), ...
                'dpa:Internal', 'Time vector must be finit numeric values')
            if iscolumn(varArray)
                obj.timeVector = varArray;
            else
                obj.timeVector = varArray';
            end
        end
        
        function set.vectorMode(obj, value)
            assert(islogical(value),...
                'dpa:WrongInputArgument',...
                'Give a logical (true/false)');
            obj.vectorMode = value;
        end % set.vectorMode
        
        function set.storeOptInputs(obj, value)
            assert(islogical(value),...
                'dpa:WrongInputArgument',...
                'Give a logical (true/false)');
            obj.storeOptInputs = value;
        end % set.storeOptInputs
    end % set.property methods
        
    methods (Access={?dpaProblem, ?dpaStateVar}, Static=true)
        functionHandle = parseModelFunction(modelFunction)
    end % restricted & static methods
    
    methods (Access=public, Static=true)
        msgLength = displayProgressMessage(pctComplete,avgCalcTime,...
            estTimeRemaining,forwardsOrBackwardsString,prevMsgLength)
    end % public & static methods
    
end % classdef

% EOF
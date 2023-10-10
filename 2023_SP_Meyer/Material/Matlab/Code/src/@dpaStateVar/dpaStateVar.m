%--------------------------------------------------------------------------
%   ETH Zurich, IDSC, Project: dpa
%--------------------------------------------------------------------------
%
%   This constructor initalizes the state with a given name. The state will
%   be accessable via its name.
%
%   obj = dpaStateVar(name)
%
%   Inputs:     name        String containing the name of the state
%
%   Outputs:    obj         dpaStateVar which is initialized with 'name'
%
%   See also dpaInputVar/dpaInputVar.m, dpaDstrbVar/dpaDstrbVar.m

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
%   20.06.2019  HC  revision(assert expression)
%   17.05.2021  AS  deleted ndgrid function (unused)
%   17.05.2021  AS  transferred the functionality of arraygrid to dpaEveryVar.m
%   18.05.2021  AS  deleted the function gridSize
%   10.06.2021  AS  deleted isconst function and added stateIsConst property
%   02.07.2021  AS  state targets set together using a function rather than separate set methods

classdef (Sealed=true) dpaStateVar < dpaEveryVar
    
    properties (Access={?dpaProblem, ?dpaEveryVar})
        nGridPoints = [];           % Number of grid points 
        min = [];                   % Lower limit (scalar or vector)
        max = [];                   % Upper limit (scalar or vector)
        targetMin = [];             % Lower limit for terminal set (scalar)
        targetMax = [];             % Upper limit for terminal set (scalar)
        init = [];                  % Inital value for forward DP (scalar)
        stateIsConst                % Logical for if state value is constant
    end % restricted properties
    
    methods (Access=?dpaProblem)
        function obj = dpaStateVar(name, nGridPoints, min, max)
            % Constructor with no input argument will give empty array of
            % dpaStateVar objects.
            if nargin == 0 
                obj = dpaStateVar.empty(1,0);
            else
                obj.name = name;
                
                assert(isnumeric(nGridPoints) && isscalar(nGridPoints) && isfinite(nGridPoints) && ...
                all(round(nGridPoints) == nGridPoints & nGridPoints > 0), ...
                'dpa:dpaInputVar:Internal', ...
                'The number of grid points must be element of N (Z>0).');
                obj.nGridPoints = nGridPoints;
                
                assert(isvector(min) && all(isnumeric(min)) && all(isfinite(min)), ...
                'dpa:dpaInputVar:Internal', ...
                'The lower boundary must be a scalar or vector containing finite numeric values.');
                assert(isvector(max) && all(isnumeric(max)) && all(isfinite(max)), ...
                'dpa:dpaInputVar:Internal', ...
                'The upper boundary must be a scalar or vector containing finite numeric values.');
                dpaEveryVar.checkBoundaries(obj, min, max);
                obj.min = min(:);
                obj.max = max(:);
                
                obj.stateIsConst = size(obj.min,1) == 1 && size(obj.max,1) == 1;
            end % if
        end % constructor function
    end % constructor method
    
    methods  
        function obj = set.init(obj, val)
            % Check if the initial value is within the state grid.
            assert(val <= obj.max(1) && val >= obj.min(1), ...
                'dpa:UnreasonableInitialValue', ...
                ['Initial value is not within the range of the ', ...
                'state variable (%s).'], obj.name); %#ok<MCSUP>
            obj.init = val;
        end % function
    end % set.property methods
    
    methods (Access=?dpaProblem)
        function [targetMin, targetMax] = set_target(obj,min,max)
            assert(isscalar(min) && isnumeric(min) && isfinite(min), ...
                'dpa:dpaInputVar:Internal','The lower target must be a scalar finite numeric value.');
            assert(isscalar(max) && isnumeric(max) && isfinite(max), ...
                'dpa:dpaInputVar:Internal','The upper target must be a scalar finite numeric value.');
            assert(min < max, ...
                'dpa:dpaProblem:UnreasonableFinalState', ...
                'The minimum must be smaller than the assigned maximum of this state variable.');
            assert(~isempty(find(min <= linspace(obj.min(end),obj.max(end),obj.nGridPoints) &...
                linspace(obj.min(end),obj.max(end),obj.nGridPoints) <= max,1)), ...
                'dpa:dpaProblem:UnreasonableFinalState', ...
                'There must be atleast one state grid point that lies between the target values.');
            targetMin = min;
            targetMax = max;
            if length(find(min <= linspace(obj.min(end),obj.max(end),obj.nGridPoints) &...
                linspace(obj.min(end),obj.max(end),obj.nGridPoints) <= max)) == 1
            warning(['Only one state grid point lies between the target values.',...
                ' Check results carefully since the problem may not be solved as desired.'])
            end
        end %function
    end % restricted method
        
    methods (Access=public)               
        function thisGrid = arraygrid(obj, k)
            thisGrid = dpaEveryVar.arraygrid(obj,k);
        end % function
    end % public method
    
end % class
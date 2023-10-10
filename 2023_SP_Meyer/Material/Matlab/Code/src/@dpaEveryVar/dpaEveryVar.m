%--------------------------------------------------------------------------
%   ETH Zurich, IDSC, Project: dpa
%--------------------------------------------------------------------------
%
%   This is a superclass which serves as a template for all the variables
%   (states, inputs and disturbance).
%
%   See also dpaStateVar/dpaStateVar.m, dpaInputVar/dpaInputVar.m

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
%   17.05.2021  AS  deleted horzat, vertcat and cat functions (unused)
%   17.05.2021  AS  added arraygrid function common to both dpaInputVar.m and dpaStateVar.m

classdef (Abstract=true) dpaEveryVar
    
    properties (Access={?dpaProblem, ?dpaEveryVar})
        name = ''; % Name of the variable
    end % restricted properties
    
    methods
        function obj = set.name(obj, string)
            assert(ischar(string) && ~isempty(string), ...
                'dpa:dpaInputVar:Internal', ...
                'The given variable name is not a char string.');
            obj.name = string;
        end % set.name
    end % set.property methods
    
    methods (Access=public, Sealed=true, Hidden=true)
        function varArray = subsasgn(A,S,B)
            if strcmp(S(1).type, '()')
                assert(isscalar(S(1).subs), ...
                    'dpa:dpaEveryVar:subsasgn', ...
                    ['Variable objects can only be vectors and are ', ...
                    'thus indexed with scalar subscripts.']);
            end % if
            varArray = builtin('subsasgn', A, S, B);
            checkForUniqueness(varArray);
        end % function
    end % public, sealed & hidden methods
    
    methods (Access=protected, Sealed=true, Static=true)
        function checkBoundaries(obj, lowerBoundary, upperBoundary)
            assert(length(lowerBoundary) == length(upperBoundary),'dpa:dpaEveryVar:LimitDimMissmatch',...
            'Lower and upper bounds need to have the same length for both states and inputs');
            if isa(obj,'dpaStateVar')
                % Ensure that maxValue is strictly larger than minValue.
                assert(all(lowerBoundary<upperBoundary),... 
                'dpa:dpaEveryVar:UnreasonableBoundaries',['The upper boundary must be ',...
                'strictly larger than the lower boundary at all times for states']);
            else
                % Ensure that maxValue is larger than or equal to the minValue.
                assert(all(lowerBoundary<=upperBoundary),... 
                'dpa:dpaEveryVar:UnreasonableBoundaries',['The upper boundary must be ',...
                'larger than or equal to the lower boundary at all times for inputs']);
            end
        end % function
    end % protected, sealed & static methods
    
    methods (Static=true)
        function thisGrid = arraygrid(obj, k)
            thisGrid = cell(1, length(obj));
            for i = 1:length(obj)
                if isscalar(obj(i).min) && isscalar(obj(i).max)
                    thisGrid{i} = linspace(obj(i).min, obj(i).max, obj(i).nGridPoints);
                else
                    thisGrid{i} = linspace(obj(i).min(k), obj(i).max(k), obj(i).nGridPoints);
                end
            end
                if length(obj)==1
                    thisGrid = thisGrid{:};
                end
        end
    end % static methods
end % class

function checkForUniqueness(varArray)
varNames = {varArray.name};
assert(length(varNames) == length(unique(varNames)), ...
    'dpa:dpaEveryVar:NonuniqueVariableName', ...
    'You cannot concatenate objects with identical names.');
end % function
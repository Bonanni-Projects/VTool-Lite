function Signals = ConcatSignalGroups(varargin)

% CONCATSIGNALGROUPS - Concatenate signal groups or signal group arrays.
% Signals = ConcatSignalGroups(Signals1,Signals2,Signals3, ...)
% Signals = ConcatSignalGroups(SIGNALS1,SIGNALS2,SIGNALS3, ...)
% Signals = ConcatSignalGroups(SIGNALS)
%
% Accepts one or more signal groups (Signals1,Signals2,Signals3,...) 
% or signal-group array inputs ('SIGNALSi') and produces a single 
% (scalar) signal group with the data in all input groups concatenated. 
%
% See also "ConcatDatasets", "BufferSignalGroup". 
%
% P.G. Bonanni
% 9/19/19

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


% Check calling syntax
args = varargin;  % initialize
mask = cellfun(@isstruct,args);
if isempty(args) || ~all(mask), error('Invalid usage.'); end

% Check that input structures/arrays have the same fields
Fields = cellfun(@fieldnames,args,'Uniform',false);
Fields = cellfun(@sort,Fields,'Uniform',false);
if length(Fields)>1 && ~all(isequal(Fields{:}))
  error('Input structures are not compatible. Fields do not match.')
end

% Build complete 'SIGNALS' structure array by stacking all inputs, including arrays
args = cellfun(@(x)x(:),args,'Uniform',false);  % ensure all arrays are columns
SIGNALS = cat(1,args{:});

% Check that all elements are valid signal groups
[Flag,Valid] = arrayfun(@IsSignalGroup,SIGNALS);
if ~all(Flag) || ~all(Valid)
  error('One or more inputs is an invalid signal group or signal group array.')
end

% Check that inputs are compatible
if numel(SIGNALS) > 1
  C = arrayfun(@GetNamesMatrix,SIGNALS,'Uniform',false);
  if ~all(isequal(C{:}))
    error('Non-homogeneous inputs. Names and/or name orders do not match.')
  end
  C = arrayfun(@(x)x.Units,SIGNALS,'Uniform',false);
  if ~all(isequal(C{:}))
    [SIGNALS,success] = ReconcileUnits(SIGNALS);
    if ~success
      error('Non-homogeneous inputs. Units do not match.')
    end
  end
end

% Perform the concatenation
Signals = SIGNALS(1);  % initialize
Signals.Values = cat(1,SIGNALS.Values);

function Signals = MergeSignalGroups(varargin)

% MERGESIGNALGROUPS - Merge two or more signal groups into one.
% Signals = MergeSignalGroups(Signals1,Signals2,...)
%
% Merges two or more input signal groups ('Signals1','Signals2',...) 
% into one output signal group 'Signals'.  The order of signals 
% within the groups is preserved in the output. 
%
% P.G. Bonanni
% 9/19/18

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


if nargin < 1
  error('Invalid usage.')
end

% Check input validity
n = arrayfun(@numel,varargin);
if any(n > 1)
  error('Works for scalar signal groups only.')
end
[flag,valid] = cellfun(@IsSignalGroup,varargin);
if ~all(flag) || ~all(valid)
  error('One or more inputs is not a valid signal group.  See "IsSignalGroup".')
end

% Number of inputs
ninputs = length(varargin);

% Check name-layer compatibility
Layers = cellfun(@GetLayers,varargin,'Uniform',false);
if ninputs > 1 && ~isequal(Layers{:})
  error('Inputs have incompatible name layers.')
end

% Check signal-length compatibility
len = cellfun(@(x)size(x.Values,1),varargin);
if ~all(len == len(1))
  error('Inputs have incompatible signal lengths.')
end

% Build a (temporary) time vector
Time = BuildTimeGroup(varargin{1},'Index',1,'','Time vector');

% Join elements into a dataset
Data.Time = Time;
for k = 1:ninputs
  group = sprintf('group%d',k);
  Data.(group) = varargin{k};
end

% Collect signals into a single group
Signals = CollectSignals(Data);

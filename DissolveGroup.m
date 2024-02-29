function DissolveGroup(Signals,layer)

% DISSOLVEGROUP - Convert a signal group to variables.
% DissolveGroup(Signals,layer)
%
% Converts signals in signal group 'Signals' (i.e., the 
% columns of Signals.Values) to discrete variables in the 
% calling workspace. Variable names are taken from the 
% specified 'layer'.  Signals with empty names are ignored. 
%
% P.G. Bonanni
% 3/29/18

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


% Check 'Signals' input
[flag,valid,errmsg] = IsSignalGroup(Signals);
if ~flag
  error('Input #1 is not a signal group: %s',errmsg)
elseif ~valid
  error('Input #1 is not a valid signal group: %s  See "IsSignalGroup".',errmsg)
end

% In case 'layer' is a source string ...
layer = Source2Layer(layer);

% Check that 'layer' is valid
if ~isfield(Signals,layer)
  error('Specified ''layer'' is not a valid name layer.')
end

% Get variable names
names = Signals.(layer);

% Assign variables in the calling environment
for k = 1:length(names)
  name = names{k};
  if ~isempty(name)
    val = Signals.Values(:,k);
    assignin('caller',names{k},val)
  end
end

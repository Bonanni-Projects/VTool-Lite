function [out1,out2] = ReplaceSignalInGroup(varargin)

% REPLACESIGNALINGROUP - Replace a signal in a signal group.
% Signals = ReplaceSignalInGroup(Signals,name,x)
% Signals = ReplaceSignalInGroup(Signals,oldname,newname,x,units,description,layer)
% [Signals,ismatched] = ReplaceSignalInGroup(...)
%
% Replaces the data column corresponding to the specified 'name' 
% within signal group 'Signals', with vector 'x' providing the new 
% data, and all names on all layers left unmodified.  If 'x' is 
% scalar, it is extended to the appropriate length. 
%
% Alternatively, if the additional arguments are supplied, removes 
% signal 'oldname' from signal group 'Signals' and adds signal 
% 'newname' with corresponding data 'x' in its place.  Inputs 'units' 
% and 'description' are strings specifying the new signal units and 
% description, and 'layer' specifies the name layer on which the new 
% name is to be recorded.  In this case, an empty string name is 
% substituted on the remaining name layers. 
%
% When looking for a match, input 'name' or 'oldname' may refer to 
% any name layer contained in 'Signals'.  However, the empty string 
% name ('') is considered a match only if it appears on all name 
% layers. If 'name' or 'oldname' (or '') refers to more than one 
% signal within the group, the replacement is performed for all 
% matches. 
%
% An error occurs if the specified 'name' or 'oldname' (or '') is 
% not matched.  Optionally, a second output argument 'ismatched' 
% can be supplied to suppress the error and return a binary flag 
% to indicate whether a match was found. 
%
% P.G. Bonanni
% 4/2/18

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


if nargin ~= 3 && nargin ~= 7
  error('Invalid usage.')
end

args = varargin;
Signals = args{1};
name = args{2};
if nargin == 3
  x = args{3};
  mode = 'short';
else  % if nargin == 7
  newname = args{3};
  x = args{4};
  units = args{5};
  description = args{6};
  layer = args{7};
  mode = 'long';
end

% Check 'Signals' input
[flag,valid,errmsg] = IsSignalGroup(Signals);
if ~flag
  error('Input ''Signals'' is not a signal group: %s',errmsg)
elseif ~valid
  error('Input ''Signals'' is not a valid signal group: %s  See "IsSignalGroup".',errmsg)
end

% Check other required inputs
if ~ischar(name)
  error('Input ''name'' or ''oldname'' is invalid.')
elseif ~(isnumeric(x) || islogical(x)) || size(x,2) ~= 1
  error('Input ''x'' must be a column vector or a scalar.')
elseif size(x,1) > 1 && size(x,1) ~= size(Signals.Values,1)
  error('Input ''x'' has the wrong size.')
end

% Find specified signal in the signal group, considering all name layers
index = FindName(name,Signals);  % includes duplicate instances, if any
ismatched = ~isempty(index);
if ~ismatched && nargout < 2
  error('Signal ''%s'' was not found in the signal group.\n',name);
elseif ~ismatched
  out1 = Signals;
  out2 = ismatched;
  return
end

% Signal length
n = size(Signals.Values,1);

% If scalar value provided
if isscalar(x), x=repmat(x,n,1); end

% Insert new signal data in matched column(s)
Signals.Values(:,index) = repmat(x,1,length(index));

% Stop here if the "short" form is being performed
if strcmp(mode,'short')
  out1 = Signals;
  if nargout==2, out2=ismatched; end
  return
end

% Check other inputs
if ~ischar(newname) || isempty(regexp(newname,'^[A-Za-z]\w*$','once'))
  error('Input ''newname'' is invalid.')
elseif ~ischar(units)
  error('Input ''units'' is invalid.')
elseif ~ischar(description)
  error('Input ''description'' is invalid.')
elseif ~ischar(layer)
  error('Input ''layer'' is invalid.')
end

% In case 'layer' is a source string ...
layer = Source2Layer(layer);

% Get name layers
layers = GetLayers(Signals);

% Check if 'layer' exists
if ~ismember(layer,layers)
  error('Input ''layer'' is not a valid name layer.')
end

% Add new signal name and attributes in place of the old
[Signals.(layer){index}]      = deal(newname);      % one or multiple
[Signals.Units{index}]        = deal(units);        % one or multiple
[Signals.Descriptions{index}] = deal(description);  % one or multiple

% Insert '' for non-designated name layers
for c = setdiff(layers(:)',layer)
  [Signals.(c{:}){index}] = deal('');  % one or multiple
end

% Outputs
out1 = Signals;
if nargout==2, out2=ismatched; end

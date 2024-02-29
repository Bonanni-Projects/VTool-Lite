function Signals = AddSignalToGroup(Signals,name,x,units,description,layer)

% ADDSIGNALTOGROUP - Add a signal to a new or existing signal group.
% Signals = AddSignalToGroup(Signals,name,x,units,description,layer)
% Signals = AddSignalToGroup(name,x,units,description,layer)
%
% Adds signal 'x' to the input 'Signals' group.  Inputs 'name', 
% 'units', and 'description' are strings specifying the signal 
% name, units, and description, and 'layer' specifies the 
% name layer on which the name is to be recorded. (An empty 
% string name is placed on the remaining name layers.) 
%
% It is permissible for 'name', 'units', or 'description' to 
% be specified as empty strings.  If 'x' is an empty vector, 
% an all-NaN signal is added.  If 'x' is scalar, it is extended 
% to the appropriate length. 
%
% If 'Signals' is empty or omitted, the function builds a new 
% one-signal group from the provided signal information. 
%
% P.G. Bonanni
% 3/30/18

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


if nargin == 5
  layer       = description;
  description = units;
  units       = x;
  x           = name;
  name        = Signals;
  Signals     = [];
end

% Check inputs
if ~ischar(name) || (~isempty(name) && ...
   isempty(regexp(name,'^[A-Za-z]\w*$','once')))
  error('Input ''name'' is invalid.')
elseif ~isnumeric(x) || (~isempty(x) && size(x,2) ~= 1)
  error('Input ''x'' must be a column vector, or scalar, or [].')
elseif ~ischar(units)
  error('Input ''units'' is invalid.')
elseif ~ischar(description)
  error('Input ''description'' is invalid.')
elseif ~ischar(layer)
  error('Input ''layer'' is invalid.')
end

% If empty strings specified
if isempty(name), name=cellstr(name); end
if isempty(units), units=cellstr(units); end
if isempty(description), description=cellstr(description); end

% In case 'layer' is a source string ...
layer = Source2Layer(layer);

% If 'Signals' provided ...
if ~isempty(Signals)

  % Check 'Signals' input
  [flag,valid,errmsg] = IsSignalGroup(Signals);
  if ~flag
    error('Input ''Signals'' is not a signal group: %s',errmsg)
  elseif ~valid
    error('Input ''Signals'' is not a valid signal group: %s  See "IsSignalGroup".',errmsg)
  end

  % Signal length
  n = size(Signals.Values,1);

  % If empty data vector provided
  if isempty(x), x=nan(n,1); end

  % If scalar value provided
  if isscalar(x), x=repmat(x,n,1); end

  % Check 'x' against data size
  if size(x,1) ~= n || size(x,2) ~= 1
    error('Input ''x'' has the wrong size.')
  end

  % Get name layers
  layers = GetLayers(Signals);

  % Check 'layer' input
  if ~ismember(layer,layers)
    error('Input ''layer'' is not a valid name layer.')
  end

  % Append '' to non-designated name layers
  for c = setdiff(layers(:)',layer)
    Signals.(c{:}){end+1,1} = '';
  end

  % Add new signal to existing group
  Signals.(layer)      = [Signals.(layer);      name];
  Signals.Values       = [Signals.Values,       x];
  Signals.Units        = [Signals.Units;        units];
  Signals.Descriptions = [Signals.Descriptions; description];

else  % if new signal group required

  % Build 'Signals' as a new group
  Signals.(layer)      = {name};
  Signals.Values       = x;
  Signals.Units        = {units};
  Signals.Descriptions = {description};

end

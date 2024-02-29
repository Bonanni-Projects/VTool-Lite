function varargout = IsSignalGroup(Signals,option)

% ISSIGNALGROUP - Identify and check a signal group for validity.
% [flag,valid] = IsSignalGroup(Signals [,'Time'])
% IsSignalGroup(Signals [,'Time'])
%
% Returns a 'flag' value of TRUE if 'Signals' is a 1x1 signal 
% group, and FALSE if not.  The defining criteria considered 
% are: 
%  - 1x1 structure
%  - has one or more field names ending in "Names"
%  - has a 'Values' field
%  - has a 'Units' field
%  - has a 'Descriptions' field
%  - has no other fields
% Returns a 'valid' value of TRUE if the contents of the 
% fields meet the following additional criteria, and FALSE 
% if not: 
%  - 'Values' field is an NxM numerical array 
%  - all remaining fields are Nx1 cell arrays
%  - all 'Names' fields contain valid word strings 
% The 'Time' option string may be supplied as a final argument 
% to indicate that the input is a 'Time' signal group.  In this 
% case, to be considered valid, the 'Values' field must also be 
% Nx1. 
%
% If the signal group is determined to be invalid, output string 
% 'errmsg' indicates the type of error found. 
%
% If called without output arguments, the function reports 
% the results of error checking without returning any outputs. 
%
% See also "IsSignalGroupArray". 
%
% P.G. Bonanni
% 4/4/18

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


if nargin < 2
  option = '';
end

if nargout == 0
  % Report the results of error checking
  [flag,valid,errmsg] = IsSignalGroup(Signals,option);
  if flag && valid
    fprintf('Input is a valid signal group.\n');
  else
    fprintf('Not a valid signal group: %s\n',errmsg)
  end

else
  % Initialize
  flag  = true;
  valid = true;
  errmsg = '';
  varargout = {flag,valid,errmsg};

  % Check if a structure and scalar
  if ~isstruct(Signals)
    flag  = false;
    valid = false;
    errmsg = 'Not a structure.';
    varargout = {flag,valid,errmsg};
    return
  elseif numel(Signals)~=1
    flag  = false;
    valid = false;
    errmsg = 'Not a scalar structure.';
    varargout = {flag,valid,errmsg};
    return
  end

  % Get field names
  fields = fieldnames(Signals);

  % Check non-name layer fields
  if ~ismember('Values',fieldnames(Signals))
    flag  = false;
    valid = false;
    errmsg = 'The ''Values'' field is missing.';
    varargout = {flag,valid,errmsg};
    return
  elseif ~ismember('Units',fieldnames(Signals))
    flag  = false;
    valid = false;
    errmsg = 'The ''Units'' field is missing.';
    varargout = {flag,valid,errmsg};
    return
  elseif ~ismember('Descriptions',fieldnames(Signals))
    flag  = false;
    valid = false;
    errmsg = 'The ''Descriptions'' field is missing.';
    varargout = {flag,valid,errmsg};
    return
  end

  % Ensure remaining fields are name fields
  namefields = setdiff(fields,{'Values','Units','Descriptions'});
  if isempty(namefields)
    flag  = false;
    valid = false;
    errmsg = 'Name fields are missing.';
    varargout = {flag,valid,errmsg};
    return
  elseif any(cellfun(@isempty,regexp(namefields,'Names$')))
    flag  = false;
    valid = false;
    errmsg = 'Contains one or more unrecognized fields.';
    varargout = {flag,valid,errmsg};
    return
  end

  % Check that 'Units' field is a cell array of strings
  if ~iscell(Signals.Units)
    valid = false;
    errmsg = 'The ''Units'' field is not valid.  Must be a cell array.';
    varargout = {flag,valid,errmsg};
    return
  elseif ~all(cellfun(@ischar,Signals.Units))
    valid = false;
    errmsg = sprintf('The ''Units'' field contains one or more non-string entries.');
    varargout = {flag,valid,errmsg};
    return
  end

  % Check 'Values' field
  if ~(length(Signals.Units)==1 && strcmp(Signals.Units{1},'datetime')) && ...
     ~isnumeric(Signals.Values)  % (exception applies for absolute time data)
    valid = false;
    errmsg = 'The ''Values'' field is not of valid type.';
    varargout = {flag,valid,errmsg};
    return
  elseif length(size(Signals.Values)) > 2
    valid = false;
    errmsg = 'The ''Values'' field has dimension > 2.';
    varargout = {flag,valid,errmsg};
    return
  end

  % Number of signals
  nsignals = size(Signals.Values,2);

  % Check 'Names' fields and their contents
  for k = 1:length(namefields)
    field = namefields{k};
    if ~iscell(Signals.(field))
      valid = false;
      errmsg = sprintf('The ''%s'' layer is not a valid cell array.',field);
      varargout = {flag,valid,errmsg};
      return
    elseif any(size(Signals.(field)) ~= [nsignals,1])
      valid = false;
      errmsg = sprintf('The ''%s'' layer has the wrong length or orientation.',field);
      varargout = {flag,valid,errmsg};
      return
    elseif ~all(cellfun(@ischar,Signals.(field)))
      valid = false;
      errmsg = sprintf('The ''%s'' layer contains one or more non-string entries.',field);
      varargout = {flag,valid,errmsg};
      return
    end
    names1 = Signals.(field);
    names1(cellfun(@isempty,names1)) = [];  % non-empty names
    if any(cellfun(@isempty,regexp(names1,'^[A-Za-z]\w*$')))
      valid = false;
      errmsg = sprintf('The ''%s'' layer contains one or more invalid names.',field);
      varargout = {flag,valid,errmsg};
      return
    end
  end

  % Check 'Units' field for proper size and orientation
  if any(size(Signals.Units) ~= [nsignals,1])
    valid = false;
    errmsg = sprintf('The ''Units'' field has the wrong length or orientation.');
    varargout = {flag,valid,errmsg};
    return
  end

  % Check 'Descriptions' field
  if ~iscell(Signals.Descriptions)
    valid = false;
    errmsg = 'The ''Descriptions'' field is not valid.  Must be a cell array.';
    varargout = {flag,valid,errmsg};
    return
  elseif ~all(cellfun(@ischar,Signals.Descriptions))
    valid = false;
    errmsg = sprintf('The ''Descriptions'' field contains one or more non-string entries.');
    varargout = {flag,valid,errmsg};
    return
  elseif any(size(Signals.Descriptions) ~= [nsignals,1])
    valid = false;
    errmsg = sprintf('The ''Descriptions'' field has the wrong length or orientation.');
    varargout = {flag,valid,errmsg};
    return
  end

  % Additional requirement for 'Time' signal groups
  if strcmp(option,'Time') && nsignals ~= 1
    flag  = false;
    valid = false;
    errmsg = '''Time'' signal groups must contain a single data column.';
    varargout = {flag,valid,errmsg};
    return
  end
end

function varargout = IsSarray(S)

% ISSARRAY - Identify and check an S-array for validity.
% [flag,valid] = IsSarray(S)
% IsSarray(S)
%
% Returns a 'flag' value of TRUE if 'S' is an S-array, and 
% FALSE if not.  The defining criteria considered are: 
%  - structure array
%  - each element has the standard fields:
%       'name'         -  signal name string (type 'char')
%       'data'         -  data vector (numerical, column vector)
%       'dt'           -  sample time (numerical, constant or column vector)
%       'unitsT'       -  time units string (type 'char')
%       'units'        -  signal units string (type 'char')
%       'description'  -  signal description string (type 'char')
%       'trigger'      -  start time (scalar value or date vector)
%  If 'S(i).dt' is a vector, its length must be length(S(i).data)-1 
%
% If the S-array is determined to be invalid, output string 
% 'errmsg' indicates the type of error found. 
%
% If called without output arguments, the function reports 
% the results of error checking without returning any outputs. 
%
% P.G. Bonanni
% 10/30/19

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


if nargout == 0
  % Report the results of error checking
  [flag,valid,errmsg] = IsSarray(S);
  if flag && valid
    fprintf('Input is a valid S-array.\n');
  else
    fprintf('Not a valid S-array: %s\n',errmsg)
  end

else
  % Initialize
  flag  = true;
  valid = true;
  errmsg = '';
  varargout = {flag,valid,errmsg};

  % Check if a structure array
  if ~isstruct(S)
    flag  = false;
    valid = false;
    errmsg = 'Not a structure array.';
    varargout = {flag,valid,errmsg};
    return
  end

  % Check if standard fields are present
  fields = {'name','data','dt','unitsT','units','description','trigger'};
  if ~isempty(setdiff(fields,fieldnames(S)))
    flag  = false;
    valid = false;
    errmsg = 'Array has missing or invalid field(s).';
    varargout = {flag,valid,errmsg};
    return
  end

  % Check 'name' fields
  Names = {S.name};
  if ~all(cellfun(@ischar,Names))
    valid = false;
    errmsg = 'One or more ''name'' values is not ''char'' type.';
    varargout = {flag,valid,errmsg};
    return
  elseif any(cellfun(@isempty,regexp(Names,'^[A-Za-z]\w*$')))
    valid = false;
    errmsg = 'One or more ''name'' values is not valid.';
    varargout = {flag,valid,errmsg};
    return
  end

  % Check 'data' fields
  Data = {S.data};
  if ~all(cellfun(@(x)isnumeric(x),Data))
    valid = false;
    errmsg = 'One or more ''data'' values is not valid.';
    varargout = {flag,valid,errmsg};
    return
  elseif any(cellfun(@isempty,Data))
    valid = false;
    errmsg = 'One or more ''data'' values is empty.';
    varargout = {flag,valid,errmsg};
    return
  elseif ~all(cellfun(@iscolumn,Data))
    valid = false;
    errmsg = 'One or more ''data'' values has the wrong format.';
    varargout = {flag,valid,errmsg};
    return
  end

  % Check 'dt' fields
  DT = {S.dt};
  if ~all(cellfun(@isnumeric,DT))
    valid = false;
    errmsg = 'One or more ''dt'' values is not valid.';
    varargout = {flag,valid,errmsg};
    return
  elseif any(cellfun(@isempty,DT))
    valid = false;
    errmsg = 'One or more ''dt'' values is empty.';
    varargout = {flag,valid,errmsg};
    return
  elseif ~all(cellfun(@iscolumn,DT))
    valid = false;
    errmsg = 'One or more ''dt'' values has the wrong format.';
    varargout = {flag,valid,errmsg};
    return
  elseif any(arrayfun(@(s)~isscalar(s.dt)&&(length(s.dt)~=length(s.data)-1),S))
    valid = false;
    errmsg = 'One or more ''dt'' values has the wrong length.';
    varargout = {flag,valid,errmsg};
    return
  end

  % Check 'unitsT' fields
  UnitsT = {S.unitsT};
  if ~all(cellfun(@ischar,UnitsT))
    valid = false;
    errmsg = 'One or more ''unitsT'' values is not ''char'' type.';
    varargout = {flag,valid,errmsg};
    return
  elseif length(S) > 1 && ~isequal(UnitsT{:})
    valid = false;
    errmsg = 'Array is not homogeneous: ''unitsT'' values differ.';
    varargout = {flag,valid,errmsg};
    return
  end

  % Check 'units' fields
  Units = {S.units};
  if ~all(cellfun(@ischar,Units))
    valid = false;
    errmsg = 'One or more ''units'' values is not ''char'' type.';
    varargout = {flag,valid,errmsg};
    return
  end

  % Check 'description' fields
  Descriptions = {S.description};
  if ~all(cellfun(@ischar,Descriptions))
    valid = false;
    errmsg = 'One or more ''description'' values is not ''char'' type.';
    varargout = {flag,valid,errmsg};
    return
  end

  % Check 'trigger' fields
  Triggers = {S.trigger};
  fun1 = @(x)isnumeric(x) && isempty(x);
  fun2 = @(x)isnumeric(x) && isscalar(x);
  fun3 = @(x)isa(x,'datetime') && isscalar(x);
  fun4 = @(x)isnumeric(x) && isrow(x) && length(x)==6;
  if ~all(cellfun(fun1,Triggers) | cellfun(fun2,Triggers) | ...
          cellfun(fun3,Triggers) | cellfun(fun4,Triggers))
    valid = false;
    errmsg = 'One or more ''trigger'' values is not valid.';
    varargout = {flag,valid,errmsg};
    return
  elseif length(S) > 1 && ~isequal(Triggers{:})
    valid = false;
    errmsg = 'Array is not homogeneous: ''trigger'' values differ.';
    varargout = {flag,valid,errmsg};
    return
  end
end

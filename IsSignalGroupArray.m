function varargout = IsSignalGroupArray(SIGNALS,option)

% ISSIGNALGROUPARRAY - Identify and check a signal group array for validity.
% [flag,valid,errmsg] = IsSignalGroupArray(SIGNALS [,'Time'])
% IsSignalGroupArray(SIGNALS [,'Time'])
%
% Returns a 'flag' value of TRUE if 'SIGNALS' is a signal group 
% array of length one or more, and FALSE if not. The input is 
% recognized as a signal group array if each of its elements 
% is a signal group (see "IsSignalGroup").  To return a 'valid' 
% value of TRUE, all elements must be valid, and in addition 
% have homogeneous name layers and units, (i.e., share the same 
% names, name order, and units on all layers). The 'Time' option 
% specifies that tests applicable to an array of 'Time' signal 
% groups be applied.  These include 'Time'-group-specific testing 
% on each array element, and testing  that data type and time 
% units are compatible across the array. 
% 
% If the signal group array is determined to be invalid, 
% output string 'errmsg' indicates the type of error found. 
% If called without output arguments, the function reports 
% the results of error checking without returning any outputs. 
%
% P.G. Bonanni
% 4/6/18

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


if nargin < 2
  option = '';
end

if nargout == 0
  % Report the results of error checking
  [flag,valid,errmsg] = IsSignalGroupArray(SIGNALS,option);
  if flag && valid
    fprintf('Input is a valid signal group array.\n');
  else
    fprintf('Not a valid signal group array: %s\n',errmsg)
  end

else
  % Initialize
  flag  = true;
  valid = true;
  errmsg = '';
  varargout = {flag,valid,errmsg};

  % Check if a structure
  if ~isstruct(SIGNALS)
    flag  = false;
    valid = false;
    errmsg = 'Not a structure.';
    varargout = {flag,valid,errmsg};
    return
  end

  % Check individual elements
  [Flag,Valid] = arrayfun(@(x)IsSignalGroup(x,option),SIGNALS);
  if ~all(Flag(:))
    flag  = false;
    valid = false;
    errmsg = 'Not a signal group array.';
    varargout = {flag,valid,errmsg};
    return
  elseif ~all(Valid(:))
    flag  = false;
    valid = false;
    str = sprintf('%d,',find(~Valid)); str(end)=[];
    errmsg = sprintf('Contains one or more invalid elements(s): [%s].',str);
    varargout = {flag,valid,errmsg};
    return
  end

  % Check name layers for homogeneity
  if numel(SIGNALS) > 1
    C = arrayfun(@GetNamesMatrix,SIGNALS,'Uniform',false);
    if ~all(isequal(C{:}))
      valid = false;
      errmsg = 'Non-homogeneous signal group array. Names do not match.';
      varargout = {flag,valid,errmsg};
      return
    end
  end

  % Check units for homogeneity
  if numel(SIGNALS) > 1
    C = arrayfun(@(x)x.Units,SIGNALS,'Uniform',false);
    if ~all(isequal(C{:}))
      % Find signals with inconsistent units
      UNITS = cat(2,C{:});
      names = GetDefaultNames(SIGNALS(1));
      for k = 1:size(UNITS,1)
        row = UNITS(k,:);
        [row{cellfun(@(x)isnumeric(x)&&isempty(x),row)}] = deal('');
        if length(unique(row)) == 1
          names{k} = '';
        end
      end
      names(cellfun(@isempty,names)) = [];
      list = sprintf('''%s'' ',names{:});  list(end)=[];
      % ---
      valid = false;
      errmsg = sprintf('Non-homogeneous signal group array. These signals have inconsistent units: %s.',list);
      varargout = {flag,valid,errmsg};
      return
    end
  end

  % If 'Time' option specified ...
  if numel(SIGNALS) > 1 && strcmp(option,'Time')
    if ~isequal(SIGNALS.Units)
      valid = false;
      errmsg = 'Incompatible/non-uniform time units.';
      varargout = {flag,valid,errmsg};
      return
    end
  end
end

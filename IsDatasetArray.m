function varargout = IsDatasetArray(DATA)

% ISDATASETARRAY - Identify and check a dataset array for validity.
% [flag,valid,errmsg] = IsDatasetArray(DATA)
% IsDatasetArray(DATA)
%
% Returns a 'flag' value of TRUE if 'DATA' is a dataset array of 
% length one or more, and FALSE if not.  The input is recognized 
% as a dataset array if each of its elements is a dataset (see 
% "IsDataset").  To return a 'valid' value of TRUE, all elements 
% must be valid, and in addition have homogeneous name layers and 
% units across all included signal groups, (i.e., share the same 
% names, name order, and units on all layers). Also, the included 
% 'Time' groups, while possibly different in value, must have 
% compatible data types and be expressed in the same units. 
% 
% If the dataset array is determined to be invalid, output 
% string 'errmsg' indicates the type of error found.  If called 
% without output arguments, the function reports the results of 
% error checking without returning any outputs. 
%
% P.G. Bonanni
% 4/7/18

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


if nargout == 0
  % Report the results of error checking
  [flag,valid,errmsg] = IsDatasetArray(DATA);
  if flag && valid
    fprintf('Input is a valid dataset array.\n');
  else
    fprintf('Not a valid dataset array: %s\n',errmsg)
  end

else
  % Initialize
  flag  = true;
  valid = true;
  errmsg = '';
  varargout = {flag,valid,errmsg};

  % Check if a structure
  if ~isstruct(DATA)
    flag  = false;
    valid = false;
    errmsg = 'Not a structure.';
    varargout = {flag,valid,errmsg};
    return
  end

  % Check individual elements
  [Flag,Valid] = arrayfun(@IsDataset,DATA);
  if ~all(Flag(:))
    flag  = false;
    valid = false;
    errmsg = 'Not a dataset array.';
    varargout = {flag,valid,errmsg};
    return
  elseif ~all(Valid(:))
    valid = false;
    str = sprintf('%d,',find(~Valid)); str(end)=[];
    errmsg = sprintf('Contains one or more invalid elements(s): [%s].',str);
    varargout = {flag,valid,errmsg};
    return
  end

  % Check name layers for homogeneity
  if numel(DATA) > 1
    C = arrayfun(@GetNamesMatrix,DATA,'Uniform',false);
    if ~all(isequal(C{:}))
      valid = false;
      errmsg = 'Non-homogeneous array. Names and/or name orders do not match.';
      varargout = {flag,valid,errmsg};
      return
    end
  end

  % Check units for homogeneity
  if numel(DATA) > 1
    C = cell(size(DATA));  % initialize
    for k = 1:numel(DATA)
      Signals = CollectSignals(DATA(k));
      C{k} = Signals.Units;
    end
    if ~all(isequal(C{:}))
      % Find signals with inconsistent units
      UNITS = cat(2,C{:});
      names = GetDefaultNames(DATA(1));
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
      errmsg = sprintf('Non-homogeneous array. These signals have inconsistent units: %s.',list);
      varargout = {flag,valid,errmsg};
      return
    end
  end

  % Check 'Time' groups for compatibility
  if numel(DATA) > 1
    Times = cat(1,DATA.Time);
    if ~all(isequal(Times.Units))
      valid = false;
      errmsg = 'Datasets have incompatible time vectors.';
      varargout = {flag,valid,errmsg};
      return
    end
  end
end

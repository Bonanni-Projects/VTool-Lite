function s = CollapseSarray(S,sourcetype,option)

% COLLAPSESARRAY - Collapse an S-array into dataset form.
% s = CollapseSarray(S [,sourcetype])
% s = CollapseSarray(..., 'nowarn')
%
% Converts input S-array 'S', returning output 's' in a generic 
% VTool dataset format.  Signals are re-sampled onto a common time grid, 
% determined by the smallest sample time found in the array, normalized 
% to a common data type ('uint16', 'single', 'double', etc.), assembled 
% in "signal groups", and returned as fields of structure 's'.  Each 
% group is a structure with the following fields: 
%    'Names'         -  cell array of signal names
%    'Values'        -  matrix with columns containing signal sequences
%    'Units'         -  cell array of unit designations ('m', 'kN', etc.)
%    'Descriptions'  -  cell array of signal descriptions. 
% Input 'S' is a structure array, with each S(i) having fields: 
%    'name'          -  signal name string
%    'data'          -  data vector
%    'dt'            -  sample time (scalar or vector)
%    'unitsT'        -  time units string
%    'units'         -  signal units string(*)
%    'description'   -  signal description string
%    'trigger'       -  start time(*) (scalar value, or 
%                       1x6 date vector, or date string)
% The re-sampling operation employs previous-neighbor interpolation 
% for 'data' of integer type, and linear interpolation otherwise. 
% Type "help formats" and see function "IsSarray" for additional 
% information on S-array format. 
%
% Input 'sourcetype' is an optional string-valued input corresponding 
% to a "source tab" within the applicable "NameTables.xls" file.  If 
% a 'sourcetype' is specified, all group definitions, signal scaling, 
% units conversions, and description modifications consistent with the 
% definition of 'sourcetype' within "NameTables.xlsx" are applied to 
% the result.  However, if no 'sourcetype' is specified, all signals 
% in the array are returned as a master signal group 'All', and no 
% modification of the contents, beyond the resampling, is performed. 
%
% A warning normally results if one or more signal names specified in 
% "NameTables.xlsx" is not present in the array.  The 'nowarn' option, 
% specified as a final argument, suppresses this warning. 
%
% (*) NOTE: Fields 'unitsT' and 'trigger' are required to be uniform 
% across the array. 
%
% See also "MakeSarray", "DataToSarray".  
%
% P.G. Bonanni
% 10/23/19

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


if nargin == 1
  sourcetype = '';
  option = '';
elseif nargin == 2
  if ischar(sourcetype) && strcmp(sourcetype,'nowarn')
    sourcetype = '';
    option = 'nowarn';
  else
    option = '';
  end
end

% Determine if Matlab version is from 2014 or later
if datenum(version('-date')) > datenum('1-Jun-2014')
  laterVersion = true;
else  % if version is older
  laterVersion = false;
end

% Check 'S' input
[flag,valid] = IsSarray(S);
if ~flag || ~valid
  error('Input ''S'' is not a valid S-array.  See "IsSarray".')
elseif isempty(S)
  error('Input S-array is empty.');
end

% Check 'sourcetype' input
if ~ischar(sourcetype)
  error('Input ''sourcetype'' is not valid.')
end

% Check that 'unitsT' and 'trigger' are consistent
if length(S) > 1 && ~(isequal(S.unitsT) && isequal(S.trigger))
  error('Fields ''unitsT'' and ''trigger'' are required to be equal for all array elements.');
end

% Get and check time units
unitsT = S(1).unitsT;
if ~ischar(unitsT)
  fprintf('Field ''unitsT'' is invalid.\n');
end

% Check/repair 'trigger' value
trigger = S(1).trigger;
if isnumeric(trigger) && isempty(trigger) && ~isempty(unitsT)
  fprintf('Trigger value is empty.  Assuming elapsed time starting from 0.\n');
elseif isnumeric(trigger) && isempty(trigger) && isempty(unitsT)
  fprintf('Trigger value is empty.  Assuming index vector starting from 1.\n');
elseif isnumeric(trigger) && isscalar(trigger) && ~isempty(unitsT)
  fprintf('Trigger value specifies a start time of %g %s.\n',trigger,unitsT);
elseif isnumeric(trigger) && isscalar(trigger) && isempty(unitsT)
  fprintf('Trigger value specifies a start value of %g.\n',trigger);
else
  try start = datenum(trigger);
  catch
    fprintf('Trigger value is invalid.  Assuming time in elapsed seconds.\n');
    trigger = [];
  end
end

% Record signal lengths
for k = 1:length(S)
  S(k).npoints = length(S(k).data);
end

% Fix "constant" signals
for k = 1:length(S)
  if S(k).npoints == 1
    S(k).data = [S(k).data; S(k).data];
    S(k).npoints = 2;
  end
end

% Build time vectors, by signal
for k = 1:length(S)
  dt = S(k).dt;
  if isscalar(dt)
    npoints = S(k).npoints;
    S(k).t = dt*(0:npoints-1)';
  else  % if 'dt' is a vector
    S(k).t = [0; cumsum(dt)];
  end
end

% Set global time vector and data length
[~,i] = max([S.npoints]);  % ... based on most finely sampled signal
npoints = S(i).npoints;  t = S(i).t;

% Re-sample the coarsely sampled signals
for k = 1:length(S)
  if S(k).npoints ~= npoints
    class0 = class(S(k).data);
    if any(strcmp(class0,{'double','single'}))
      S(k).data = interp1(S(k).t,S(k).data,t,'linear','extrap');
    else  % if integer data type (e.g., "status" signals)
      S(k).data = interp1(S(k).t,double(S(k).data),t,'previous','extrap');
    end
    S(k).t = t;
  end
end

% Normalize all data to the same class; use 'double' if any 'double' present
Class = arrayfun(@(x)class(x.data),S,'Uniform',false);
if any(strcmp(Class,'double'))
  mask = ~strcmp(Class,'double');
  for k = find(mask)'
    S(k).data = double(S(k).data);
  end
elseif any(strcmp(Class,'single'))
  mask = ~strcmp(Class,'single');
  for k = find(mask)'
    S(k).data = single(S(k).data);
  end
end

% Build master signal group
Master.Names        = {S.name}';
Master.Values       = cat(2,S.data);
Master.Units        = {S.units}';
Master.Descriptions = {S.description}';

% ------------------------------------------
% Extract signals and append to output
% ------------------------------------------

% If 'sourcetype' specified ...
if ~isempty(sourcetype)

  % Read signal group info from Excel file
  [Names,Factors,Units,Descriptions] = ReadSourceTab(sourcetype);

else
  % Source type for this function
  sourcetype = '';

  % Request all available signals, and ensure that no 
  % modification of the original data is performed. 
  n = length(Master.Names);
  Names.All        = Master.Names;
  Factors.All      = repmat({''},n,1);
  Units.All        = repmat({''},n,1);
  Descriptions.All = repmat({''},n,1);
end

% Source type indicator
s.sourcetype = sourcetype;

% Build 'Time' group
if isempty(trigger) && ~isempty(unitsT)  % empty 'trigger' with non-empty 'unitsT'
  % Build time in elapsed units
  s.Time.Names        = {'Time'};
  s.Time.Values       = t;
  s.Time.Units        = {unitsT};
  s.Time.Descriptions = {'Time vector'};
elseif isempty(trigger) && ~isempty(unitsT)  % empty 'trigger' with unitsT = ''
  % Build time as an index vector
  s.Time.Names        = {'Index'};
  s.Time.Values       = 1 + t;
  s.Time.Units        = {unitsT};
  s.Time.Descriptions = {'Index vector'};
elseif isnumeric(trigger) && isscalar(trigger) && trigger < 1e5 && ~isempty(unitsT)  % real 'trigger' with non-empty 'unitsT'
  % Build time in the required units offset by trigger value
  s.Time.Names        = {'Time'};
  s.Time.Values       = trigger + t;
  s.Time.Units        = {unitsT};
  s.Time.Descriptions = {'Time vector'};
elseif isnumeric(trigger) && isscalar(trigger) && trigger < 1e5 && isempty(unitsT)  % real 'trigger' with unitsT = ''
  % Build time as an index vector offset by trigger value
  s.Time.Names        = {'Index'};
  s.Time.Values       = trigger + t;
  s.Time.Units        = {unitsT};
  s.Time.Descriptions = {'Index vector'};
else  % if 'trigger' is a 1x6 date vector, or of 'datetime' or 'datenum' type
  % Convert 't' to seconds
  if ~strcmp(unitsT,'sec')
    switch unitsT
      case 'msec',  t = t/1000;
      case 'min',   t = t*60;
      case 'hrs',   t = t*60*60;
      case 'days',  t = t*60*60*24;
      otherwise fprintf('Time units ''%s'' not supported with supplied ''trigger'' value.\n',unitsT);
    end
  end

  % Get start time, and build absolute time vector
  if laterVersion  % use 'datetime' type if possible
    start = datetime(trigger);
    s.Time.Names        = {'Time'};
    s.Time.Values       = start + seconds(t);
    s.Time.Units        = {'datetime'};
    s.Time.Descriptions = {'Time vector'};
  else  % use 'datenum' if older Matlab version
    start = datenum(trigger);
    s.Time.Names        = {'Time'};
    s.Time.Values       = start + t/86400;
    s.Time.Units        = {'datenum'};
    s.Time.Descriptions = {'Time vector'};
  end
end

% List of signal groups
fields = fieldnames(Names);

% Extract named signals
for k = 1:length(fields)
  field = fields{k};
  if ~strcmp(option,'nowarn')
    s.(field) = SelectFromGroup(Names.(field),Master);
  else  % second output argument suppresses warnings
    [s.(field),~] = SelectFromGroup(Names.(field),Master);
  end

  % Apply conversion factor and assign new units as follows:
  % - If both 'factor' and 'units' are blank, make no change.
  % - If 'factor' not specified, and 'units' specified, determine factor, apply conversion, and assign new units.
  % - If 'factor' specified as NaN (originally '*' in NameTables), replace signal with all-NaNs.
  % - If 'units' specified as '*', assign empty units, i.e., ''.
  % - Otherwise, if 'factor' blank, apply no conversion, and if 'units' blank, leave units unchanged.
  % Apply new 'description' if not blank.
  for j = 1:length(s.(field).Names)
    [~,i] = ismember(s.(field).Names{j},Names.(field));
    % ---
    factor = Factors.(field){i};
    units = Units.(field){i};
    if isempty(factor) && ~isempty(units) && ~strcmp(units,'*')  % If only 'units' specified (excluding '*'),
      factor = ConversionFactor(s.(field).Units{j}, units);      % determine the conversion factor, 
      if ~isnan(factor)                                          % and if successful ...
        s.(field).Values(:,j) = s.(field).Values(:,j) * factor;  %   apply conversion
        s.(field).Units{j} = units;                              %   assign new units
      else  % if conversion factor could not be determined
        fprintf('*** WARNING: No conversion from ''%s'' to ''%s'' performed for signal ''%s''.\n', ...
                s.(field).Units{j}, units, s.(field).Names{j});
      end
    else
      if ~isempty(factor)                                        % If 'factor' specified (including '*' == NaN), 
        s.(field).Values(:,j) = s.(field).Values(:,j) * factor;  %   apply conversion
      end
      if ~isempty(units)                                         % If 'units' specified, 
        if strcmp(units,'*'), units=''; end                      %   interpret '*' as '', 
        s.(field).Units{j} = units;                              %   assign new units
      end
    end
    % ---
    description = Descriptions.(field){i};
    if ~isempty(description)                                     % if not empty, 
      s.(field).Descriptions{j} = description;                   %   assign new description
    end
  end
end

function MakeVtlFile(pathname,t,Values,Names,Units,Descriptions,sourcetype)

% MAKEVTLFILE - Make a .vtl file from time-synchronized data.
% MakeVtlFile(pathname,t,Values,Names,Units,Descriptions,sourcetype)
% MakeVtlFile(pathname,t,Values,[],[],[],sourcetype)
%
% Saves a .vtl file constructed from "time synchronized" data to 
% the specified 'pathname' (and overwriting any existing file if 
% present).  Time synchronization implies that a single time vector 
% 't' applies to all signals, with signals arranged as columns of 
% a 'Values' matrix. 
%
% Inputs to the function are as follows: 
%    't'             -  Nx1 time vector, either real-valued or in 
%                       absolute-time units ('datetime', 'datenum'), 
%    'Values'        -  NxM values array, representing M signals of 
%                       length N, 
%    'Names'         -  (OPTIONAL) length-M cell array of signal 
%                       names, defaulting to {'x1','x2',...,'xM'} 
%                       if [] is specified, 
%    'Units'         -  (OPTIONAL) length-M cell array of units 
%                       designations, defaulting to empty strings 
%                       {'','',...} if [] is specified, 
%    'Descriptions'  -  (OPTIONAL) length-M cell array of signal 
%                       descriptions, defaulting to empty strings 
%                       {'','',...} if [] is specified, 
%    'sourcetype'    -  sourcetype identification string. 
%
% Parameter 'sourcetype' is a string-valued input corresponding 
% to a "source tab" within the applicable "NameTables.xls" file.  
% All group definitions, signal scaling, units conversions, and 
% description modifications consistent with the definition of 
% 'sourcetype' within "NameTables.xlsx" are applied to the data 
% before storing in the output file.  However, if 'sourcetype' 
% is given as '', no modifications are performed. 
%
% See also "MakeSarrayFile". 
%
% P.G. Bonanni
% 7/8/19

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


% Determine if Matlab version is from 2014 or later
if datenum(version('-date')) > datenum('1-Jun-2014')
  laterVersion = true;
else  % if version is older
  laterVersion = false;
end

% Check inputs
if ~ischar(pathname)
  error('Input ''pathname'' is invalid.')
elseif ~isvector(t)
  error('Time vector ''t'' is invalid')
elseif ~isnumeric(Values) || ~ismatrix(Values)
  error('The ''Values'' array is invalid.')
elseif size(Values,1) ~= length(t)
  error('The ''Values'' array is not compatible with the provided time vector.')
elseif ~ischar(sourcetype)
  error('Input ''sourcetype'' is invalid.')
end

% Build default components as necessary
if isnumeric(Names) && isempty(Names)
  Names = strcat({'x'},strread(num2str(1:size(Values,2)),'%s'));
end
if isnumeric(Units) && isempty(Units)
  Units = repmat({''},size(Values,2),1);
end
if isnumeric(Descriptions) && isempty(Descriptions)
  Descriptions = repmat({''},size(Values,2),1);
end

% Additional input checks
if ~iscellstr(Names) || ~isvector(Names)
  error('Input ''Names'' is invalid.  Specify a cell array of strings, or [].')
elseif length(Names) ~= size(Values,2)
  error('The ''Names'' list does not match the number of signals.')
elseif ~iscellstr(Units) || ~isvector(Units)
  error('Input ''Units'' is invalid.  Specify a cell array of strings, or [].')
elseif length(Units) ~= size(Values,2)
  error('The ''Units'' list does not match the number of signals.')
elseif ~iscellstr(Descriptions) || ~isvector(Descriptions)
  error('Input ''Descriptions'' is invalid.  Specify a cell array of strings, or [].')
elseif length(Descriptions) ~= size(Values,2)
  error('The ''Descriptions'' list does not match the number of signals.')
end

% Determine time units
if laterVersion && isdatetime(t)     % if 't' is 'datetime' type
  time_units = 'datetime';
elseif isnumeric(t) && all(t > 1e5)  % interpret 't' as date numbers
  time_units = 'datenum';
elseif isnumeric(t)                  % interpret 't' as elapsed seconds
  time_units = 'sec';
end

% Make columns
t            = t(:);
Names        = Names(:);
Units        = Units(:);
Descriptions = Descriptions(:);

% Build 'Time' group
Time.Names = {'Time'};
Time.Values = t;
Time.Units = {time_units};
Time.Descriptions = {'Time Vector'};

% Build 'All' signal group
All.Names = Names;
All.Values = Values;
All.Units = Units;
All.Descriptions = Descriptions;

% Build dataset structure
s.sourcetype = sourcetype;
s.Time       = Time;
s.All        = All;

% If 'sourcetype' is registered in "NameTables.xlsx" ...
if ~isempty(which('NameTables.xlsx')) && ismember(sourcetype,ListSourceTypes)
  fprintf('Applying modifications for source type ''%s''.\n',sourcetype);

  % Read signal group info from Excel file
  [Names,Factors,Units,Descriptions] = ReadSourceTab(sourcetype);

  % Define new groups on the dataset
  groups = fieldnames(Names);
  for k = 1:length(groups)
    group = groups{k};
    s = DefineSignalGroup(s,group,Names.(group));
  end

  % Remove the 'All' group if not included in 'groups'
  if ~ismember('All',groups), s=rmfield(s,'All'); end

  % List of signal groups to process
  fields = setdiff(fieldnames(s),{'sourcetype','Time'});

  % Process the dataset
  for k = 1:length(fields)
    field = fields{k};

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

elseif ~isempty(which('NameTables.xlsx')) 
  % Warn about unregistered status of 'sourcetype'
  fprintf('Source type ''%s'' not registered in "NameTables.xlsx". No units conversions or description modifications applied.\n',sourcetype);

else
  % Warn about unregistered status of 'sourcetype' and missing "NameTables.xlsx"
  fprintf('Source type ''%s'' not registered. "NameTables.xlsx" file not found. No units conversions or description modifications applied.\n',sourcetype);
end

% Check output pathname for .vtl extension
[~,~,ext] = fileparts(pathname);
if ~strcmp(ext,'.vtl')
  pathname = [pathname,'.vtl'];
end

% Save results to .vtl file
fprintf('Writing file "%s".\n',pathname);
save('-mat',pathname,'-struct','s')

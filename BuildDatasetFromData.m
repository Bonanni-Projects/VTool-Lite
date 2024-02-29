function Data = BuildDatasetFromData(varargin)

% BUILDDATASETFROMDATA - Build a dataset from raw time and signal data.
% Data = BuildDatasetFromData([ t ],Values)
% Data = BuildDatasetFromData(Table)
% Data = BuildDatasetFromData(s1)
% Data = BuildDatasetFromData(S)
% Data = BuildDatasetFromData(...,source)
%
% Builds a dataset from raw signal data. The signal and attribute data 
% are supplied in one of several ways: 
%
%   - Time vector 't' and column-oriented 'Values' array, where length 
%     of time vector matches number of rows in 'Values'.  Time 't' is 
%     assumed in 'sec' units if not given in absolute units ('datetime' 
%     or 'datenum'), and if 't' is omitted, a unitless 'Index' is assumed, 
%     starting at value 1.  The M columns of the 'Values' array are 
%     assigned generic signal names 'x1', 'x2', ..., 'xM', and all 
%     signal units and descriptions are set to the empty string (''). 
%
%   - Table or timetable 'Table'. Time is determined by the 'RowTimes' 
%     property or by a 'Time' column, if present. If not, a unitless 
%     'Index' is assumed, starting at value 1. Columns with non-numeric 
%     data are ignored. Multi-dimensional data are handled by expansion 
%     into an equivalent set of one-dimensional signals per the note 
%     below (*).
%
%   - Scalar structure 's1' with column-oriented fields having equal 
%     number of rows.  Time is determined by a 'Time' field, if present. 
%     If not, unitless 'Index' is assumed, starting at 1. Field names 
%     are taken as variable names, but all units and descriptions are 
%     set to the empty string (''). Fields with non-numeric data are 
%     ignored.  Matrix-valued and multi-dimensional fields are handled 
%     by expansion into an equivalent set of one-dimensional signals 
%     as described below (*). 
%
%   - S-array 'S', wherein all signal names and attributes are taken 
%     directly from fields of structure array 'S'.  For a description 
%     of the S-array data structure, see function "MakeSarray" or type 
%     "help formats". 
%
% (*) In the case of 2- or higher dimensional array data, the array is 
% expanded into an equivalent set of 1-dimensional column vectors to 
% produce a new set of 1-dimensional signals.  The corresponding variable 
% name is interpreted as a root name, and appropriate subscripting with 
% trailing numerals is used to name the individual signals. The underscore 
% character '_' is employed where necessary to separate the subscripts.  
% Units and descriptions are replicated across the expanded set of signals. 
%
% An optional final string argument 'source' can be provided 
% if specification of a dataset source is desired. 
%
% See also "CollapseSarray", "DataToSarray". 
%
% P.G. Bonanni
% 7/8/19, updated 7/11/23

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


args = varargin;
if isempty(args)
  error('Invalid usage.')
end
source = [];  % initialize
if ischar(args{end}) || ...
   isnumeric(args{end}) && isempty(args{end}) && (nargin==3 || nargin==2 && ~isnumeric(args{1}))
  source = args{end};
  args(end) = [];
end
if isstruct(args{1}) && ...
   all(ismember({'units','description'},fieldnames(args{1})))
  if length(args) ~= 1
    error('Invalid usage.')
  end
  option = 'S-array';
  S = args{1};
elseif isa(args{1},'table')
  if length(args) ~= 1
    error('Invalid usage.')
  end
  option = 'table';
  Table = args{1};
elseif isa(args{1},'timetable')
  if length(args) ~= 1
    error('Invalid usage.')
  end
  option = 'timetable';
  Table = args{1};
elseif isstruct(args{1}) && isscalar(args{1})
  if length(args) ~= 1
    error('Invalid usage.')
  end
  option = 'struct';
  s1 = args{1};
else
  if length(args) == 1
    option = '';
    nameT  = 'Index';
    descT  = 'Index vector';
    Values = args{1};
    t = (1:size(Values,1))';
  elseif length(args) == 2
    option = '';
    nameT  = 'Time';
    descT  = 'Time vector';
    t      = args{1};
    Values = args{2};
  else
    error('Invalid usage.')
  end
end

% Determine if Matlab version is from 2014 or later
if datenum(version('-date')) > datenum('1-Jun-2014')
  laterVersion = true;
else  % if version is older
  laterVersion = false;
end

% If 'S-array' provided ...
if strcmp(option,'S-array')

  % Check 'S' input
  [flag,valid] = IsSarray(S);
  if ~flag || ~valid
    error('Input ''S'' is not a valid S-array.  See "IsSarray".')
  elseif isempty(S)
    error('Input S-array is empty.');
  end

  % Collapse S-array and remove 'sourcetype' field
  Data = CollapseSarray(S,'');
  Data = RenameField(Data,'All','Signals');
  Data = rmfield(Data,'sourcetype');

elseif strcmp(option,'table')

  % Check 'Table' input
  if isempty(Table)
    error('Input ''Table'' is empty.');
  end

  % Get initial variable names
  Names = Table.Properties.VariableNames;

  % Determine size parameters
  nsignals = length(Names);
  npoints = size(Table.(Names{1}),1);

  % Retrieve and remove the 'Time' column, or build 'Index' vector. 
  % Determine sampling attributes.
  if ismember('Time',Names)
    t = Table{:,'Time'};
    if size(t,2) ~= 1
      error('The ''Time'' variable must be 1-dimensional.')
    end
    start = t(1);
    dt = diff(t);
    if isa(start,'duration'), start=seconds(start); end
    if ~isnumeric(dt), dt=seconds(dt); end
    Table(:,'Time') = [];  nsignals=nsignals-1;
    unitsT = 'sec';
  else
    t = (1:npoints)';  % index vector
    start = t(1);
    dt = diff(t);
    unitsT = '';
  end

  % Remove any non-numeric variables
  mask = true(1,nsignals);  % initialize
  for k = 1:nsignals
    if ~isnumeric(Table{:,k}), mask(k)=false; end
  end
  Table(:,~mask) = [];

  % Collect final table attributes
  Names        = Table.Properties.VariableNames;
  Units        = Table.Properties.VariableUnits;
  Descriptions = Table.Properties.VariableDescriptions;
  if isempty(Units),        Units       =repmat({''},size(Names)); end
  if isempty(Descriptions), Descriptions=repmat({''},size(Names)); end

  % Make S-array from table data and attributes
  Cdata = struct2cell(table2struct(Table,'ToScalar',true));
  S = MakeSarray('Sampling',dt,'Data',Cdata,'Names',Names,'Units',Units', ...
                 'Descriptions',Descriptions,'timeunits',unitsT,'start',start);

  % Collapse S-array and remove 'sourcetype' field
  Data = CollapseSarray(S,'');
  Data = RenameField(Data,'All','Signals');
  Data = rmfield(Data,'sourcetype');

elseif strcmp(option,'timetable')

  % Check 'Table' input
  if isempty(Table)
    error('Input ''Table'' is empty.');
  end

  % Get initial variable names
  Names = Table.Properties.VariableNames;

  % Determine size parameters
  nsignals = length(Names);
  npoints = size(Table.(Names{1}),1);

  % Retrieve 'Time' and determine sampling attributes
  t = Table.Properties.RowTimes;
  start = t(1);
  dt = diff(t);
  if isa(start,'duration'), start=seconds(start); end
  if ~isnumeric(dt), dt=seconds(dt); end
  unitsT = 'sec';

  % Remove any non-numeric variables
  mask = true(1,nsignals);  % initialize
  for k = 1:nsignals
    if ~isnumeric(Table{:,k}), mask(k)=false; end
  end
  Table(:,~mask) = [];

  % Collect final table attributes
  Names        = Table.Properties.VariableNames;
  Units        = Table.Properties.VariableUnits;
  Descriptions = Table.Properties.VariableDescriptions;
  if isempty(Units),        Units       =repmat({''},size(Names)); end
  if isempty(Descriptions), Descriptions=repmat({''},size(Names)); end

  % Make S-array from table data and attributes
  Cdata = struct2cell(table2struct(Table,'ToScalar',true));
  S = MakeSarray('Sampling',dt,'Data',Cdata,'Names',Names,'Units',Units', ...
                 'Descriptions',Descriptions,'timeunits',unitsT,'start',start);

  % Collapse S-array and remove 'sourcetype' field
  Data = CollapseSarray(S,'');
  Data = RenameField(Data,'All','Signals');
  Data = rmfield(Data,'sourcetype');

elseif strcmp(option,'struct')

  % Convert 's1' to 'table', and check it
  try
    Table = struct2table(s1);
    Data = BuildDatasetFromData(Table,source);
  catch
    error('Input structure ''s1'' is not valid.  Must be convertible to table.');
  end

else  % if 'Values' provided

  % Check 't' and 'Values'
  if ~isvector(t)
    error('Time vector is invalid.')
  elseif ~isnumeric(Values) || ~ismatrix(Values)
    error('The ''Values'' array is invalid.')
  elseif size(Values,1) ~= length(t)
    error('The ''Values'' array and time vector are not compatible.')
  end

  % Make column
  t = t(:);

  % Determine time units
  if (laterVersion && isdatetime(t))   % if 't' is 'datetime' type
    time_units = 'datetime';
  elseif isnumeric(t) && all(t > 1e5)  % interpret 't' as date numbers
    time_units = 'datenum';
  elseif isnumeric(t) && strcmp(nameT,'Time')   % interpret 't' as elapsed seconds
    time_units = 'sec';
  elseif strcmp(nameT,'Index')         % interpret 't' as an index vector
    time_units = '';
  else
    error('Time vector is invalid')
  end

  % Number of signals
  nsignals = size(Values,2);

  % Use generic signal names
  Names = arrayfun(@(x)['x',int2str(x)],1:nsignals,'Uniform',false)';

  % Build signal group
  Signals.Names = Names;
  Signals.Values = Values;
  Signals.Units = repmat({''},nsignals,1);
  Signals.Descriptions = repmat({''},nsignals,1);

  % Build 'Time' group
  Time.Names = {nameT};
  Time.Values = t;
  Time.Units = {time_units};
  Time.Descriptions = {descT};

  % Build dataset
  Data.Time = Time;
  Data.Signals = Signals;
end

% Add source string if provided
if ischar(source)
  Data.source = source;
end

function S = ReadXlsFile(pathname)

% READXLSFILE - Read signal data from a spreadsheet file.
% S = ReadXlsFile(pathname)
%
% Reads signal data from a spreadsheet (.xls,.xlsx,.csv) file into 
% structure array 'S'. Signals are assumed to be formatted in columns 
% with signal name headers in the first row.  A 'Time' column with 
% real values or date-time stamps is optional. (Real values > 1e4 are 
% assumed to be Excel date numbers representing absolute time.) Input 
% 'pathname' is the pathname to the file to be read.  Output 'S' has 
% a 'name' field containing the signal names and additional fields 
% corresponding to the imported signal attributes.  The following 
% fields are derived: 
%   'name'         -  signal name string(*)
%   'data'         -  data vector(**)
%   'dt'           -  sample time
%   'unitsT'       -  time units string
%   'units'        -  signal units string
%   'description'  -  signal description string
%   'trigger'      -  start time value (== 0)
% Type "help formats" and see function "IsSarray" for additional 
% information on S-array format. 
% 
% (*) Repeated names and names containing spaces or special characters 
% are modified to preserve uniqueness and compatibility as variable 
% names. 
% 
% (**) Any text or empty cells occurring in the data columns are 
% replaced by NaN. 
%
% P.G. Bonanni
% 10/24/19

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


% Determine if Matlab version is from 2014 or later
if datenum(version('-date')) > datenum('1-Jun-2014')
  laterVersion = true;
else  % if version is older
  laterVersion = false;
end

% If single-entry cell array provided
if iscellstr(pathname) && numel(pathname)==1
  pathname = pathname{1};
end

% Check input
if ~ischar(pathname)
  error('Input ''pathname'' is not valid.')
end

% Check that input file exists
if ~exist(pathname,'file')
  error('File "%s" does not exist.',pathname)
end

% Remaining input check
if ~IsFileType(pathname,'xls') && ~IsFileType(pathname,'csv')
  error('Accepts spreadsheet format (.xls or .xlsx or .csv) files only.')
end

% ------------------------------------------
% Read spreadsheet file
% ------------------------------------------

% Read data from specified file and default worksheet
[~,TXT,RAW] = xlsread(pathname,'');

% Remove comment lines (starting with "#" character)
mask = ~cellfun(@isempty,regexp(TXT(:,1),'^\s*#','match'));
TXT(mask,:) = [];
RAW(mask,:) = [];

% Check for header row
if size(TXT,2) ~= size(RAW,2) || any(cellfun(@isempty,TXT(1,:)))
  error('Header row is missing or defective.')
end

% Number data columns
ncols = size(RAW,2);

% Get column headers
names = TXT(1,:)';

% Check for "Time" or "time" column; ensure no more than one
maskT = strcmpi('Time',names);  % permit any case
if sum(maskT) > 1
  error('Multiple "Time" columns detected.')
end

% Replace space characters (and '/', '\', ':', '-', '.') by '_'
names = regexprep(names,'\s+',        '_');
names = regexprep(names,'[\\\/:\-\.]','_');

% Remove bracket characters
names = regexprep(names,'[\(\)\[\]<>{}]','');

% Ensure no repeated names
for k = 2:ncols
  while any(strcmp(names{k},names(1:k-1)))
    names{k} = [names{k},'_1'];
  end
end

% Remove header row
RAW(1,:) = [];

% Data length
nrows = size(RAW,1);
if nrows < 2
  error('Must include at least two data rows.')
end

% Determine element types and locate empty cells
TYPE  = zeros(size(RAW));
EMPTY = zeros(size(RAW));
for j = 1:nrows
  for k = 1:ncols
    TYPE(j,k)  = ischar(RAW{j,k});     % always scalar
    EMPTY(j,k) = any(isnan(RAW{j,k})); % works for strings
  end
end

% Classify columns by type, excluding empty cells
COLTYPE = zeros(1,ncols);  % (1=text,0=numeric,-1=mixed
for k = 1:ncols
  if all(EMPTY(:,k))  % all empty, treat as numeric
    COLTYPE(k) =  0;
  elseif all(TYPE(~EMPTY(:,k),k)==1)  % all text
    COLTYPE(k) =  1;
  elseif all(TYPE(~EMPTY(:,k),k)==0)  % all numeric
    COLTYPE(k) =  0;
  else  % mixed type
    COLTYPE(k) = -1;
  end
end

% Identify columns containing empty cells
INCOMPLETE = any(EMPTY==1);

% Warn about empty cells and/or mixed types
if any(INCOMPLETE)
  fprintf('Warning: Empty cells assigned '''' or NaN in column(s):')
  fprintf('  %s',names{INCOMPLETE})
  fprintf('\n')
end
if any(COLTYPE == -1)
  fprintf('Warning: Data of mixed type found in column(s):')
  fprintf('  %s',names{COLTYPE == -1})
  fprintf('\n')
end

% Replace NaN by '' in text columns (empty cells)
for k = find(COLTYPE == 1)
  for j = 1:nrows
    if isnan(RAW{j,k})
      RAW{j,k}='';
    end
  end
end

% Split RAW array into columns
DATA = mat2cell(RAW,nrows,ones(ncols,1));

% If a "Time" column is present containing real values, time units 
% of 'sec' are assumed.  However, if all values in the column are 
% greater than 1e4, the values are assumed to be Excel date numbers 
% representing absolute time. In all cases with time provided, 
% sample times are computed in 'sec'.  If a time is not provided, 
% sampling is set to 1 and time units to ''. 

% If "Time" column present ...
if any(maskT)

  % Get Time data
  TIME     = DATA{maskT};
  TIMETYPE = COLTYPE(maskT);

  % Ensure Time is either all-real or all-string
  if TIMETYPE == -1
    error('Time data column is not valid.')
  end

  % Excel offset time (NOTE: Subtraction of 2 days 
  % from the 1/1/1900 reference date disagrees with 
  % published articles, but is required for accurate 
  % time conversion. 
  ExcelOffset = datenum('1-Jan-1900') - 2;

  % Convert time data and compute sampling in 'sec'
  if TIMETYPE == 0 && any(cell2mat(TIME) < 1e4)  % real-valued Time
    Time = cell2mat(TIME);
    dt = diff(Time);  % sec
  else
    if laterVersion
      if TIMETYPE == 0  % if numerical
        Time = days(cell2mat(TIME)) + datetime(ExcelOffset,'ConvertFrom','datenum');
      else  % if strings
        Time = datetime(datevec(TIME));
      end
      dt = diff(Time);  dt=seconds(dt);  % sec
    else  % if ~laterVersion, use date numbers
      if TIMETYPE == 0  % if numerical
        Time = cell2mat(TIME) + ExcelOffset;
      else  % if strings
        Time = datenum(TIME);
      end
      dt = diff(Time)*86400;  % sec
    end
  end

  % Replace DATA and COLTYPE entries
  DATA{maskT}    = Time;
  COLTYPE(maskT) = 0;

  % Warn if sampling is not monotonic
  if any(dt <= 0)
    fprintf('Warning: Sampling is not monotonic.\n')
  end

  % Reduce 'dt' to scalar, if possible
  if all(dt>0) && (max(dt) - min(dt))/min(dt) < 1e-6
    dt = dt(1);
  end

  % Set time units
  unitsT = 'sec';

  % Get start time
  start = Time(1);

else  % if "Time" column not present ...

  % Index sampling
  dt = 1;

  % Set time units
  unitsT = '';

  % Set start time
  start = 1;
end

% Replace text with NaN in columns of mixed type or text
if any(COLTYPE ~= 0)
  disp('         Replacing text with NaN values.');
end
for k = find(COLTYPE ~= 0)
  for j = find(TYPE(:,k)' == 1)
    DATA{k}{j} = NaN;
  end
end

% Create vectors
for k = 1:length(DATA)
  if iscell(DATA{k})
    DATA{k} = cell2mat(DATA{k});
  end
end

% Report on data read
fprintf('Number of rows:    %5d\n',nrows);
fprintf('Number of columns: %5d\n',ncols);

% Remove time column
if any(maskT)
  names(maskT) = [];
  DATA(maskT)  = [];
end

% Make S-array from signal data
S = MakeSarray('Sampling',  dt, ...
               'Data',      DATA, ...
               'Names',     names, ...
               'timeunits', unitsT, ...
               'start',     start);

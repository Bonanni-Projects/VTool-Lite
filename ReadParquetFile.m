function S = ReadParquetFile(pathname)

% READPARQUETFILE - Read signal data from a parquet file.
% S = ReadParquetFile(pathname)
%
% Reads signal data from a parquet (.parquet) file into structure 
% array 'S'. A 'Time' variable (i.e., column) with real values or 
% datetime values is optional. Columns with non-numeric data are 
% ignored. Input 'pathname' is the pathname to the file to be read. 
% Output 'S' has a 'name' field containing the signal names and 
% additional fields corresponding to the imported signal attributes. 
% The following fields are derived: 
%   'name'         -  signal name string(*)
%   'data'         -  data vector
%   'dt'           -  sample time
%   'unitsT'       -  time units string
%   'units'        -  signal units string
%   'description'  -  signal description string
%   'trigger'      -  start time value
% Type "help formats" and see function "IsSarray" for additional 
% information on S-array format. 
% 
% (*) Names containing spaces or special characters are modified 
% as necessary to ensure uniqueness and compatibility as variable 
% names. 
%
% P.G. Bonanni
% 3/17/26

% Copyright (c) 2026  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


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
if ~IsFileType(pathname,'parquet')
  error('Accepts .parquet files only.')
end

% Suppress warning about variable name modification
warningID = 'MATLAB:table:ModifiedVarnames';
s = warning('query',warningID);  % get current state
warning('off',warningID)

% Read input file as table
Table = parquetread(pathname);

% Restore warning state
warning(s.state,warningID)

% Get initial variable names
Names = Table.Properties.VariableNames;

% Determine size parameters
nsignals = length(Names);
npoints = size(Table.(Names{1}),1);

% Retrieve and remove the 'Time' column, or build 'Index' vector. 
% Determine sampling attributes.
if ismember('Time',Names)
  t = Table{:,'Time'};
  start = t(1);
  dt = diff(t);
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

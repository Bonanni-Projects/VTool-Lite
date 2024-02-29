function S = MakeSarray(varargin)

% MAKESARRAY - Make an S-array from signal data.
% S = MakeSarray('Sampling',Ts,'Data',Data)
% S = MakeSarray('Sampling',Sampling,'Data',Data)
% S = MakeSarray('Sampling',Sampling,'Data',Data,<property>,<value>,<property>,<value>, ...)
%
% Constructs an S-array from signal data.  The S-array supports signals 
% that may be regularly or irregularly sampled, and in addition may be  
% "non time-synchronized", implying that different sampling may apply to 
% different signal data.  Output 'S' is a structure array, with each S(i) 
% having fields: 
%   'name'         -  signal name string
%   'data'         -  data vector
%   'dt'           -  sample time (constant or vector)
%   'unitsT'       -  time units string
%   'units'        -  signal units string
%   'description'  -  signal description string
%   'trigger'      -  start time (scalar value or date vector, see below)
% Type "help formats" and see function "IsSarray" for additional 
% information on S-array format. 
%
% Signal information is provided via property/value pairs, as follows. 
% The 'Sampling' and 'Data' specifications are required.  The additional 
% property/value pairs are optional. 
%
%   Property           Value(*)
% ------------         -------------------------------------------------
%  'Sampling'     -    Cell array of sample times, one per signal, or a
%                      scalar value 'Ts' if sampling times are the same. 
%                      If a signal has non-uniform sampling, its sampling 
%                      is specified by a vector of length(data)-1. 
%  'Data'         -    Cell array of signal data, each cell containing 
%                      a single column vector, or a multidimensional array 
%                      whose columns represent time series (see below). 
%  'Names'         -   (OPTIONAL) Cell array of signal names, each cell 
%                      containing a single character string. Defaults to 
%                      {'x1','x2',...,'xM'} if [] is specified, or if 
%                      no 'Names' information provided. 
%  'Units'         -   (OPTIONAL) Cell array of signal units strings, each 
%                      cell containing a single character string. Defaults 
%                      to empty strings {'','',...} if [] is specified, or 
%                      if no 'Units' information provided. 
%  'Descriptions'  -   (OPTIONAL) Cell array of signal descriptions, each 
%                      cell containing a single character string. Defaults 
%                      to empty strings {'','',...} if [] is specified, or 
%                      if no 'Descriptions' information provided. 
%  'timeunits'     -   (OPTIONAL) time units string.  Defaults to 'sec' if 
%                      [] is specified or no information provided. 
%  'start'         -   (OPTIONAL) date string, or datetime value, or datenum 
%                      value, or 6-element date vector specifying an absolute 
%                      start time for the signals, or a scalar value specifiying 
%                      a start time offset.  Defaults to 0 if [] is specified 
%                      or no information provided. 
%
% (*) All cell arrays must be length-M, where M is the number of 
% represented signals. 
%
% If 'Data' contains a 2- or higher dimensional array, the array is 
% expanded into an equivalent set of 1-dimensional column vectors to 
% produce a new set of 1-dimensional signals.  The corresponding 'Names' 
% entry is interpreted as a root name, and appropriate subscripting with 
% trailing numerals is used to name the individual signals. The underscore 
% character '_' is employed where necessary to separate the subscripts.  
% All other attributes are replicated across the expanded set of signals. 
%
% See also "MakeSarrayFile". 
%
% P.G. Bonanni
% 7/13/19

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


% Determine if Matlab version is from 2014 or later
if datenum(version('-date')) > datenum('1-Jun-2014')
  laterVersion = true;
else  % if version is older
  laterVersion = false;
end

% Initialize
args = varargin;

% Check property/value pairs
OptionsList = {'Sampling','Data','Names','Units','Descriptions','timeunits','start'};
if rem(length(args),2) ~= 0
  error('Incomplete property/value pair(s).')
elseif any(cellfun('isclass',args(1:2:end),'char') == 0)
  error('One or more invalid options specified.')
elseif any(~ismember(args(1:2:end),OptionsList))
  error('One or more invalid options specified.')
end
Options = args(1:2:end);
if length(unique(Options)) ~= length(Options)
  fprintf('WARNING: One or more options is repeated.\n')
end

% Initialize all options to defaults
[Sampling,Data,Names,Units,Descriptions,timeunits,start] = deal([]);

% Make property/value assignments
for k = 1:2:length(args)
  eval(sprintf('%s = args{%d};',args{k},k+1));
end

% Check 'Data' information
if isempty(Data)
  error('No ''Data'' provided.')
elseif ~iscell(Data) || ~isvector(Data)
  error('Input ''Data'' has the wrong format.  Must be a 1-d cell array.')
elseif ~all(cellfun(@(x)isnumeric(x),Data))
  error('Input ''Data'' is invalid.  Contents must be numeric.')
end

% Number of signals
M = length(Data);

% Extend 'Sampling' to a cell array if necessary
if isnumeric(Sampling)
  Sampling = repmat({Sampling},size(Data));
end

% Check 'Sampling' information
if isempty(Sampling)
  error('No ''Sampling'' information provided.')
elseif ~iscell(Sampling) || ~isvector(Sampling)
  error('The provided ''Sampling'' information is not valid.  Must be numerical, or a 1-d cell array.')
elseif ~all(cellfun(@(x)isnumeric(x)&&isvector(x),Sampling))
  error('Input ''Sampling'' is invalid.  Contents must be scalar values or vectors.')
end

% Repair any mismatched 'dt' vectors
for k = 1:length(Sampling)
  dt = Sampling{k};
  n = length(Data{k});
  if length(dt) > n-1
    fprintf('Sampling vector ''dt'' for data entry #%d is too long. Truncating.\n',k);
    dt = dt(1:n-1);
  elseif ~isscalar(dt) && length(dt) < n-1
    fprintf('Sampling vector ''dt'' for data entry #%d is too short. Extrapolating last value.\n',k);
    p = length(dt);  dt(p+1:n-1)=dt(p);
  end
  Sampling{k} = dt;
end

% Build default components as necessary
if isnumeric(Names) && isempty(Names)
  Names = strcat({'x'},strread(num2str(1:M),'%s'));
end
if isnumeric(Units) && isempty(Units)
  Units = repmat({''},M,1);
end
if isnumeric(Descriptions) && isempty(Descriptions)
  Descriptions = repmat({''},M,1);
end
if isnumeric(timeunits) && isempty(timeunits)
  timeunits = 'sec';
end

% Check additional cell-array options
if ~iscell(Names) || ~isvector(Names)
  error('Input ''Names'' has the wrong format.  Must be a 1-d cell array.')
elseif ~all(cellfun(@(x)ischar(x)&&(isempty(x)||isrow(x)),Names))
  error('Input ''Names'' is invalid.  Contents must be character strings.')
elseif ~iscell(Units) || ~isvector(Units)
  error('Input ''Units'' has the wrong format.  Must be a 1-d cell array.')
elseif ~all(cellfun(@(x)ischar(x)&&(isempty(x)||isrow(x)),Units))
  error('Input ''Units'' is invalid.  Contents must be character strings.')
elseif ~iscell(Descriptions) || ~isvector(Descriptions)
  error('Input ''Descriptions'' has the wrong format.  Must be a 1-d cell array.')
elseif ~all(cellfun(@(x)ischar(x)&&(isempty(x)||isrow(x)),Descriptions))
  error('Input ''Descriptions'' is invalid.  Contents must be character strings.')
end

% Check compatibility of sizes
if numel(Sampling) ~= M
  error('Specified ''Sampling'' array must match ''Data'' in length.')
elseif numel(Names) ~= M
  error('Specified ''Names'' array must match ''Data'' in length.')
elseif numel(Units) ~= M
  error('Specified ''Units'' array must match ''Data'' in length.')
elseif numel(Descriptions) ~= M
  error('Specified ''Descriptions'' array must match ''Data'' in length.')
end

% Check 'timeunits' option
if ~ischar(timeunits)
  error('Input ''timeunits'' is invalid.  Must be a string.')
end

% Check 'start' option
if ~(isnumeric(start) && (isempty(start) || isscalar(start) || (isrow(start) && length(start)==6) )) && ...
   ~(laterVersion && isdatetime(start) && isscalar(start)) && ...
   ~(ischar(start) && isrow(start))
  error('Input ''start'' is invalid.  Specify a date vector or date string or datetime or datenum or a scalar value.')
end

% Derive 'trigger' from 'start' value
if isnumeric(start) && isempty(start)                        % if []
  trigger = [];
elseif isnumeric(start) && isscalar(start) && start < 1e5    % if real scalar
  trigger = start;
elseif isnumeric(start) && isrow(start) && length(start)==6  % if date vector
  trigger = start;
elseif (laterVersion && isdatetime(start)) || ...  % if 'datetime' type
       (isnumeric(start) && start > 1e5) || ...    %  ... or 'datenum' type
       ischar(start)                               %  ... or date string
  trigger = datevec(start);
end

% Make column arrays
Sampling     = Sampling(:);
Data         = Data(:);
Names        = Names(:);
Units        = Units(:);
Descriptions = Descriptions(:);

% Fill in any empty 'Names' entries
mask = cellfun(@isempty,Names);  n=sum(mask);
names = strcat({'x'},strread(num2str(1:n),'%s'));
[Names{mask}] = deal(names{:});

% Loop over 'Data' array, expanding 
% any multi-dimensional signal data
for k = 1:length(Data)

  % Get contents
  X = Data{k};

  % Split into columns
  C = num2cell(X,1);
  Data{k} = C(:);

  % Number of component signals
  n = length(Data{k});

  % Expand the remaining attributes
  Sampling{k}     = repmat(Sampling(k),n,1);
  Names{k}        = repmat(Names(k),n,1);
  Units{k}        = repmat(Units(k),n,1);
  Descriptions{k} = repmat(Descriptions(k),n,1);

  % Skip remainder if contents is 1-d
  if iscolumn(X), continue, end

  % Add subscripting to 'Names'
  d=size(X);  d(1)=[];  D=num2cell(d);          % dimensions
  V = cellfun(@(x)1:x,D,'Uniform',false);       % grid vectors
  Coords = cell(size(D));  % initialize
  [Coords{:}] = ndgrid(V{:});                   % coordinates
  Coords = cellfun(@(x)x(:),Coords,'Uniform',false);  % make columns
  Coords = fliplr(Coords);                      % reverse order of dimensions
  Coords = cat(2,Coords{:})';                   % prepare for sprintf()
  format = repmat('_%d',1,length(d));           % format string
  Str = sprintf([format,' '],Coords);
  Endings = strread(Str,'%s','delimiter',' ');  % subscript strings
  % ---
  % Remove the first underscore if root name does 
  % not end in a numeral and X is only 2-dimensional
  if isempty(regexp(Names{k}{1},'[0-9]$','once')) && isscalar(d)
    Endings = cellfun(@(x)x(2:end),Endings,'Uniform',false);
  end
  % Append subscript strings
  Names{k} = strcat(Names{k},Endings);
end

% Re-flatten the cell arrays
Sampling     = cat(1,Sampling{:});
Data         = cat(1,Data{:});
Names        = cat(1,Names{:});
Units        = cat(1,Units{:});
Descriptions = cat(1,Descriptions{:});

% Build 'S' array
S = struct( ...
  'name',        Names, ...
  'data',        Data, ...
  'dt',          Sampling, ...
  'unitsT',      timeunits, ...
  'units',       Units, ...
  'description', Descriptions, ...
  'trigger',     trigger);

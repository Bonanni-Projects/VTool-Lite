function [out1,out2] = ComputeStatsArray(pathname,ArrayName0,varargin)

% COMPUTESTATSARRAY - Compute comparison statistics from signal group arrays.
% ComputeStatsArray(pathname,ArrayName0 [,outfolder])
% ComputeStatsArray(pathname,ArrayName0,outfolder,<Option1>,<Value>,<Option2>,{Value>,...)
% [Stats,Info] = ComputeStatsArray(...)
%
% Computes a "Stats array" from a saved set of signal group arrays. 
% Fields of the Stats array represent "self" and "comparison" statistics 
% for the signal group arrays found in a "collected_signals_*.mat" file 
% (as produced, for example, by functions "CollectSignalsFromFiles" or 
% "CollectSignalsFromResults"). Parameter 'pathname' specifies the 
% pathname to the input file, and 'ArrayName0' specifies which array 
% within the file to regard as the reference to which all remaining 
% arrays (if present) should be compared.  The arrays in the file are 
% assumed to be of equal length, with all name layers and signal lengths 
% equal. 
%
% Results are assembled in structure array 'Stats', with Stats(i).name 
% identifying a signal group array being compared to the reference array, 
% and the remaining fields representing the computed statistics. If 
% output arguments are not provided, the 'Stats' structure array is 
% saved in a mat-file either to the current working directory or to an 
% optionally specified 'outfolder', with filename derived by replacing 
% the string 'collected_signals' by 'computed_stats'. 
%
% The function behavior can be modified by supplying option/value 
% pairs after the 'outfolder' argument, or after a [] provided in 
% its place.  The following options are available: 
%   'ArrayNames'   -  specifies a subset of signal group arrays 
%                     and their order of comparison to 'ArrayName0'. 
%                     If not specified, all valid arrays in the file 
%                     are compared. 
%   'Selections'   -  cell array of signal names to include in the 
%                     statistics calculations.  The default is all 
%                     signals in the arrays. 
%   'nameF'        -  signal name to use for filtering cases from 
%                     the arrays.  If not provided, no filtering 
%                     is performed. 
%   'rangesF'      -  nx2 matrix of "valid ranges" for the 'nameF' 
%                     signal, each row defining a [min,max] interval. 
%                     A case is considered valid if the 'nameF' signal 
%                     remains within valid intervals for the full 
%                     duration of the case.  If invalid, the case is 
%                     removed from all arrays and excluded from the 
%                     statistics calculations. Default is [-inf,inf]. 
%   'valuesF'      -  vector of "valid values" for the 'nameF' signal. 
%                     Similar to 'rangesF', but applicable if the 
%                     'nameF' signal is discrete. A case is considered 
%                     valid if the 'nameF' signal takes on only values 
%                     specified in this vector for the full duration. 
%   'nameC'        -  classification signal name to use for "binned 
%                     statistics". If not provided, no classification 
%                     is performed. 
%   'edges1'       -  specifies the classification bin boundaries 
%                     used for time-domain statistics computations, 
%                     The default is 10 bins of equal width between 
%                     the minimum and maximum value of the 'nameC 
%                     signal. 
%   'spectral'     -  'on' or 'off', specifying whether to compute 
%                     frequency-domain statistics.  Default is 'off'. 
%                     Requires uniform time sampling, with sample 
%                     time determined by one or more Time signal 
%                     groups found in the file. 
%   'edges2'       -  specifies the classification bin boundaries 
%                     used for frequency-domain statistics, 
%                     The default is the same as for 'edges1'. 
%   'includeData'  -  'on' or 'off', specifying whether to include 
%                     raw and derived signal group array data on 
%                     the 'Stats' structure (as Stats(i).SIGNALS, 
%                     Stats(i).PSD, etc.) and in the saved file. 
%                     Default is 'off'. 
%
% As a supplement to 'Stats', a scalar 'Info' structure is also 
% stored in the output file, or returned.  This structure captures 
% additional information resulting from the statistical processing, 
% including the assumed values of the above options, and information 
% useful for interpreting and plotting results. 
%
% P.G. Bonanni
% 4/6/20

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


% If output argument is supplied, 'outfolder' should be []
if nargout && ~isempty(varargin) && rem(length(varargin),2)==1 && ~(isnumeric(varargin{1}) && isempty(varargin{1}))
  error('Invalid usage.  No ''outfolder'' permitted if output argument is supplied.')
end

% Destination folder (or []) must be specified if providing option/value pairs
if ~isempty(varargin) && ~(rem(length(varargin),2)==1)
  error('Invalid usage.  Specify ''outfolder'' or [] if providing option/value pairs.')
end

% Set 'outfolder' and adjust 'varargin'
outfolder = '.';  % initialize
if ~isempty(varargin)
  if ~(isnumeric(varargin{1}) && isempty(varargin{1}))
    outfolder = varargin{1};
  end
  varargin(1) = [];
end

% Check 'pathname' argument and get rootname
if ~ischar(pathname)
  error('Invalid ''pathname'' input.')
end
[~,rootname,ext] = fileparts(pathname);  % rootname and extension
if ~strncmp(rootname,'collected_signals',length('collected_signals')) || ~strcmp(ext,'.mat')
  error('Input file name ''%s'' is not valid.',[rootname,ext])
elseif ~exist(pathname,'file')
  error('Input file ''%s'' not found.',pathname)
end

% Check 'ArrayName0' argument
if ~ischar(ArrayName0)
  error('Parameter ''ArrayName0'' is not valid.')
end

% Check 'outfolder'
if ~ischar(outfolder)
  error('Parameter ''outfolder'' is not valid.')
elseif ~isdir(outfolder)
  error('Destination folder ''%'' does not exist.',outfolder)
end  

% Initialize
ArrayNames  = [];
Selections  = [];
nameF       = [];
rangesF     = [];
valuesF     = [];
nameC       = [];
edges1      = [];
spectral    = [];
edges2      = [];
includeData = [];

if ~isempty(varargin)
  % Check option/value pairs
  OptionsList = {'ArrayNames','Selections','nameF','rangesF','valuesF', ...
                 'nameC','edges1','spectral','edges2','includeData'};
  if rem(length(varargin),2) ~= 0
    error('Incomplete option/value pair(s).')
  elseif any(~cellfun('isclass',varargin(1:2:end),'char'))
    error('One or more invalid options specified.')
  elseif any(~ismember(varargin(1:2:end),OptionsList))
    error('One or more invalid options specified.')
  end
  % Get options list
  Options = varargin(1:2:end);
  if length(unique(Options)) ~= length(Options)
    fprintf('WARNING: One or more options is repeated.\n')
  end
  % Make option/value assignments
  for k = 1:2:length(varargin)
    eval(sprintf('%s = varargin{%d};',varargin{k},k+1));
  end
end

% Check option values, but allow [] throughout
if ~(isnumeric(ArrayNames) && isempty(ArrayNames)) && ...
   (~iscellstr(ArrayNames) || any(cellfun(@isempty,ArrayNames)))
  error('Specified ''ArrayNames'' is not valid.')
elseif ~(isnumeric(Selections) && isempty(Selections)) && ...
       (~iscellstr(Selections) || any(cellfun(@isempty,Selections)))
  error('Specified ''Selections'' is not valid.')
elseif ~(isnumeric(nameF) && isempty(nameF)) && ...
       (~ischar(nameF) || isempty(nameF))
  error('Specified ''nameF'' is not valid.')
elseif ~(isnumeric(rangesF) && isempty(rangesF)) && ...
       (~isnumeric(rangesF) || ~ismatrix(rangesF) || size(rangesF,2)~=2 || any(diff(rangesF,[],2) < 0))
  error('Specified ''rangesF'' is not valid.')
elseif ~(isnumeric(valuesF) && isempty(valuesF)) && ...
       (~isnumeric(valuesF) || ~isvector(valuesF))
  error('Specified ''valuesF'' is not valid.')
elseif ~(isnumeric(nameC) && isempty(nameC)) && ...
       (~ischar(nameC) || isempty(nameC))
  error('Specified ''nameC'' is not valid.')
elseif ~(isnumeric(edges1) && isempty(edges1)) && ...
       (~isnumeric(edges1) || ~isvector(edges1) || length(edges1) < 2 || ~all(diff(edges1) > 0))
  error('Specified ''edges1'' is not valid.')
elseif ~(isnumeric(spectral) && isempty(spectral)) && ...
       (~ischar(spectral) || ~ismember(spectral,{'on','off'}))
  error('Specified ''spectral'' option is not valid.')
elseif ~(isnumeric(edges2) && isempty(edges2)) && ...
       (~isnumeric(edges2) || ~isvector(edges2) || length(edges2) < 2 || ~all(diff(edges2) > 0))
  error('Specified ''edges2'' is not valid.')
elseif ~(isnumeric(includeData) && isempty(includeData)) && ...
       (~ischar(includeData) || ~ismember(includeData,{'on','off'}))
  error('Specified ''includeData'' option is not valid.')
end

% Set defaults as necessary
if isempty(spectral)
  spectral = 'off';
end
if isempty(includeData)
  includeData = 'off';
end

% Check compatibility of options
if isempty(nameF) && ~isempty(rangesF)
  error('Specification of ''rangesF'' is not valid if a filtering signal is not specified.');
elseif isempty(nameF) && ~isempty(valuesF)
  error('Specification of ''valuesF'' is not valid if a filtering signal is not specified.');
elseif ~isempty(nameF) && ~isempty(rangesF) && ~isempty(valuesF)
  error('Not valid to specify both ''rangesF'' and ''valuesF'' for filtering.');
elseif isempty(nameC) && ~isempty(edges1)
  error('Specification of ''edges1'' is not valid if a classification signal is not specified.');
elseif strcmp(spectral,'off') && ~isempty(edges2)
  error('Specification of ''edges2'' is not valid if the ''spectral'' option is ''off''.');
elseif isempty(nameC) && ~isempty(edges2)
  error('Specification of ''edges2'' is not valid if a classification signal is not specified.');
end

% Set 'rangesF' default if 'nameF' specified and no criteria specified
if ~isempty(nameF) && isempty(rangesF) && isempty(valuesF)
  rangesF = [-inf,inf];
end

% Derive output pathname
rootname1 = strrep(rootname,'collected_signals','computed_stats');
outfile = fullfile(outfolder,[rootname1,'.mat']);

tic

% Load input data
fprintf('Loading collected signals ... ');
s = load(pathname);
fprintf('done.\n');
fprintf('\n');

% Check for filename list
if ~isfield(s,'fnames')
  error('The ''fnames'' list is not present in the input file.')
end

% Set filename lists
fnames  = s.fnames;  % complete list
fnamesF = {};        % initialize "filtered" list

% Initialize
TsValues = [];

% Loop over variables.  Keep only signal group arrays. Determine 
% the sample time 'Ts' from any 'Time' group/arrays, and check if 
% sampling is uniform with time monotonically increasing. If it 
% is not, set 'Ts' back to []. 
%
% Loop over variables
varnames = fieldnames(s);
for k = 1:length(varnames)
  varname = varnames{k};
  x = s.(varname);

  % Keep only the non-Time signal group arrays on the structure
  if ~IsSignalGroupArray(x) || strncmpi(varname,'Time',4)
    s = rmfield(s,varname);
  end

  % If a 'Time' signal group, get the min and max sample time. 
  % Consider only the first element, if a group array. 
  if IsSignalGroupArray(x) && strncmpi(varname,'Time',4)
    t = x(1).Values;
    if isa(t,'datetime')                 % if 'datetime' type
      dt = diff(t);  dt=seconds(dt);
    elseif isnumeric(t) && min(t) > 1e5  % assume 'datenum' type
      dt = diff(t)*86400;  % sec
      dt = double(dt);
    elseif isnumeric(t)                  % real type
      dt = diff(t);
      dt = double(dt);
    else
      error('Time vector has invalid type.')
    end
    TsValues = [TsValues; min(dt); max(dt)];
  end
end
% If 'Ts' info was extracted
if ~isempty(TsValues)

  % Sample time range
  TSrange = [min(TsValues),max(TsValues)];

  % Check results
  if any(TsValues <= 0)
    Ts = [];
    TsFlag = -2;  % sampling is not monotonic
  elseif diff(TSrange)/min(TsValues) > 0.002
    Ts = [];
    TsFlag = -1;  % sample time is not constant
  else
    Ts = TsValues(1);
    TsFlag = 1;   % sampling is uniform and valid
  end
else
  Ts = [];
  TsFlag = 0;     % sampling info not available
end

% If the 'spectral' option is 'on', check sampling
if strcmp(spectral,'on') && isempty(Ts)
  switch TsFlag
    case  0, error('Sampling time information not available.  Turn ''spectral'' option ''off''.')
    case -1, error('Sample time is not constant.  Turn ''spectral'' option ''off''.')
    case -2, error('Sampling is not monotonic.  Turn ''spectral'' option ''off''.')
  end
end

% Check that specified arrays are present
if ~isfield(s,ArrayName0)
  error('Specified ''ArrayName0'' is not present in the input file.')
elseif ~isempty(ArrayNames) && any(~ismember(ArrayNames,fieldnames(s)))
  error('One or more specified ''ArrayNames'' is not present in the input file.')
end

% Set 'ArrayNames' if necessary
if isempty(ArrayNames)
  ArrayNames = setdiff(fieldnames(s),ArrayName0);
end

% Always exclude 'ArrayName0' from the 'ArrayNames' list
% ... as it is the default first element of 'Stats'. 
ArrayNames = setdiff(ArrayNames,ArrayName0,'stable');

% Reduce 's' to the specified arrays only
s = rmfield(s,setdiff(fieldnames(s),[ArrayName0; ArrayNames(:)]));

% Check that the selected signal group arrays are valid and compatible
% --- Check homogeneity of names within the individual arrays
[~,valid] = structfun(@(x)IsSignalGroupArray(x),s);
if ~all(valid)
  error('One or more signal group arrays is invalid.  See "IsSignalGroupArray".')
end
% --- Check for matching names and name layers across the arrays
C = struct2cell(structfun(@(x)GetNamesMatrix(x(1)),s,'Uniform',false));
if ~isscalar(C) && ~isequal(C{:})
  error('Signal group arrays in the input file are not compatible.  Names do not match.')
end
% --- Check for matching signal units across the arrays
C = struct2cell(structfun(@(x)x(1).Units,s,'Uniform',false));
if ~isscalar(C) && ~isequal(C{:})
  error('Signal group arrays in the input file are not compatible.  Units do not match.')
end
% --- Check that arrays have the same length (number of cases)
C = struct2cell(structfun(@numel,s,'Uniform',false));
if ~isscalar(C) && ~isequal(C{:})
  error('Signal group arrays in the input file are not compatible.  Array lengths do not match.')
end
% --- Check uniformity of signal lengths throughout
fun = @(z)arrayfun(@(x)size(x.Values,1),z);
C = struct2cell(structfun(fun,s,'Uniform',false));
C = num2cell(cat(1,C{:}));
if ~isscalar(C) && ~isequal(C{:})
  error('Signal group arrays are not valid for analysis.  Signal lengths vary.')
end
% --- Check length agreement with 'fnames'
if numel(s.(ArrayName0)) ~= numel(fnames)
  error('Length of included ''fnames'' list does not match the arrays.')
end

% Set 'Selections' if necessary
if isempty(Selections)
  Selections = GetDefaultNames(s.(ArrayName0));
end

% Check that signal selections are present
if any(cellfun(@(x)isempty(FindName(x, s.(ArrayName0)(1))),Selections))
  error('One or more specified ''Selections'' is not present in the arrays.')
end

% Apply case filtering
if ~isempty(nameF)
  if isempty(FindName(nameF,s.(ArrayName0)(1)))
    error('Cannot filter cases. Signal ''%s'' not found.',nameF);
  end

  % Either 'rangesF' or 'valuesF' will be empty, but not both
  if ~isempty(rangesF), spec=rangesF; else spec=valuesF; end
  mask = ComputeFilterMask(s.(ArrayName0),nameF,spec);

  % Apply the mask to each array, and to 'fnames'
  s = structfun(@(x)x(mask),s,'Uniform',false);
  fnamesF = fnames(~mask);  % names removed by filter
  fnames  = fnames( mask);  % names retained

  % Report filtering results
  fprintf('Filtering performed based on signal ''%s''.\n',nameF);
  fprintf('Rejected %d cases out of %d.\n',sum(~mask),length(mask));
  fprintf('\n');
end

% Locate the classification signal
iC = [];  % initialize
if ~isempty(nameC)
  iC = FindName(nameC,s.(ArrayName0)(1));
  if isempty(iC)
    error('Cannot classify cases. Signal ''%s'' not found.',nameC);
  elseif numel(iC) > 1
    fprintf('Classification signal ''%s'' appears more than once. Using first instance.\n',nameC);
    iC = iC(1);
    fprintf('\n');
  end
end

% Set 'edges1' and 'edges2' if necessary
if ~isempty(nameC) && (isempty(edges1) || isempty(edges2))
  minval = min(ComputeStat(s.(ArrayName0),nameC,'min'));
  maxval = max(ComputeStat(s.(ArrayName0),nameC,'max'));
  if isempty(edges1), edges1=linspace(minval,maxval,11); end
  if isempty(edges2), edges2=linspace(minval,maxval,11); end
  if strcmp(spectral,'off'), edges2=[]; end
  if ~all(diff(edges1) > 0)
    error('The inferred ''edges1'' is not valid.')
  elseif strcmp(spectral,'on') && ~all(diff(edges2) > 0)
    error('The inferred ''edges2'' is not valid.')
  end
end

% Retain 'ArrayName0' array for classification purposes, then 
% reduce the arrays to contain only the selected signals
SIGNALS0 = s.(ArrayName0);
fun1 = @(x)SelectFromGroup(Selections,x);
fun2 = @(x)arrayfun(fun1,x);
s = structfun(fun2,s,'Uniform',false);

% Initialize 'Stats' structure array
Stats = struct('name',[ArrayName0; ArrayNames(:)]);

% Initialize 'Info' structure
Info.fnames     = fnames;
Info.ArrayName0 = ArrayName0;
Info.Selections = Selections;
Info.nameF      = nameF;
Info.rangesF    = rangesF;
Info.valuesF    = valuesF;
Info.fnamesF    = fnamesF;
Info.nameC      = nameC;
Info.spectral   = spectral;
Info.edges1     = edges1;
Info.edges2     = edges2;
Info.Ts         = Ts;

% Transfer arrays from 's' to 'Stats'
s = orderfields(s,{Stats.name});
C=struct2cell(s); [Stats.SIGNALS]=deal(C{:});
clear s C  % to save space

% Convert signal data to 'double' as necessary
DataTypes = arrayfun(@(x)class(x.SIGNALS(1).Values),Stats,'Uniform',false);
mask = strcmp(DataTypes,'double');
if any(~mask)
  for k = find(~mask)'
    dtype = class(Stats(k).SIGNALS(1).Values);
    fprintf('Converting ''%s'' from ''%s'' to ''double''.\n',Stats(k).name,dtype);
    for j = 1:length(Stats(k).SIGNALS)
      Stats(k).SIGNALS(j).Values = double(Stats(k).SIGNALS(j).Values);
    end
  end
  fprintf('\n');
end

% Compute "Difference" arrays
for k = 1:length(Stats)
  Stats(k).DIFFS = Stats(1).SIGNALS;
  for j = 1:length(Stats(k).DIFFS)
    Stats(k).DIFFS(j).Values = Stats(k).SIGNALS(j).Values - Stats(1).SIGNALS(j).Values;
  end
end

% -----------------------------
% TIME-DOMAIN STATISTICS

% Perform binning strategy #1 (for time-series analysis)
[iclass1,edges1,BinResults1] = perform_binning(SIGNALS0,nameC,edges1);

% Compute abcissa vector for plotting, and a corresponding label
if isempty(iC) || all(iclass1 == 0)
  xvec      = [];
  xlabelstr = '';
else
  [~,~,Mean] = ComputeLtStatsByBin(SIGNALS0,iclass1);
  xvec = double(Mean.mean(:,iC));  % (and convert to double)
  units       = SIGNALS0(1).Units{iC};
  description = SIGNALS0(1).Descriptions{iC};
  xlabelstr = description;  % initialize
  if ~isempty(units)
    xlabelstr = sprintf('%s (%s)',description,units);
  end
end

% Compute binned LT min-max-mean statistics (fields are P x M, where P is number of bins)
fprintf('Computing binned LT statistics ... ');
for k = 1:length(Stats)
  [Stats(k).LtMin, Stats(k).LtMax, Stats(k).LtMean] = ComputeLtStatsByBin(Stats(k).SIGNALS,iclass1);
end
fprintf('done.\n');

% Compute binned ST and binned ST error statistics (fields are P x M, where P is number of bins)
fprintf('Computing binned ST statistics ... ');
for k = 1:length(Stats)
  Stats(k).StStats = ComputeStStatsByBin(Stats(k).SIGNALS,iclass1);
  Stats(k).StErr   = ComputeStStatsByBin(Stats(k).DIFFS,  iclass1);
end
fprintf('done.\n');

% Number of cases
N = numel(Stats(1).SIGNALS);

% Compute unbinned, "case-wise" statistics (fields are N x M, where N is number of cases)
fprintf('Computing case-wise statistics ... ');
for k = 1:length(Stats)
  Stats(k).CaseStats = ComputeStStatsByBin(Stats(k).SIGNALS,1:N);
  Stats(k).CaseErr   = ComputeStStatsByBin(Stats(k).DIFFS,  1:N);
end
fprintf('done.\n');

% Compute global ST statistics (fields are 1 x M, where M is number of signals)
fprintf('Computing global ST statistics ... ');
for k = 1:length(Stats)
  Stats(k).GlobalStats = ComputeStStatsByBin(Stats(k).SIGNALS,ones(N,1));
  Stats(k).GlobalErr   = ComputeStStatsByBin(Stats(k).DIFFS,  ones(N,1));
end
fprintf('done.\n');
fprintf('\n');

% Update 'Info' fields
Info.edges1      = edges1;
Info.iclass1     = iclass1;
Info.BinResults1 = BinResults1;
Info.xvec        = xvec;
Info.xlabelstr   = xlabelstr;


% -----------------------------
% FREQUENCY-DOMAIN STATISTICS

% If frequency-domain statistics are specified ...
if strcmp(spectral,'on')

  % Perform binning strategy #2 (for PSD analysis)
  [iclass2,edges2,BinResults2] = perform_binning(SIGNALS0,nameC,edges2);

  % Initialize (for position on structure)
  [Stats.f] = deal([]);

  % Compute frequency-domain statistics
  fprintf('Computing PSD spectra ...\n');
  for k = 1:length(Stats)
    [Stats(k).PsdStats, Stats(k).f, Stats(k).PSD] = ComputePsdByBin(Stats(k).SIGNALS,iclass2,Ts,'dB');
  end
  fprintf('Computing Error-PSD spectra ...\n');
  for k = 1:length(Stats)
    [Stats(k).ErrPsdStats, ~, Stats(k).ErrPSD] = ComputeErrPsdByBin(Stats(1).SIGNALS,Stats(k).SIGNALS,iclass2,Ts,'dB');
  end
  fprintf('Computing PSD-error spectra ...\n');
  for k = 1:length(Stats)
    [Stats(k).RelPsdStats, ~, Stats(k).RelPSD] = ComputeRelPsdByBin(Stats(k).DIFFS,Stats(1).SIGNALS,iclass2,Ts,'dB');
  end
  fprintf('Frequency analysis complete.\n');
  fprintf('\n');

  % Record additional 'Info' fields
  Info.edges2      = edges2;
  Info.iclass2     = iclass2;
  Info.BinResults2 = BinResults2;
  Info.PsdUnits    = Stats(1).PSD(1).Units;
end

% Include a null signal group for name reference purposes
Info.Ref=Stats(1).SIGNALS(1);  Info.Ref.Values=nan(size(Info.Ref.Values));

% If 'includeData' option is 'off'
if strcmp(includeData,'off')
  Stats = rmfield(Stats,{'SIGNALS','DIFFS'});
  if strcmp('spectral','on')
    Stats = rmfield(Stats,{'PSD','ErrPSD','RelPSD'});
  end
end

% Return or store results
if nargout
  out1 = Stats;
  out2 = Info;
else
  fprintf('Storing results to "%s" ... ',outfile);
  save(outfile,'Stats','Info')
  fprintf('done.\n');
  fprintf('\n');
end

toc



% =========================================================================
function [iclass,edges,BinResults] = perform_binning(SIGNALS,nameC,edges)

% Perform binning of the 'nameC' signal within signal group array 'SIGNALS', 
% yielding integer-valued classification vector 'iclass' and 'BinResults' 
% structure array. Report results of the classification. Adjust the 'edges' 
% vector and the remaining outputs if lower or higher value bins are not 
% populated. 

% If classification signal specified ...
if ~isempty(nameC)
  % Compute classification vector and report binning results
  [iclass,BinResults] = ComputeClassVector(SIGNALS,nameC,'mean',edges,'report');

  % Adjust 'edges' and 'BinResults' to remove end bins if empty
  if ~all(iclass == 0)
    nbins0  = length(edges) - 1;      % initial number of bins
    minval0 = min(iclass(iclass>0));  % initial lowest class index
    maxval0 = max(iclass);            % initial highest class index
    nlo = minval0 - 1;       % number of bins to remove at lower end
    nhi = nbins0 - maxval0;  % number of bins to remove at upper end
    edges(1:nlo)      = [];                                          % remove 'nlo' bins
    BinResults(1:nlo) = [];                                          % remove 'nlo' bins
    edges(length(edges)+1-nhi : length(edges))                = [];  % remove 'nhi' bins
    BinResults(length(BinResults)+1-nhi : length(BinResults)) = [];  % remove 'nhi' bins
    % ---
    iclass(iclass>0) = iclass(iclass>0) - minval0 + 1;  % shift index values
    if nlo > 0, fprintf('Adjusted ''edges'' based on binning results: Lowest %d bin(s) removed.\n', nlo); end
    if nhi > 0, fprintf('Adjusted ''edges'' based on binning results: Highest %d bin(s) removed.\n',nhi); end
    if nlo > 0 || nhi > 0
      fprintf('\n');
    end
  else  % if all(iclass == 0)
    edges      = [];
    BinResults = [];
    fprintf('Adjusted ''edges'' to [], removing all bins.\n');
    fprintf('\n');
  end
else  % if no classification signal specified
  iclass = ones(size(SIGNALS));
  edges = [];
  BinResults = struct('index',  1, ...
                      'center', [], ...
                      'cases',  numel(SIGNALS), ...
                      'title',  'all cases');
end

% If all cases rejected
if all(iclass == 0)
  fprintf('WARNING: All %d cases fall outside binning range.  Statistical pool size is zero.\n',numel(SIGNALS))
  fprintf('\n');
end

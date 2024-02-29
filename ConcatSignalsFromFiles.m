function ConcatSignalsFromFiles(varargin)

% CONCATSIGNALSFROMFILES - Concatenate signals from data files in a folder.
% ConcatSignalsFromFiles(dname,filetype [,outfolder])
% ConcatSignalsFromFiles(pathnames,outfolder)
% ConcatSignalsFromFiles(..., <Option1>,<Value>,<Option2>,{Value>,...)
%
% Files used: "names.txt"
%             "include.txt"
%             "exclude.txt"
%
% Collects a defined set of signals from data files found in a folder, 
% and concatenates them into a full-length signal group with associated 
% 'Time' group.  Input 'dname' specifies the data folder, and 'filetype' 
% specifies a file type among any valid type recognized by VTool (see 
% function "IsFileType").  Alternatively, a cell array of pathnames to 
% desired input files may be directly specified via a 'pathnames' argument. 
%
% The named signals are extracted from each file, and concatenated into 
% a single signal group, extending the data length until the files are 
% exhausted.  The same procedure is followed with the time vector from 
% each file.  The signal group is generically named 'Signals' and the 
% time group 'Time'. 
% 
% The desired signal names are specified in file "names.txt", which 
% must be present in the 'dname' folder or the current working 
% directory, with the current working directory taking precedence. 
% Alternatively, signal names can be specified via the 'Selections' 
% option below.  All named signals are represented in the resulting 
% signal group, with the signal data reverting to all NaNs for any 
% signals not found in a particular file. 
%
% As an alternative to operating on all files found in the 'dname folder, 
% specific filenames to be included may be listed in a file "include.txt" 
% placed either in the current working directory or the 'dname' folder.  
% That file may list either simple filenames or full pathnames. If some 
% files are to be excluded, those filenames or pathnames should be listed 
% in a file called "exclude.txt" and the file placed in the working 
% directory or 'dname' folder. The "include.txt" file, if found, is read 
% before any "exclude.txt" file.  If these files are found in both 
% locations, the current working directory takes precedence. 
%
% Additional options may be specified via option/value pairs, as follows: 
%   'Selections'      -  cell array of signal names to collect. Overrides  
%                        retrieval of these names from "names.txt". 
%   'SourceType'      -  'sourcetype' identifier from "NameTables.xlsx", 
%                        specifying units conversions and description 
%                        modifications to be applied to the named signals 
%                        (see function "ExtractData"). 
%   'CategoryFun'     -  function handle applied to file root names to 
%                        derive "category strings".  If provided, the 
%                        function performs a separate concatenation operation 
%                        for each detected category. As an example, the 
%                        function @(x)x(1:10) can be used to extract date 
%                        strings from root names that start with the pattern 
%                        'yyyy-mm-dd', to perform separate collections by 
%                        date. (Root names are derived from pathnames 
%                        using function "GetRootname".) 
%   'DownSampFactor'  -  integer-valued downsampling factor. If specified, 
%                        all signals are downsampled by this factor. 
%   'NanSeparators'   -  'on' or 'off' (default). If 'on', NaN values 
%                        are placed at the signal endpoints before 
%                        concatenation, to permit signals from individual 
%                        input files to be distinguished when plotting. 
%   'OutputTag'       -  optional tag string to be included as part of 
%                        the output filename (see below). 
%
% The resulting signal group 'Signals' and time group 'Time', along with 
% a cell array 'fnames' listing the names and order of files read, are 
% stored as .mat file "joined_signals.mat" within the 'dname' folder, 
% unless an optional output folder 'outfolder' is specified.  If 'pathnames' 
% are specified, the 'outfolder' argument is required.  If concatenation 
% is by category, the output files are named "joined_signals_*.mat", with 
% the derived category strings appended.  The 'OutputTag' string, if 
% provided, is enclosed in parentheses and appended at the end of the 
% final filename root. 
%
% See also "CollectSignalsFromFiles", "ConcatSignalsFromResults", etc. 
%
% P.G. Bonanni
% 1/27/21

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


vars = varargin;
if isempty(vars)
  error('Invalid usage.')
end

% First input
inp = vars{1};

% If a single file pathname given ...
if ischar(inp) && exist(inp,'file') && ~isdir(inp)
  inp = cellstr(inp);
  vars{1} = inp;
end

% Check first input argument
if iscell(inp) && ~iscellstr(inp)
  error('Invalid ''pathnames'' input.')
elseif ~iscell(inp) && ~ischar(inp)
  error('Invalid ''dname'' or ''pathnames'' input.')
elseif ~iscell(inp) && ~isdir(inp)
  error('Specified ''dname'' is not valid.')
end

% Define all inputs
if ~iscell(inp)
  if nargin < 2
    error('Invalid usage.')
  end
  dname    = vars{1};
  filetype = vars{2};
  if nargin >= 3
    outfolder = vars{3};
    vars(1:3) = [];
  else
    outfolder = '';
    vars(1:2) = [];
  end
else  % if iscell(inp)
  if nargin < 2
    error('Must specify ''outfolder'' if ''pathnames'' are specified.')
  end
  dname     = '.';
  pathnames = vars{1};
  outfolder = vars{2};
  vars(1:2) = [];
end

% Initialize
selections     = [];
sourcetype     = '';
categoryfun    = [];
downsampfactor = [];
nanseparators  = [];
outputtag      = [];

% Process option/value pairs
if ~isempty(vars)
  % Check pairs
  OptionsList = {'Selections','SourceType','CategoryFun','DownSampFactor','NanSeparators','OutputTag'};
  if ischar(outfolder) && any(strcmp(outfolder,OptionsList))
    error('Must specify ''outfolder'' (or [] for default) when using option/value pair(s).')
  elseif rem(length(vars),2) ~= 0
    error('Invalid usage. Incomplete option/value pair(s).')
  elseif any(~cellfun('isclass',vars(1:2:end),'char'))
    error('One or more invalid options specified.')
  elseif any(~ismember(vars(1:2:end),OptionsList))
    error('One or more invalid options specified.')
  end
  % Get options list
  Options = vars(1:2:end);
  if length(unique(Options)) ~= length(Options)
    fprintf('WARNING: One or more options is repeated.\n')
  end
  % Make option/value assignments
  for k = 1:2:length(vars)
    eval(sprintf('%s = vars{%d};',lower(vars{k}),k+1));
  end
end

% Check 'filetype', 'selections', 'sourcetype', 'categoryfun', and 'outputtag'
if ischar(inp) && ~ischar(filetype)
  error('Invalid ''filetype'' input.')
elseif ~(isnumeric(selections) && isempty(selections)) && ~iscellstr(selections)
  error('Invalid ''Selections'' option.')
elseif ~ischar(sourcetype)
  error('Invalid ''SourceType'' option.')
elseif ~isa(categoryfun,'function_handle') && ...
       ~(isnumeric(categoryfun) && isempty(categoryfun))
  error('Specified ''CategoryFun'' option is not valid.')
elseif ~ischar(outputtag) && ...
       ~(isnumeric(outputtag) && isempty(outputtag))
  error('Invalid ''OutputTag'' option.')
end

% Set default 'downsampfactor' if necessary
if isnumeric(downsampfactor) && isempty(downsampfactor)
  downsampfactor = 1;
end

% Check that 'outfolder' is specified when required
if iscell(inp) && isempty(outfolder)
  error('Must specify ''outfolder'' if ''pathnames'' are specified.')
end

% Set default output folder if necessary
if ischar(inp) && isempty(outfolder), outfolder=dname; end

% Check that 'dname' and 'outfolder' are valid
if ~ischar(dname)
  error('Specified ''dname'' is not valid.')
elseif ~isdir(dname)
  error('Specified ''dname'' (''%s'') does not exist.',dname)
elseif ~ischar(outfolder)
  error('Specified ''outfolder'' is not valid.')
elseif ~isdir(outfolder)
  error('Specified ''outfolder'' (''%s'') does not exist.',outfolder)
end

% Check 'downsampfactor' for validity
if ~isnumeric(downsampfactor) || ...
   (isnumeric(downsampfactor) && (downsampfactor < 1 || rem(downsampfactor,1)~=0))
  error('Specified ''downsampfactor'' is not valid.  Must be a positive integer.')
end

% Set default 'nanseparators' option if necessary
if isnumeric(nanseparators) && isempty(nanseparators)
  nanseparators = 'off';
end

% Check 'nanseparators' option for validity
if ~ischar(nanseparators) || ...
   (ischar(nanseparators) && ~any(strcmp(nanseparators,{'on','off'})))
  error('Specified ''NanSeparators'' is not valid.  Must be ''on'' or ''off''.')
end

% Build tag string to be appended to output filename root
if isempty(outputtag), tagstr=''; else tagstr=sprintf(' (%s)',outputtag); end

% Determine signal name selections
if ~isempty(selections)
  names = selections(:);
else
  % Look for "names.txt" file
  namesfile1 = fullfile('.',  'names.txt');
  namesfile2 = fullfile(dname,'names.txt');
  if exist(namesfile1,'file')
    fprintf('Found: %s\n',namesfile1);
    namesfile = namesfile1;
  elseif exist(namesfile2,'file')
    fprintf('Found: %s\n',namesfile2);
    namesfile = namesfile2;
  else
    error('No ''Selections'' specified or "names.txt" file found.')
  end
  % Get signal-name list
  names = textread(namesfile,'%s','delimiter','\n');
  names(cellfun(@isempty,names)) = [];
end

% If 'folder' was specified
if ischar(inp)
  % Find files of the specified type, conditioned by any inclusions/exclusions
  pathnames = FindFilesOfType(dname,filetype,0);
end

% Number of files
ncases = numel(pathnames);

% Return immediately if no files
if ncases==0
  fprintf('No files to read!\n');
  return
end

% If a 'CategoryFun' option selected
if ~isempty(categoryfun)

  % Extract rootnames from all pathnames
  rootnames = cellfun(@GetRootname,pathnames,'Uniform',false);

  % Derive categories using the specified function
  categories = cellfun(categoryfun,rootnames,'Uniform',false);
  Categories = unique(categories,'stable');

  % Process pathnames by category
  for k = 1:length(Categories)
    category = Categories{k};
    mask = strcmp(category,categories);
    pathnames1 = pathnames(mask);

    % Process pathnames within the current category
    results = ProcessFiles(pathnames1,sourcetype,downsampfactor,nanseparators,names);

    % Save results
    fname = sprintf('joined_signals_%s%s.mat',category,tagstr);
    outfile = fullfile(outfolder,fname);
    save(outfile,'-v7.3','-struct','results');
    fprintf('File "%s" written.\n',outfile);
  end

else
  % Process all pathnames as one category
  results = ProcessFiles(pathnames,sourcetype,downsampfactor,nanseparators,names);

  % Save results
  fname = sprintf('joined_signals%s.mat',tagstr);
  outfile = fullfile(outfolder,fname);
  save(outfile,'-v7.3','-struct','results');
  fprintf('File "%s" written.\n',outfile);
end



% ---------------------------------------------------------------------------------------
function results = ProcessFiles(pathnames,sourcetype,downsampfactor,nanseparators,names)

% Process the list of input files defined by 'pathnames', with 
% sourcetype option 'sourcetype', downsampling factor 'downsampfactor', 
% separation option 'nanseparators', and desired signal 'names' list. 
% Return collected quantities as fields of 'results' structure. 

% Extract filenames from pathnames
[~,Nam,Ext] = cellfun(@fileparts,pathnames,'Uniform',false);
fnames = strcat(Nam,Ext);

% Number of files
ncases = numel(pathnames);

% Initialize signal group arrays
Signals = [];
Time    = [];

% Loop over files
for k = 1:ncases
  pathname = pathnames{k};
  fprintf('Reading file %d of %d\n',k,ncases);
  disp(fnames{k})

  % Extract simulation results
  s = ExtractData(pathname,sourcetype,'nowarn');

  % Downsample according to 'downsampfactor'
  s = DownsampleDataset(s,downsampfactor);

  % Define a signal group containing the named signals
  % (with NaN placeholders for any names not present)
  s = DefineSignalGroup(s,'Collection',names);

  % Extract named signals and time, as groups
  Signals1 = s.Collection;
  Time1    = s.Time;

  % If NaN separation is specified
  if strcmp(nanseparators,'on')
    Signals1 = ApplyMask(Signals1,'last',nan);
  end

  % Concatenate
  if k == 1
    Signals = Signals1;
    Time    = Time1;
  else
    Signals = ConcatSignalGroups(Signals,Signals1);
    Time    = ConcatSignalGroups(Time,Time1);
  end
end

% Return results
results.Signals = Signals;
results.Time    = Time;
results.fnames  = fnames;

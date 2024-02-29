function CollectDataFromResults(inp,outfolder,varargin)

% COLLECTDATAFROMRESULTS - Collect datasets from result files in a folder.
% CollectDataFromResults(dname [,outfolder])
% CollectDataFromResults(pathnames,outfolder)
% CollectDataFromResults(..., <Option1>,<Value>,<Option2>,{Value>,...)
%
% Files used: "include.txt"
%             "exclude.txt"
%             "LoadResults.m"
%
% Collects datasets from VTool "results" files found in folder 'dname'.  
% Files are assumed to be named according to the convention "results_*.mat" 
% and their contents are assumed to include one or more VTool datasets. 
% Alternatively, a cell array of pathnames to desired input files is 
% directly specified via a 'pathnames' argument. 
%
% The datsets are assembled into dataset arrays, one per dataset variable, 
% with each element of the arrays corresponding to a single identified 
% (or specified) file.  The dataset arrays are named by converting the 
% original dataset variable names to all-caps (e.g., 'DataIn' becomes 
% 'DATAIN').  The arrays have the same dimension as the specified or 
% derived 'pathnames' list. 
%
% As an alternative to operating on all results files found in the 
% 'dname' folder, specific filenames to be included may also be listed 
% in a file "include.txt" placed either in the current working directory 
% or the 'dname' folder.  That file may list either simple filenames or 
% full pathnames. If some files are to be excluded, those filenames or 
% pathnames should be listed in a file called "exclude.txt" and the file 
% placed in the working directory or 'dname' folder. The "include.txt" 
% file, if found, is read before any "exclude.txt" file.  If these files 
% are found in both locations, the current working directory takes 
% precedence. 
%
% Any non-dataset variables found in the files are assembled into 
% arrays of the appropriate type, with length equal to the number 
% of files.  NOTE: All files must contain the same variables, or an 
% error will result. 
%
% The function "LoadResults" is used to load data from the input files. 
% The default version of this function can be found in "<VTool>\templates". 
% A local copy of this function can be used to provide user-definable 
% modifications to the file contents (e.g., re-sampling or other 
% size-reducing operations).  As an alternative to a local copy, a user-
% defined function handle may be directly provided via the 'LoadFun' 
% option (see below). 
%
% Additional options may be specified via option/value pairs, as follows: 
%   'LoadFun'         -  function handle defining a user-selectable 
%                        load function. For example, @(x)load(x,'var1') 
%                        limits loading to the 'var1' variable only. 
%   'CategoryFun'     -  function handle applied to file root names to 
%                        derive "category strings".  If provided, the 
%                        function performs a separate collection operation 
%                        for each detected category. As an example, the 
%                        function @(x)x(1:10) can be used to extract date 
%                        strings from root names that start with the pattern 
%                        'yyyy-mm-dd', to perform separate collections by 
%                        date. (Root names are derived from pathnames 
%                        using function "GetRootname".) 
%   'DownSampFactor'  -  integer-valued downsampling factor. If specified, 
%                        all datasets are downsampled by this factor. 
%   'TimeRange'       -  1 x 2 vector specifying a desired [Tmin,Tmax] 
%                        within the available time range. This operation 
%                        is applied after any downsampling. See function 
%                        "LimitTimeRange" for options. 
%   'OutputTag'       -  optional tag string to be included as part of 
%                        the output filename (see below). 
%
% The resulting dataset array(s), along with array(s) representing non-
% dataset variables, plus a cell array containing the included filenames, 
% are stored as file "collected_datasets.mat" within the 'dname' folder, 
% unless an optional output folder 'outfolder'is specified. If 'pathnames' 
% are specified, the 'outfolder' argument is required.  If collection is 
% by category, the output files are named "collected_datasets_*.mat", with 
% the derived category strings appended.  The 'OutputTag' string, if 
% provided, is enclosed in parentheses and appended at the end of the 
% final filename root. 
%
% See also "ConcatDataFromResults", "CollectDataFromFiles", etc. 
%
% P.G. Bonanni
% 11/10/19

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


% Initialize
loadfun        = [];
categoryfun    = [];
downsampfactor = [];
timerange      = [];
outputtag      = [];

if nargin == 1
  outfolder = '';
elseif nargin > 2
  % Check option/value pairs
  OptionsList = {'LoadFun','CategoryFun','DownSampFactor','TimeRange','OutputTag'};
  if ischar(outfolder) && any(strcmp(outfolder,OptionsList))
    error('Must specify ''outfolder'' (or [] for default) when using option/value pair(s).')
  elseif rem(length(varargin),2) ~= 0
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
    eval(sprintf('%s = varargin{%d};',lower(varargin{k}),k+1));
  end
end

% Check 'loadfun', 'categoryfun', and 'outputtag' for validity
if ~isa(loadfun,'function_handle') && ...
   ~(isnumeric(loadfun) && isempty(loadfun))
  error('Specified ''LoadFun'' option is not valid.')
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

% Check 'downsampfactor' for validity
if ~isnumeric(downsampfactor) || ...
   (isnumeric(downsampfactor) && (downsampfactor < 1 || rem(downsampfactor,1)~=0))
  error('Specified ''downsampfactor'' is not valid.  Must be a positive integer.')
end

% Check 'timerange' for validity
if ~(isnumeric(timerange) && (isempty(timerange) || all(size(timerange)==[1,2]))) && ...
   ~(isa(timerange,'datetime') && all(size(timerange)==[1,2]))
  error('Specified ''timerange'' is not valid.  Must be a 1x2 vector of time values, or [].')
end

% Build tag string to be appended to output filename root
if isempty(outputtag), tagstr=''; else tagstr=sprintf(' (%s)',outputtag); end

% If a single file pathname given ...
if ischar(inp) && exist(inp,'file') && ~isdir(inp)
  inp = cellstr(inp);
end

% Confirm that ''pathnames'' is a cell array of strings
if iscell(inp) && ~iscellstr(inp)
  error('Invalid ''pathnames'' input.')
end

% Check that 'outfolder' is specified when required
if iscell(inp) && isempty(outfolder)
  error('Must specify ''outfolder'' if ''pathnames'' are specified.')
end

% Set 'dname', with default to '.' if 'pathnames' specified
if ischar(inp), dname=inp; else dname='.'; end

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

% Get pathname list
if ischar(inp)
  % Find result files, conditioned by any inclusions/exclusions
  pathnames = FindResultsPathnames(dname,0);
else
  % Use provided pathnames
  pathnames = inp;
end

% Number of files
ncases = numel(pathnames);

% Return immediately if no files
if ncases==0
  fprintf('No files to read!\n');
  return
end

% Set default and notify user if a non-default "LoadResults" will be used
if isempty(loadfun)  % if a function handle was not provided ...
  loadfun = @LoadResults;
  SRC = fileparts(which(mfilename));  % VTool source folder
  funpath = which('LoadResults');
  if ~strcmp(funpath,fullfile(SRC,'templates','LoadResults.m'))
    fprintf('NOTE: Results loaded using: "%s".\n',funpath);
  end
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
    results = ProcessResultsFiles(pathnames1,loadfun,downsampfactor,timerange);

    % Save results
    fname = sprintf('collected_datasets_%s%s.mat',category,tagstr);
    outfile = fullfile(outfolder,fname);
    save(outfile,'-v7.3','-struct','results');
    fprintf('File "%s" written.\n',outfile);
  end

else
  % Process all pathnames as one category
  results = ProcessResultsFiles(pathnames,loadfun,downsampfactor,timerange);

  % Save results
  fname = sprintf('collected_datasets%s.mat',tagstr);
  outfile = fullfile(outfolder,fname);
  save(outfile,'-v7.3','-struct','results');
  fprintf('File "%s" written.\n',outfile);
end



% ----------------------------------------------------------------------------------
function results = ProcessResultsFiles(pathnames,loadfun,downsampfactor,timerange)

% Process the list of results files defined by 'pathnames', with 
% load function 'loadfun' and downsampling factor 'downsampfactor'. 
% Return collected/concatenated variables as fields of 'results' 
% structure. 

% Extract filenames from pathnames
[~,Nam,Ext] = cellfun(@fileparts,pathnames,'Uniform',false);
fnames = strcat(Nam,Ext);

% Load first file and survey contents to determine 
% which variables are VTool datasets
s = loadfun(pathnames{1});
vnames = fieldnames(s);  % get variable names
isdataset = structfun(@(x)IsDataset(x),s);  % detect datasets

% Number of files
ncases = numel(pathnames);

% Initialize master array
S = [];

% Loop over files
for k = 1:ncases
  pathname = pathnames{k};
  fprintf('Reading file %d of %d\n',k,ncases);
  disp(fnames{k})

  % Extract results data
  s = loadfun(pathname);

  % Check that file contains the same variables
  if ~isempty(setxor(fieldnames(s),vnames))
    error('All result files must contain the same variables.')
  end

  % Loop over variables
  for j = 1:length(vnames)
    vname = vnames{j};   % variable name

    % If variable is a dataset
    if isdataset(j)

      % Downsample according to specified 'downsampfactor'
      s.(vname) = DownsampleDataset(s.(vname),downsampfactor);

      % Limit time range according to specified 'timerange'
      s.(vname) = LimitTimeRange(s.(vname),timerange);

      % Transfer into the new field name
      Dname = upper(vname);  % dataset array name
      s.(Dname) = s.(vname);
      s = rmfield(s,vname);
    end
  end

  % Append to array
  S = [S; s];
end

% Update variable names
vnames = fieldnames(S);

% Concatenate variables into arrays matching 'pathnames' in dimension
for j = 1:length(vnames)
  vname = vnames{j};  % variable name
  if isstruct(S(1).(vname)) && isscalar(S(1).(vname))
    results.(vname) = cat(1,S.(vname));
  else  % all other types
    results.(vname) = {S.(vname)}';
  end
  % Reshape to match provided 'pathnames'
  results.(vname) = reshape(results.(vname), size(pathnames));
end

% Add filenames field
results.fnames = fnames;

% Check dataset arrays for validity and data-length uniformity
vnames = fieldnames(results);  % final list of variables
for j = 1:length(vnames)
  vname = vnames{j};  % variable name
  [flag,valid,warning1] = IsDatasetArray(results.(vname));
  if flag && numel(results.(vname)) > 1
    nvec = arrayfun(@(x)length(x.Time.Values),results.(vname));
    warning2 = 'Data lengths are not uniform.';
    if ~valid,              fprintf('WARNING on ''%s'': %s\n',vname,warning1); end
    if ~all(nvec==nvec(1)), fprintf('WARNING on ''%s'': %s\n',vname,warning2); end
  end
end

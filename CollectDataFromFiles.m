function CollectDataFromFiles(varargin)

% COLLECTDATAFROMFILES - Collect datasets from data files in a folder.
% CollectDataFromFiles(dname,filetype,datafun [,outfolder])
% CollectDataFromFiles(pathnames,datafun,outfolder)
% CollectDataFromFiles(..., <Option1>,<Value>,<Option2>,{Value>,...)
%
% Files used: "include.txt"
%             "exclude.txt"
%
% Forms VTool datasets by running the dataset-building function specified 
% by function handle 'datafun' on data files found in a folder, and stacks 
% them into a dataset array. 
%
% Input 'dname' specifies the data folder, and 'filetype' specifies 
% a file type among any valid type recognized by VTool (see function 
% "IsFileType").  Alternatively, a cell array of pathnames to desired 
% input files may be directly specified via a 'pathnames' argument. The 
% dimensions of the dataset array follow from those of the 'pathnames' 
% argument. 
%
% Function 'datafun' is any function taking a data file pathname as input 
% and producing a single VTool dataset as output.  Datasets are assembled 
% into a dataset array 'DATA', with each element of the array representing 
% the dataset formed from a single identified (or specified) file. 
% 
% As an alternative to operating on all files found, specific filenames 
% to be included may be listed in a file "include.txt" placed either in 
% the current working directory or the 'dname' folder.  That file may 
% list either simple filenames or full pathnames. If some files are to 
% be excluded, those filenames or pathnames should be listed in a file 
% called "exclude.txt" and the file placed in the working directory 
% or 'dname' folder. The "include.txt" file, if found, is read before 
% any "exclude.txt" file.  If these files are found in both locations, 
% the current working directory takes precedence. 
%
% Additional options may be specified via option/value pairs, as follows: 
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
% The resulting dataset array and a cell array 'fnames' containing the 
% included filenames are stored as file "collected_datasets.mat" within 
% the 'dname' folder, unless an optional output folder 'outfolder' is 
% specified.  If 'pathnames' are specified, the 'outfolder' argument 
% is required.  If collection is by category, the output files are named 
% "collected_datasets_*.mat", with the derived category strings appended. 
% The 'OutputTag' string, if provided, is enclosed in parentheses and 
% appended at the end of the final filename root. 
%
% See also "ConcatDataFromFiles", "CollectDataFromResults", etc. 
%
% P.G. Bonanni
% 11/16/19

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
  if nargin < 3
    error('Invalid usage.')
  end
  dname    = vars{1};
  filetype = vars{2};
  datafun  = vars{3};
  if nargin >= 4
    outfolder = vars{4};
    vars(1:4) = [];
  else
    outfolder = '';
    vars(1:3) = [];
  end
else  % if iscell(inp)
  if nargin < 3
    error('Must specify ''outfolder'' if ''pathnames'' are specified.')
  end
  dname     = '.';
  pathnames = vars{1};
  datafun   = vars{2};
  outfolder = vars{3};
  vars(1:3) = [];
end

% Initialize
categoryfun    = [];
downsampfactor = [];
timerange      = [];
outputtag      = [];

% Process option/value pairs
if ~isempty(vars)
  % Check pairs
  OptionsList = {'CategoryFun','DownSampFactor','TimeRange','OutputTag'};
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

% Check 'filetype', 'datafun', 'categoryfun', and 'outputtag'
if ischar(inp) && ~ischar(filetype)
  error('Invalid ''filetype'' input.')
elseif ~isa(datafun,'function_handle')
  error('Input ''datafun'' is not a valid function handle.')
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

% Check 'timerange' for validity
if ~(isnumeric(timerange) && (isempty(timerange) || all(size(timerange)==[1,2]))) && ...
   ~(isa(timerange,'datetime') && all(size(timerange)==[1,2]))
  error('Specified ''timerange'' is not valid.  Must be a 1x2 vector of time values, or [].')
end

% Build tag string to be appended to output filename root
if isempty(outputtag), tagstr=''; else tagstr=sprintf(' (%s)',outputtag); end

% If 'folder' was specified
if ischar(inp)
  % Find files of the specified type, conditioned by any inclusions/exclusions
  pathnames = FindFilesOfType(dname,filetype,0);
end

% Number of files
ncases = numel(pathnames);

% Return immediately if no files
if ncases==0
  fprintf('No files to process!\n');
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
    results = ProcessFiles(pathnames1,datafun,downsampfactor,timerange);

    % Save results
    fname = sprintf('collected_datasets_%s%s.mat',category,tagstr);
    outfile = fullfile(outfolder,fname);
    save(outfile,'-v7.3','-struct','results');
    fprintf('File "%s" written.\n',outfile);
  end

else
  % Process all pathnames as one category
  results = ProcessFiles(pathnames,datafun,downsampfactor,timerange);

  % Save results
  fname = sprintf('collected_datasets%s.mat',tagstr);
  outfile = fullfile(outfolder,fname);
  save(outfile,'-v7.3','-struct','results');
  fprintf('File "%s" written.\n',outfile);
end



% ---------------------------------------------------------------------------
function results = ProcessFiles(pathnames,datafun,downsampfactor,timerange)

% Process the list of input files defined by 'pathnames', with 
% dataset function 'datafun' and downsampling factor 'downsampfactor'. 
% Return collected quantities as fields of 'results' structure. 

% Extract filenames from pathnames
[~,Nam,Ext] = cellfun(@fileparts,pathnames,'Uniform',false);
fnames = strcat(Nam,Ext);

% Number of files
ncases = numel(pathnames);

% Initialize dataset array
DATA = [];

% Loop over files
for k = 1:ncases
  pathname = pathnames{k};
  fprintf('------------------------------\n');
  fprintf('Processing file %d of %d\n',k,ncases);
  disp(fnames{k})

  % Build dataset from file
  Data = datafun(pathname);

  % Downsample according to 'downsampfactor'
  Data = DownsampleDataset(Data,downsampfactor);

  % Limit time range according to 'timerange'
  Data = LimitTimeRange(Data,timerange);

  % Append to array
  DATA = [DATA; Data];
end

% Check resulting array for validity
[flag,valid,errmsg] = IsDatasetArray(DATA);
if ~flag || ~valid, fprintf('WARNING: %s\n',errmsg); end

% Check data-length uniformity
nvec = arrayfun(@(x)length(x.Time.Values),DATA);
if ~all(nvec==nvec(1)), fprintf('WARNING: Data lengths are not uniform.\n'); end

% Reshape array to match 'pathnames'
DATA = reshape(DATA, size(pathnames));

% Return results
results.DATA   = DATA;
results.fnames = fnames;

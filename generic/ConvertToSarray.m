function ConvertToSarray(varargin)

% CONVERTTOSARRAY - Convert files to S-array .mat files.
% ConvertToSarray(pathname)
% ConvertToSarray(pathnames)
% ConvertToSarray(folder,filetype)
% ConvertToSarray(...., names)
%
% Bulk file conversion function. 
%
% Converts data files to VTool S-array format.  Operates on either 
% 1) the single file pointed to by 'pathname', or 2) a list of files 
% of matching file type, designated by a cell array of 'pathnames', e.g.,  
% {'pathname1','pathname2',...}, or 3) files contained with a specified 
% 'folder' and matching a specified 'filetype' (see function "IsFileType"). 
%
% The conversion can be limited to a specific set of signals via an 
% optional final argument 'names', which is a cell array listing the 
% names of the desired signals.  Signals not named in this list are 
% excluded from the output file(s). 
%
% The S-array format preserves the individual signal sampling, enabling 
% clean-up/filtering operations prior to re-sampling onto a common time 
% grid via "ExtractData".  Type "help formats" and see function "IsSarray" 
% for additional information on S-array format. 
%
% Output file naming
% -------------------
% The output .mat file for each input file is named using the convention 
% "S_<rootname>.mat", where <rootname> is the root name of the input file, 
% and the file is saved to the same folder where the input file resides.  
% (If two input files share the same root name, only the first is converted.)  
%
% See also "ConvertToVtl". 
%
% P.G. Bonanni
% 10/24/18

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


if isempty(varargin)
  error('Invalid usage.')
elseif length(varargin) == 1
  inp      = varargin{1};
  filetype = [];
  names    = [];
elseif length(varargin) == 2
  inp = varargin{1};
  if ischar(varargin{2})
    filetype = varargin{2};
    names    = [];
  elseif iscell(varargin{2})
    filetype = [];
    names    = varargin{2};
  else
    error('Invalid usage.')
  end
elseif length(varargin) == 3
  inp      = varargin{1};
  filetype = varargin{2};
  names    = varargin{3};
else
  error('Invalid usage.')
end

% If a single file pathname given ...
if ischar(inp) && ~isdir(inp)
  inp = cellstr(inp);
end

% Check for 'filetype' argument
if ischar(inp) && isempty(filetype)
  error('Input ''filetype'' is missing.')
elseif ischar(inp) && ~ischar(filetype)
  error('Input ''filetype'' is invalid.')
elseif iscell(inp) && ~isempty(filetype)
  error('Specification of ''filetype'' is only valid when a folder name is provided.')
end

% Check 'names' argument (allow only [] or cell array of names)
if ~(isnumeric(names) && isempty(names)) && ~iscellstr(names)
  error('Input ''names'' is invalid.')
end

% Derive input pathnames
if ischar(inp)  % if folder specified ...

  % Get full directory listing
  list = dir(inp);

  % Mask for the specified 'filetype' only
  mask = IsFileType({list.name},filetype);

  % Extract file names
  fnames = {list(mask).name}';

  % Extract folder names
  if isfield(list,'folder')
    folders = {list(mask).folder}';
  elseif isdir(inp)
    folders = repmat({inp},size(fnames));
  else
    folders = {};
  end

  % Build 'pathnames1' list
  if ~isempty(folders)
    pathnames1 = cellfun(@fullfile,folders,fnames,'Uniform',false);
  else
    pathnames1 = {};
  end

  % Sort alphabetically
  if ~isempty(pathnames1)
    [~,i] = sort(fnames);
    pathnames1 = pathnames1(i);
  end

elseif iscell(inp)  % if cell-array specified ...

  % Pathnames specified directly
  pathnames1 = inp;

else
  error('Invalid input.')
end

% If list is empty
if isempty(pathnames1)
  fprintf('No files to convert!\n');
  return
end

% Determine/revise file type based on the first list entry
if IsFileType(pathnames1{1},    'vtool')
  filetype = 'vtool';
elseif IsFileType(pathnames1{1},'S-array')
  filetype = 'S-array';
elseif IsFileType(pathnames1{1},'xls')
  filetype = 'xls';
elseif IsFileType(pathnames1{1},'csv')
  filetype = 'csv';
else  % otherwise reject
  error('Unsupported input file type.')
end

% Warn about filetype being assumed the same
if iscell(inp) && length(inp) > 1
  fprintf('NOTE: All files assumed to be of same type (''%s''). ',filetype);
  fprintf('Results not guaranteed otherwise.\n');
end

% Return immediately if S-array type
if strcmp(filetype,'S-array')
  fprintf('S-array file exists. Exiting.\n');
  return
end

% Extract folder names
folders = cellfun(@fileparts,pathnames1,'Uniform',false);
mask = cellfun(@isempty,folders);  [folders{mask}]=deal('.');

% Reduce to a list with unique rootnames
[~,rootnames1,~] = cellfun(@fileparts,pathnames1,'Uniform',false);
[~,i] = unique(rootnames1,'stable');  % rootnames1 = rootnames1(i);
rootnames1 = rootnames1(i);
pathnames1 = pathnames1(i);
folders    = folders(i);

% Derive output pathnames
rootnames2 = rootnames1;
fnames2 = cellfun(@(x)sprintf('S_%s.mat',x),rootnames2,'Uniform',false);
pathnames2 = cellfun(@fullfile,folders,fnames2,'Uniform',false);

% Loop over pathnames
for k = 1:length(pathnames1)

  % Get and report pathnames
  pathname1 = pathnames1{k};
  pathname2 = pathnames2{k};
  fprintf('Converting %s\n', pathname1);
  fprintf('    to     %s\n', pathname2);

  % Read data from file
  switch filetype
    case 'vtool',       S = DataToSarray(ExtractData(pathname1));
    case {'xls','csv'}, S = ReadXlsFile(pathname1);
  end

  % Filter for specified names, if required
  if ~isempty(names)
    names = names(:);  % make column
    [mask,i] = ismember(names,{S.name});
    if ~all(mask)
      i = i(i~=0);
      fprintf('Warning: These specified names were not found:\n');
      disp(names(~mask))
    end
    S = S(i);
  end

  % Save to output file
  save(pathname2,'S');
end

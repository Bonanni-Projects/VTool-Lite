function [pathnames,fnames] = FindFilesOfPattern(dname,pat,depth)

% FINDFILESOFPATTERN - Find files matching a name pattern in a folder and subfolders.
% [pathnames,fnames] = FindFilesOfPattern(dname,pat)
% [pathnames,fnames] = FindFilesOfPattern(dname,pat,depth)
% [pathnames,fnames] = FindFilesOfPattern(dnames,...)
%
% Files used: "include.txt"
%             "exclude.txt"
%
% Recursively searches for files whose rootnames (per function 
% "GetRootname") match a specified pattern.  The specification 
% 'pat' may be either a character sequence or a regular expression. 
% The function searches folder 'dname' and all of its subfolders, 
% returning full pathnames and corresponding filenames in output 
% cell arrays 'pathnames' and 'fnames', respectively. 
%
% The user may augment or modify the directory search operation by 
% limiting the search depth and/or by filtering the filenames to be 
% considered.  Optional parameter 'depth' specifies the desired 
% search depth (number of directory levels below 'dname' to search, 
% valued at 0 or greater).  Filename filtering is accomplished by 
% placing filter files "include.txt" and/or "exclude.txt" in either 
% the working directory or the 'dname' folder.  Those files may list 
% either simple filenames or full pathnames.  The "include" file 
% lists names of files to be considered for inclusion, overriding the 
% directory search.  The "exclude" file lists names of files to be 
% excluded.  The "include.txt" file, if found, is read before any 
% "exclude.txt" file.  If these filter files are found in both 
% locations, the version(s) in the current working directory take 
% precedence. 
%
% If cell array 'dnames' is provided in place of a single 'dname' 
% pathname, the input is taken to be a list of folder pathnames.  
% In this case, the function is repeated for all array entries, 
% and the returned lists are concatenated. 
%
% See also "FindFilesOfType", "FindResultsPathnames".  
%
% P.G. Bonanni
% 11/8/19

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


if nargin < 3
  depth = inf;
end

% If cell array provided
if iscell(dname)
  dnames = dname;

  % Check array entries
  if ~all(cellfun(@ischar,dnames)) || ~all(cellfun(@isdir,dnames))
    error('Input ''dnames'' has one or more non-folder pathname entries.')
  end

  % Initialize
  pathnames = {};
  fnames    = {};

  % Loop over entries
  for k = 1:length(dnames)
    fprintf('----------------------------------------------------------------------------------------------------------------\n');
    fprintf(' Searching folder "%s".\n',dnames{k});
    fprintf('----------------------------------------------------------------------------------------------------------------\n');
    [pathnames1,fnames1] = FindFilesOfPattern(dnames{k},pat,depth);
    pathnames = [pathnames; pathnames1];
    fnames =    [fnames;    fnames1];
    fprintf('\n');
  end
  fprintf('Results concatenated.\n');

  % Remove any duplicates (possible if 'dnames' entries overlap)
  [pathnamesi,i] = unique(pathnames,'stable');
  if ~isequal(pathnames,pathnamesi)
    pathnames = pathnamesi;
    fnames =    fnames(i);
    fprintf('Duplicated removed.\n');
  end
  return
end

% Check 'dname' and 'pat' inputs
if ~ischar(dname)
  error('Input ''dname'' is invalid.')
elseif ~isdir(dname)
  error('Input ''dname'' is not a folder.')
elseif ~ischar(pat)
  error('Input ''pat'' is invalid.')
end

% Check 'depth' parameter
if ~isnumeric(depth)
  error('Input ''depth'' must be a numeric value.')
elseif ~isinf(depth) && ~(isscalar(depth) && rem(depth,1)==0 && depth >= 0)
  error('Input ''depth'' must be a non-negative integer value.')
end

% Remove trailing filesep character, if present
if dname(end)==filesep, dname=dname(1:end-1); end

% Search 'dname' and subfolders for valid filenames
pathnames = {};  % initialize
tree = strread(genpath(dname),'%s','delimiter',pathsep);
if ~isinf(depth)  % limit search depth
  fprintf('Search depth: %d\n',depth);
  fun = @(x)length(strfind(x,filesep));  % depth function
  mask = cellfun(fun,tree) <= fun(dname) + depth;
  tree = tree(mask);
end
for k = 1:length(tree)
  list = dir(tree{k});
  rootnames = cellfun(@GetRootname,{list.name}','Uniform',false);
  mask = ~cellfun(@isempty,regexp(rootnames,pat,'once'));
  pathnames1 = strcat(tree{k},filesep,{list(mask).name}');
  pathnames = [pathnames; pathnames1];
end

% Derive corresponding filenames
[~,Nam,Ext] = cellfun(@fileparts,pathnames,'Uniform',false);
fnames = strcat(Nam,Ext);

% Look for "include.txt" and "exclude.txt"
incfile1 = fullfile('.',  'include.txt');
incfile2 = fullfile(dname,'include.txt');
if exist(incfile1,'file')
  fprintf('Found: %s\n',incfile1);
  incfile = incfile1;
elseif exist(incfile2,'file')
  fprintf('Found: %s\n',incfile2);
  incfile = incfile2;
else
  fprintf('No "include.txt" file found.\n');
  incfile = '';
end
excfile1 = fullfile('.',  'exclude.txt');
excfile2 = fullfile(dname,'exclude.txt');
if exist(excfile1,'file')
  fprintf('Found: %s\n',excfile1);
  excfile = excfile1;
elseif exist(excfile2,'file')
  fprintf('Found: %s\n',excfile2);
  excfile = excfile2;
else
  fprintf('No "exclude.txt" file found.\n');
  excfile = '';
end

% If an "include" file was found, read it
inclusions = {};  % initialize
if ~isempty(incfile)
  inclusions = textread(incfile,'%s','delimiter','\n');
  inclusions(cellfun(@isempty,inclusions)) = [];
  mask = ~ismember(inclusions,fnames) & ~ismember(inclusions,pathnames);
  if any(mask)  % exclude and report any invalid entries
    fprintf('These entries in "include.txt" are not valid:\n');
    disp(inclusions(mask))
    inclusions(mask) = [];
  end
end

% If an "exclude" file was found, read it
exclusions = {};  % initialize
if ~isempty(excfile)
  exclusions = textread(excfile,'%s','delimiter','\n');
  exclusions(cellfun(@isempty,exclusions)) = [];
  mask = ~ismember(exclusions,fnames) & ~ismember(exclusions,pathnames);
  if any(mask)  % exclude any invalid entries
    fprintf('These entries in "exclude.txt" are not valid:\n');
    disp(exclusions(mask))
    exclusions(mask) = [];
  end
  n = length(exclusions);
  if n > 0 && n <= 20
    fprintf('Excluding these files:\n');
    disp(exclusions)
  elseif n > 20
    fprintf('Excluding %d files:\n',n);
    list = [exclusions(1:20); '...'];
    disp(list)
  end
end

% Convert any simple filenames to the equivalent pathnames
mask = cellfun(@(x)isempty(fileparts(x)),inclusions);  % simple entries
[~,i] = ismember(inclusions(mask),fnames);
[inclusions{mask}] = deal(pathnames{i});
mask = cellfun(@(x)isempty(fileparts(x)),exclusions);  % simple entries
[~,i] = ismember(exclusions(mask),fnames);
[exclusions{mask}] = deal(pathnames{i});

% Derive the final list of pathnames
if ~isempty(inclusions)
  % Limit to "included" cases, but ignore if empty
  pathnames = intersect(pathnames,inclusions,'stable');
end
% Always reject the "exclusions"
pathnames = setdiff(pathnames,exclusions);

% Derive corresponding filenames
[~,Nam,Ext] = cellfun(@fileparts,pathnames,'Uniform',false);
fnames = strcat(Nam,Ext);

% Report the final results
N = length(pathnames);
fprintf('Number of names returned: %d\n',N);
if N <= 20, disp(pathnames), end

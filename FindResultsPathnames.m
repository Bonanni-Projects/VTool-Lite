function [pathnames,fnames] = FindResultsPathnames(dname,depth)

% FINDRESULTSPATHNAMES - Find result files in a folder and its subfolders.
% [pathnames,fnames] = FindResultsPathnames(dname)
% [pathnames,fnames] = FindResultsPathnames(dname,depth)
%
% Files used: "include.txt"
%             "exclude.txt"
%
% Recursively searches for VTool "result" files in folder 'dname' and all 
% of its subfolders, returning full pathnames and corresponding filenames 
% in output cell arrays 'pathnames' and 'fnames', respectively. The result 
% files are understood to follow the naming convention "results_*.mat". 
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
% See also "FindFilesOfType". 
%
% P.G. Bonanni
% 9/5/18

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


if nargin < 2
  depth = inf;
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
  mask = IsValidFilename({list.name});
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
  mask = ~IsValidFilename(inclusions) | ...
    (~ismember(inclusions,fnames) & ~ismember(inclusions,pathnames));
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
  mask = ~IsValidFilename(exclusions) | ...
    (~ismember(exclusions,fnames) & ~ismember(exclusions,pathnames));
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



% ------------------------------------------------------------------------
function mask = IsValidFilename(list)

% Flags filenames matching a valid filename pattern for VTool 
% "result" files.  Input 'list' is a cell array of pathnames 
% or filenames. 

% Extract filename portions from all entries
[~,Nam,Ext] = cellfun(@fileparts,list,'Uniform',false);
filenames = strcat(Nam,Ext);

% Match the filenames against the valid patterns
mask = ~cellfun(@isempty,regexp(filenames,'^results_.*\.mat$','once'));

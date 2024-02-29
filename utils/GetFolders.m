function [folders,folderpaths] = GetFolders(pathname,pat)

% GETFOLDERS - Return a list of subfolders.
% [folders,folderpaths] = GetFolders(pathname)
% [folders,folderpaths] = GetFolders(pathname,pat)
%
% Finds the subfolders of 'pathname' and returns the 
% resulting list as output cell array 'folders', with 
% the entries sorted alphabetically.  Also returns 
% corresponding cell array 'folderpaths' containing 
% the full pathnames to the folders. 
%
% Optional argument 'pat' is a string or a regular 
% expression.  If this argument is supplied, the 
% returned lists include only the folders matching 
% the prescribed pattern. 
%
% P.G. Bonanni
% 4/2/20

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


if nargin < 2
  pat = '';
end

% Check inputs
if ~ischar(pathname)
  error('Invalid ''pathname'' input.')
elseif ~ischar(pat)
  error('Invalid ''pat'' input.')
end

% Get directory listing
list = dir(pathname);

% Extract folder names
i = [list.isdir];
folders = {list(i).name}';

% Exclude '.' and '..' directories
mask = ismember(folders,{'.','..'});
folders(mask) = [];

% Sort alphabetically
folders = sort(folders);

% Construct the folder pathnames
folderpaths = cellfun(@(x)fullfile(pathname,x),folders,'Uniform',false);

% If pattern supplied
if ~isempty(pat)
  mask = ~cellfun(@isempty,regexp(folders,pat,'once'));
  folders     = folders(mask);
  folderpaths = folderpaths(mask);
end

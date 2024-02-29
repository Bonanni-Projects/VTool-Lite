function fnames = GetFilename(pathnames)

% GETFILENAME - Extract filename(s) from pathname(s).
% fname = GetFilename(pathname)
% fnames = GetFilename(pathnames)
%
% Returns the filename portion of an input 'pathname'. If cell 
% array 'pathnames' is provided, an equal-sized cell array of 
% 'fnames' is returned. 
%
% P.G. Bonanni
% 6/10/22

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


% If single pathname supplied
if ischar(pathnames)
  pathnames = cellstr(pathnames);
end

% Derive filenames from pathnames
[~,Nam,Ext] = cellfun(@fileparts,pathnames,'Uniform',false);
fnames = strcat(Nam,Ext);

% If single pathname supplied
if isscalar(pathnames)
  fnames = fnames{1};
end

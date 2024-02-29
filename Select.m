function [pathnames,fnames] = Select(dname)

% SELECT - Select pathnames using a file browser.
% [pathnames,fnames] = Select
% [pathnames,fnames] = Select(dname)
% [pathnames,fnames] = Select('last')
%
% Opens a file selection dialog box permitting navigation and 
% selection of one or more files.  Full pathnames to the selected 
% files are returned as cell array 'pathnames', and filenames as 
% 'fnames'.  If a single file is selected, each output is returned 
% as a character string instead.  Optional input 'dname' specifies 
% a starting directory for browsing. 
%
% The resulting selection is stored in memory. If the keyword 'last' 
% is input, the function outputs the 'pathnames' and 'fnames' from 
% the most recent call to the function. 
%
% This function works for file selection only. To select folders, 
% use function "uigetdir". 
%
% P.G. Bonanni
% 3/7/20, updated 2/15/22

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


if nargin == 0
  dname = '';
end

% Check 'dname' input
if ~ischar(dname)
  error('The provided input is invalid.')
end

persistent pathnames1 fnames1

% Initialize
if isempty(pathnames1)
  pathnames1 = {};
  fnames1 = {};
end 

% Return previous results if requested
if strcmp(dname,'last')
  pathnames = pathnames1;
  fnames    = fnames1;
  return
end

% Open Matlab file browser and perform selection
[fnames,fpath] = uigetfile('*.*','Select One or More Files',dname,'MultiSelect','on');

% Set outputs
if iscell(fnames) && ischar(fpath)
  fnames = fnames(:);
  pathnames = strcat(fpath,fnames);
elseif ischar(fpath)
  pathnames = strcat(fpath,fnames);
else
  pathnames = {};
  fnames = {};
end

% Update memory
pathnames1 = pathnames;
fnames1    = fnames;

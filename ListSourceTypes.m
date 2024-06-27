function Tabs = ListSourceTypes(pathname)

% LISTSOURCETYPES - List the source types in "NameTables.xlsx".
% Tabs = ListSourceTypes
% Tabs = ListSourceTypes(pathname)
%
% Returns a list of the source types (tabs) in "NameTables.xlsx". 
% The "MASTER" tab is excluded.  If the optional 'pathname' argument 
% is supplied, the function reads the specified file in place of the 
% default "NameTables.xlsx" file. 
%
% P.G. Bonanni
% 5/6/19

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


if nargin < 1
  pathname = which('NameTables.xlsx');
end

% Check that file exists
if ~exist(pathname,'file')
  error('NameTables file not found. Must be on Matlab path.')
end

% List the sheets (tabs) in the file
[~,sheets] = xlsfinfo(pathname);

% Output all but "MASTER"
Tabs = setdiff(sheets,'MASTER');

% Make column
Tabs = Tabs(:);

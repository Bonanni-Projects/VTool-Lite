function mask = IsFileType(list,filetype)

% ISFILETYPE - Flag filenames belonging to a specified file type.
% mask = IsFileType(list,filetype)
%
% Flags entries in a list of filenames or pathnames for a match 
% to a specified file type.  Input 'list' is a single string or 
% a cell array of filenames (or pathnames).  Output 'mask' is an 
% equal-length binary mask, with TRUE values marking the filenames 
% belonging to the specified file type.  Recognized 'filetype' 
% values and their defining requirements are: 
%
%   filetype(*)  requirements(*)
%   -----------  ----------------
%    'vtool'     file extension '.vtl'
%    'S-array'   root name beginning with 'S_', file extension .mat
%    'xls'       file extension matching .xls or .xlsx
%    'csv'       file extension matching .csv
%    '.XXX'      file extension matching the characters 'XXX' following 
%                the '.' character. 
% (*) The 'filetype' input and file extensions are not case-sensitive. 
%
% Type "help formats" for more information on supported file formats. 
%
% P.G. Bonanni
% 9/8/18

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


% Check inputs
if ~ischar(list) && ~iscellstr(list)
  error('Input ''list'' must be a cell array of filenames/pathnames.')
elseif ~ischar(filetype)
  error('Input ''filetype'' must be a string.')
end

% If single entry supplied
if ischar(list)
  list = cellstr(list);
end

% Get filename parts
[~,Nam,Ext] = cellfun(@fileparts,list,'Uniform',false);

% Match filenames to file types
if strcmpi(filetype,'vtool') || strcmpi(filetype,'vtl')
  mask = strcmpi(Ext,'.vtl');
elseif strcmpi(filetype,'S-array')
  mask = ~cellfun(@isempty,regexp(Nam,'^S_','once')) & strcmpi(Ext,'.mat');
elseif strcmpi(filetype,'xls')
  mask = strcmpi(Ext,'.xls') | strcmpi(Ext,'.xlsx');
elseif strcmpi(filetype,'csv')
  mask = strcmpi(Ext,'.csv');
elseif strncmp(filetype,'.',1)
  mask = strcmpi(Ext,filetype);
else
  error('File type ''%s'' is not recognized.',filetype)
end

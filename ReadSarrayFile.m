function S = ReadSarrayFile(pathname)

% READSARRAYFILE - Read signal data from an S-array file.
% S = ReadSarrayFile(pathname)
%
% Reads signal data from an S-array .mat file, returning structure 
% array 'S'.  Input 'pathname' is the pathname to the file to be 
% read.  Output 'S' has a 'name' field containing the signal names 
% and additional fields corresponding to signal attributes.  The 
% fields are: 
%   'name'         -  signal name string
%   'data'         -  data vector
%   'dt'           -  sample time
%   'unitsT'       -  time units string
%   'units'        -  signal units string
%   'description'  -  signal description string
%   'trigger'      -  6-vector indicating start date and time
% Type "help formats" and see function "IsSarray" for additional 
% information on S-array format. 
%
% P.G. Bonanni
% 10/31/19

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


% If single-entry cell array provided
if iscellstr(pathname) && numel(pathname)==1
  pathname = pathname{1};
end

% Check input
if ~ischar(pathname)
  error('Input ''pathname'' is not valid.')
end

% Check that input file exists
if ~exist(pathname,'file')
  error('File "%s" does not exist.',pathname)
end

% Remaining input check
if ~IsFileType(pathname,'S-array')
  error('Accepts S-array format .mat files only.')
end

% Load data from file
data = load(pathname);

% Check contents
if ~isempty(setxor(fieldnames(data),{'S'}))
  error('Input file contents is not valid.')
end
[flag,valid] = IsSarray(data.S);
if ~flag || ~valid
  error('Contents ''S'' of file is not a valid S-array.  See "IsSarray".')
end

% Return S-array
S = data.S;

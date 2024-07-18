function out = BatchFunction(pathname,outfolder)

% BATCHFUNCTION - Compute results from a single input data file.
% BatchFunction(pathname [,outfolder])
% out = BatchFunction(pathname)
%
% (SAMPLE)
%
% P.G. Bonanni
% 2/1/20

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


if nargin < 2
  outfolder = [];
end

% No outputs if 'outfolder' specified
if nargout && nargin > 1
  error('Invalid usage.')
end

% Set default 'outfolder' if necessary
if isempty(outfolder), outfolder='.'; end

% Derive 'casename'
casename = GetRootname(pathname);

% Derive output file pathname
outfile = ['results_',casename,'.mat'];
outpath = fullfile(outfolder,outfile);

% -----------------------------------------------------------
% To speed processing when results already exist, set global
% variable "NEW_ONLY" and uncomment the lines below: 
% -----------------------------------------------------------
% global NEW_ONLY  % set to TRUE to skip over existing files
% if ~isempty(NEW_ONLY) && NEW_ONLY && ~nargout && exist(outpath,'file')
%   fprintf('File "%s" exists. Skipping.\n',outfile);
%   return
% end

% Load data from file
s = LoadResults(pathname);


% Sample calculation
x = 0;
y = 0;
z = 0;


if nargout
  out.x = x;
  out.y = y;
  out.z = z;

else
  % Save results
  save(outpath,'x','y','z')
end

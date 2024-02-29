function s = LoadResultsFiltered(pathname,Inclusions,Exclusions)

% LOADRESULTSFILTERED - Modified "load" function, employing filtering of variables.
% s = LoadResultsFiltered(pathname,Inclusions,[])
% s = LoadResultsFiltered(pathname,[],Exclusions)
%
% This function is called by functions "CollectDataFromResults", 
% "ConcatDataFromResults", "CollectSignalsFromResults", and 
% "ConcatSignalsFromResults" in place of the standard Matlab 
% "load" function. 
%
% This version allows specification of variables to include or 
% exclude in the loaded results.  The 'Inclusions' list represents 
% variable names in the file to be included, while the 'Exclusions' 
% list represents those to exclude.  The unused argument is 
% normally specified as [].  If both lists are provided, the 
% inclusions are considered before the exclusions. 
%
% P.G. Bonanni
% 5/27/21

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


if nargin < 3
  Exclusions = {};
end

% Interpret empties as {}
if isnumeric(Inclusions) && isempty(Inclusions)
  Inclusions = {};
end
if isnumeric(Exclusions) && isempty(Exclusions)
  Exclusions = {};
end

% Load data from file
s = load(pathname);

% Get variable names
vars = fieldnames(s);

% Check lists for validity
if ~iscellstr(Inclusions)
  error('The ''Inclusions'' list is invalid.')
elseif ~isempty(Inclusions) && ~all(ismember(Inclusions,vars))
  error('The ''Inclusions'' list contains one or more entries not found in the file.')
elseif ~iscellstr(Exclusions)
  error('The ''Exclusions'' list is invalid.')
elseif ~isempty(Exclusions) && ~all(ismember(Exclusions,vars))
  error('The ''Exclusions'' list contains one or more entries not found in the file.')
end

% Apply filtering
if ~isempty(Inclusions) && isempty(Exclusions)
  s = rmfield(s,setdiff(vars,Inclusions));
elseif isempty(Inclusions) && ~isempty(Exclusions)
  s = rmfield(s,Exclusions);
elseif ~isempty(Inclusions) && ~isempty(Exclusions)
  s = rmfield(s,setdiff(vars,setdiff(Inclusions,Exclusions)));
end

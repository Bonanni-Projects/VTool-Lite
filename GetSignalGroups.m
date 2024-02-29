function [s,fields] = GetSignalGroups(Data)

% GETSIGNALGROUPS - Get signal groups and group names.
% [s,fields] = GetSignalGroups(Data)
%
% Given dataset 'Data', consisting of signal-group and 
% non-signal-group fields, return structure 's' containing 
% only the signal-group fields.  Also return the field 
% names as 'fields'. 
%
% P.G. Bonanni
% 2/16/18

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


% Check input
if ~isstruct(Data)
  error('Invalid input.')
elseif numel(Data) > 1
  error('Works for scalar structures only.')
end

% Identify and collect signal groups
fields = fieldnames(Data);  % all fields
C = struct2cell(Data);      % all values
mask = cellfun(@IsSignalGroup,C);
Groups = C(mask);  fields=fields(mask);  % signal groups and fieldnames

% Return groups as fields of output 's'
s = cell2struct(Groups,fields,1);

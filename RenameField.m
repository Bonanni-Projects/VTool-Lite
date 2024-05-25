function S = RenameField(S,oldfields,newfields)

% RENAMEFIELD - Rename signal groups, name layers, or fields.
% Data = RenameField(Data,'oldgroup','newgroup')
% Data = RenameField(Data,{'oldgroup1','oldgroup2',...},{'newgroup1','newgroup2',...})
% Signals = RenameField(Signals,'oldlayer','newlayer')
% Signals = RenameField(Signals,{'oldlayer1','oldlayer2',...},{'newlayer1','newlayer2',...})
% S = RenameField(S,'oldfield','newfield')
% S = RenameField(S,{'oldfield1','oldfield2',...},{'newfield1','newfield2',...})
% DATA = RenameField(DATA, ...)
% SIGNALS = RenameField(SIGNALS, ...)
%
% Rename one or more signal groups or fields within an input structure 
% or structure array, while preserving their order.  Applies to groups 
% in a dataset, name layers in a signal group, or fields in an arbitrary 
% structure array, regardless of dimension.  Accepts either single strings 
% (e.g., 'oldname' and 'newname') or equal-length cell arrays of strings 
% specifying the old and corresponding new field names. 
%
% See also "RenameLayer". 
%
% P.G. Bonanni
% 3/30/18

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


% Check arguments
if ~isstruct(S)
  error('First input must be a structure or structure array.')
elseif ~ischar(oldfields) && ~iscellstr(oldfields)
  error('Input ''oldfields'' is invalid.')
elseif ~ischar(newfields) && ~iscellstr(newfields)
  error('Input ''newfields'' is invalid.')
end

% Make cell arrays if single strings provided
if ischar(oldfields), oldfields={oldfields}; end
if ischar(newfields), newfields={newfields}; end

% Make lists
oldfields = oldfields(:);
newfields = newfields(:);

% Get fieldnames
fields = fieldnames(S);

% Check lengths
if length(oldfields)~=length(newfields)
  error('Number of old and new field names must match.')
end

% Check that all old fields are present
if any(~ismember(oldfields,fields))
  error('One or more specified fields not present in the input structure.')
end

% Extract data
C = struct2cell(S);

% Make name substitutions
[~,i] = ismember(oldfields,fields);
[fields{i}] = deal(newfields{:});

% Rebuild structure (array)
S = cell2struct(C,fields,1);

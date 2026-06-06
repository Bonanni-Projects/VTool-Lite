function S = mvfield(S,field,position,field0)

% MVFIELD - Move a field of a structure to a new position in the order.
% S = mvfield(S,field,'first')
% S = mvfield(S,field,'last')
% S = mvfield(S,field,'before',field0)
% S = mvfield(S,field,'after',field0)
%
% Move the specified 'field' of structure (or structure array) 'S' to a 
% new position in the field order. Options for 'position' are 'first', 
% 'last', or 'before' or 'after' an additional specified 'field0'. 
%
% P.G. Bonanni
% 6/6/26

% Copyright (c) 2026  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


if nargin < 4
  field0 = '';
end

% Check first input
if ~isstruct(S)
  error('Input ''S'' must be a structure or structure array.')
end

% Get field names
fields = fieldnames(S);

% Check remaining inputs
if ~ischar(field) || ~ismember(field,fields)
  error('Input ''field'' is not valid.')
elseif ~ischar(position) || ~ismember(position,{'first','last','before','after'})
  error('Input ''position'' is not valid.')
elseif ~ischar(field0) || (~isempty(field0) && ~ismember(field0,fields))
  error('Input ''field0'' is not valid.')
end

% Check usage
if ( ismember(position,{'before','after'}) &&  isempty(field0)) || ...
   (~ismember(position,{'before','after'}) && ~isempty(field0))
  error('Invalid usage.')
end

% Compute new field order
newfields = setdiff(fields,field,'stable');  % initialize
switch position
  case 'first'
    newfields = [field; newfields];
  case 'last'
    newfields = [newfields; field];
  case 'before'
    [~,i] = ismember(field0,newfields);
    if i == 1
      newfields = [field; newfields];
    else
      newfields = [newfields(1:i-1); field; newfields(i:end)];
    end
  case 'after'
    [~,i] = ismember(field0,newfields);
    if i == length(newfields)
      newfields = [newfields; field];
    else
      newfields = [newfields(1:i); field; newfields(i+1:end)];
    end
end

% Reorder the fields
S = orderfields(S,newfields);

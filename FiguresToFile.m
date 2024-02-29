function FiguresToFile(outfile)

% FIGURESTOFILE - Save current figures to a .fig file.
% FiguresToFile(outfile)
%
% Saves the currently displayed figures to a Matlab .fig 
% file. Input 'outfile' specifies the output file. 
%
% P.G. Bonanni
% 8/19/19

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


% Get handles to displayed figures
handles = get(0,'Children');

% Return immediately if no figures
if isempty(handles)
  fprintf('No figures to save!\n');
  return
end

% Order handles according to figure number
C = get(handles,'Number');
if isscalar(C), num=C; else num=cat(1,C{:}); end
[~,i] = sort(num);  handles=handles(i);

% Add file extension if not present
[~,~,ext] = fileparts(outfile);
if ~strcmp(ext,'.fig')
  outfile = [outfile,'.fig'];
end

% Save to file, and assume Matlab 2014b or later
savefig(handles,outfile,'compact')

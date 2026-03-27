%% Utility function
% ===================================================================
% Author of this script:
%   Ki Heon Lee
% Contact:
%   kiheon97@gmail.com
% ===================================================================

function Ic = find_contrast_indices_by_name(spm_mat_path, contrast_names)
% Find contrast indices in SPM.xCon by exact name match.

SP = load(spm_mat_path);
SPM = SP.SPM;

allnames = {SPM.xCon.name};
Ic = nan(1, numel(contrast_names));

for ii = 1:numel(contrast_names)
    Ic(ii) = find(strcmp(allnames, contrast_names{ii}), 1, 'first');
end

assert(all(~isnan(Ic)), 'Could not find all requested contrasts by name.');
end

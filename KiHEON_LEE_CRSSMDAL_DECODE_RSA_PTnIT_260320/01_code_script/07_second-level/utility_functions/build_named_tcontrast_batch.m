%% Utility function
% ===================================================================
% Author of this script:
%   Ki Heon Lee
% Contact:
%   kiheon97@gmail.com
% ===================================================================

function matlabbatch = build_named_tcontrast_batch(spm_mat_path, contrast_names, contrast_vectors)
% Build a t-contrast batch from names and vectors.

assert(numel(contrast_names) == numel(contrast_vectors), ...
    'contrast_names and contrast_vectors must have the same length.');

matlabbatch = [];
matlabbatch{1}.spm.stats.con.spmmat = {spm_mat_path};
matlabbatch{1}.spm.stats.con.delete = 0;

for ii = 1:numel(contrast_names)
    matlabbatch{1}.spm.stats.con.consess{ii}.tcon.name    = contrast_names{ii};
    matlabbatch{1}.spm.stats.con.consess{ii}.tcon.convec  = contrast_vectors{ii};
    matlabbatch{1}.spm.stats.con.consess{ii}.tcon.sessrep = 'none';
end
end

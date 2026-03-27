%% Utility function
% ===================================================================
% Author of this script:
%   Ki Heon Lee
% Contact:
%   kiheon97@gmail.com
% ===================================================================

function matlabbatch = build_classical_estimation_batch(spm_mat_path)
% Build the classical estimation batch for an existing second-level design.

matlabbatch = [];
matlabbatch{1}.spm.stats.fmri_est.spmmat = {spm_mat_path};
matlabbatch{1}.spm.stats.fmri_est.write_residuals = 0;
matlabbatch{1}.spm.stats.fmri_est.method.Classical = 1;
end

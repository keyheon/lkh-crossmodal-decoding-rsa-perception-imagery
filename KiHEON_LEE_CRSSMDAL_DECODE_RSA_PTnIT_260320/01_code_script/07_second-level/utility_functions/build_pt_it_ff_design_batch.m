%% Utility function
% ===================================================================
% Author of this script:
%   Ki Heon Lee
% Contact:
%   kiheon97@gmail.com
% ===================================================================

function matlabbatch = build_pt_it_ff_design_batch(outDir, root_first, subj_vec, pt_subdir, it_subdir, pt_con, it_con)
% Build the flexible-factorial design batch for PT and IT emotional_face contrasts.

matlabbatch = [];

matlabbatch{1}.spm.stats.factorial_design.dir = {outDir};

% Factor 1: Subject
matlabbatch{1}.spm.stats.factorial_design.des.fblock.fac(1).name     = 'Subject';
matlabbatch{1}.spm.stats.factorial_design.des.fblock.fac(1).dept     = 0;
matlabbatch{1}.spm.stats.factorial_design.des.fblock.fac(1).variance = 0;
matlabbatch{1}.spm.stats.factorial_design.des.fblock.fac(1).gmsca    = 0;
matlabbatch{1}.spm.stats.factorial_design.des.fblock.fac(1).ancova   = 0;

% Factor 2: Task (PT vs IT)
matlabbatch{1}.spm.stats.factorial_design.des.fblock.fac(2).name     = 'Task';
matlabbatch{1}.spm.stats.factorial_design.des.fblock.fac(2).dept     = 1;
matlabbatch{1}.spm.stats.factorial_design.des.fblock.fac(2).variance = 0;
matlabbatch{1}.spm.stats.factorial_design.des.fblock.fac(2).gmsca    = 0;
matlabbatch{1}.spm.stats.factorial_design.des.fblock.fac(2).ancova   = 0;

% Include the Task main effect
matlabbatch{1}.spm.stats.factorial_design.des.fblock.maininters{1}.fmain.fnum = 2;

% Subject × Task cells
for ii = 1:numel(subj_vec)
    sID = sprintf('P%03d', subj_vec(ii));
    PT  = fullfile(root_first, sID, pt_subdir, sprintf('con_%04d.nii,1', pt_con));
    IT  = fullfile(root_first, sID, it_subdir, sprintf('con_%04d.nii,1', it_con));

    matlabbatch{1}.spm.stats.factorial_design.des.fblock.fsuball.fsubject(ii).scans = {PT; IT};
    matlabbatch{1}.spm.stats.factorial_design.des.fblock.fsuball.fsubject(ii).conds = [1 2];
end

% Common options
matlabbatch{1}.spm.stats.factorial_design.masking.tm.tm_none = 1;
matlabbatch{1}.spm.stats.factorial_design.masking.im = 1;
matlabbatch{1}.spm.stats.factorial_design.masking.em = {''};
matlabbatch{1}.spm.stats.factorial_design.globalc.g_omit = 1;
matlabbatch{1}.spm.stats.factorial_design.globalm.gmsca.gmsca_no = 1;
matlabbatch{1}.spm.stats.factorial_design.globalm.glonorm = 1;
end

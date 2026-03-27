%% Utility function
% ===================================================================
% Author of this script:
%   Ki Heon Lee
% Contact:
%   kiheon97@gmail.com
% ===================================================================

function [SPM, xSPM, TabDat, outimg] = run_conjunction_null_and_save(outDir, Ic, u, k, thresDesc, outimg_name)
% Run conjunction-null inference in SPM and save the filtered map.

SP = load(fullfile(outDir, 'SPM.mat'));
SPM = SP.SPM;

xSPM = struct();
xSPM.swd       = outDir;
xSPM.Ic        = Ic;
xSPM.n         = 1;          % conjunction-null
xSPM.u         = u;
xSPM.k         = k;
xSPM.thresDesc = thresDesc;

[SPM, xSPM] = spm_getSPM(xSPM);
TabDat      = spm_list('Table', xSPM);

outimg = fullfile(outDir, outimg_name);
descrip = sprintf('Conjunction-null PT&IT emotional_face: %s=%.3f, k=%d', xSPM.thresDesc, xSPM.u, xSPM.k);

spm_write_filtered(xSPM.Z, xSPM.XYZ, xSPM.DIM, xSPM.M, descrip, outimg);
fprintf('Conjunction map written: %s\n', outimg);
end

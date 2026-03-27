%% Utility function
% ===================================================================
% Author of this script:
%   Ki Heon Lee
% Contact:
%   kiheon97@gmail.com
% ===================================================================

function [c_pt, c_it] = get_task_main_effect_contrasts(SPM)
% Create one-hot t-contrast vectors for the two Task main-effect columns.

Hcols = SPM.xX.iH(:)';
assert(numel(Hcols) >= 2, 'Task main effect columns not found. Check maininters.');

pt_col = Hcols(1);
it_col = Hcols(2);

c_pt = zeros(1, size(SPM.xX.X, 2));
c_it = zeros(1, size(SPM.xX.X, 2));

c_pt(pt_col) = 1;
c_it(it_col) = 1;
end

%% Utility function
% ===================================================================
% Author of this script:
%   Ki Heon Lee
% Contact:
%   kiheon97@gmail.com
% ===================================================================
function rsm_avg = average_pt_rsms(rsm_pt1, rsm_pt2)
    % Compute the cell-wise Fisher z average of the PT session 1 and PT
    % session 2 RSMs. Then, inverse transforming the averaged values.
    % The diagonal is restored to 1 after averaging.

    n_items = size(rsm_pt1, 1);
    diag_idx = 1:n_items+1:(n_items * n_items);

    r1 = rsm_pt1;
    r2 = rsm_pt2;
    r1(diag_idx) = NaN;
    r2(diag_idx) = NaN;

    eps_clip = 1e-7;
    r1 = max(min(r1, 1 - eps_clip), -1 + eps_clip);
    r2 = max(min(r2, 1 - eps_clip), -1 + eps_clip);

    rsm_avg = tanh((atanh(r1) + atanh(r2)) / 2);
    rsm_avg(diag_idx) = 1;
end

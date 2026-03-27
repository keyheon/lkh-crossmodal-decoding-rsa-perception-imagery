%% Utility function
% ===================================================================
% Author of this script:
%   Ki Heon Lee
% Contact:
%   kiheon97@gmail.com
% ===================================================================
function Xmask = local_build_union_finite_mask(F)
    if ischar(F)
        F = {F};
    end
    Xmask = [];
    for k = 1:numel(F)
        Vk = spm_vol(F{k});
        X = spm_read_vols(Vk);
        M = isfinite(X);
        if isempty(Xmask)
            Xmask = M;
        elseif isequal(size(Xmask), size(M))
            Xmask = Xmask | M;
        end
    end
end
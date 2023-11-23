%%%  This file takes parameters from an AR(n) process and converts them
%%%  into AR(n) parameters of lower frequency process.

function rhoa = averaging_multirho(rho, N, its)
if ~isrow(rho)
    rho = rho';
end
n_lag = numel(rho);
% rho1=rho(1);
% rho2=rho(2);
%N=3;
%its=20000;

MM = [rho; eye(n_lag - 1, n_lag)];
if max(abs(eig(MM))) > 1
    flag0 = 0;
    while flag0 == 0
        rho = rho * .995;
        MMA = [rho; eye(n_lag - 1, n_lag)];
        if max(abs(eig(MMA))) < 1
            flag0 = 1;
        end
    end
end

% if rho1+rho2>1
%     tempV=rho1+rho2;
%     rho1=rho1/(tempV+0.001);
%     rho2=rho2/(tempV+0.001);
% end

eps = .0001 * randn(N * its, 1);
x = zeros(N * its, 1);
for j = 1:(N * its)
    if j <= n_lag
        x(j) = 0;
    else
        x(j) = rho * x((j - n_lag):(j - 1)) + eps(j);
    end
end

y = mean(reshape(x, [], its));

% beta=pinv(X'*X)*(X'*Y);

if sum(rho) < 1
    Y = y((n_lag + 1):its)';
    X = [ones(its, 1) lagmatrix(y', (1 - n_lag):0)];
    X = X(1:(end - n_lag), :);
    %beta = (X' * X) \ (X' * Y);
else
    disp('XXX')
    Y = y((n_lag + 2):its)' - y((n_lag + 1):(its - 1))';
    X = [ones(its - (n_lag + 1), 1) lagmatrix(Y, (-n_lag):(-1))];
end

beta = X \ Y;
rhoa = beta(1 + (1:n_lag));

end
%%%  This file takes parameters from an AR(2) process and converts them
%%%  into AR(2) parameters of lower frequency process.

function rhoa = averaging(rho,N,its);
%N=3;
%its=20000;

MM=rho;
if max(abs(eig(MM)))>1
    flag0=0;
    while flag0==0
        rho=rho*0.995;
        MMA=rho;
        if max(abs(eig(MMA)))<1
            flag0=1;
        end
    end
end

% if rho1+rho2>1
%     tempV=rho1+rho2;
%     rho1=rho1/(tempV+0.001);
%     rho2=rho2/(tempV+0.001);
% end

x=zeros(N*its,1);
eps=.0001*randn(N*its,1);
x(1)=0;
for j=2:N*its
    x(j)=rho*x(j-1)+eps(j);
end

y=zeros(1,its);
for j=1:its
    n=0;    y(j)=0;
    while n<N
        y(j)=y(j)+1/N*x(j*N-n);
        n=n+1;
    end
end

% beta=pinv(X'*X)*(X'*Y);

if rho<1
    Y=y(2:its)'; X=[ones(its-1,1) y(1:its-1)'];
    beta=inv(X'*X)*(X'*Y);
else
    disp('XXX')
    Y=y(3:its)'-y(2:its-1)';
    X=[ones(its-2,1) y(2:its-1)'-y(1:its-2)'];
end


beta=X\Y;
rhoa=beta(2);

return

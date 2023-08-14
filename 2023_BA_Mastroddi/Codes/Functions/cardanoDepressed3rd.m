function [solution] = cardanoDepressed3rd(p, q)
% Solves depressed third order polynomial equations:
% t^3 + p*t + q = 0
% Outputs only real roots
% from https://en.wikipedia.org/wiki/Cubic_equation

delta = q^2 / 4 + p^3 / 27;

if delta == 0
    disp('Not a third order polynomial');

elseif delta > 0
    u1 = -q/2 + sqrt(delta);
    u2 = -q/2 - sqrt(delta);
    solution = nthroot(u1, 3) + nthroot(u2, 3); %1 real root

else
    solution = roots([1 0 p q]); %3 real roots

end % if

end
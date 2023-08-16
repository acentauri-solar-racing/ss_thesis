x = linspace(-5000,5000,100);
a = 0.97;
b = 30;
k = 0.1;
y = x * a - b;
z = x / a -  b;
figure
plot(x,y)
legend('>P0')
hold on
plot(x,z)
legend('<P0')
hold on
%%
% Define constants a, b, and k (you can adjust k to control the smoothness)


% Generate an array of x values (for example, from -10 to 10)

% Calculate the smooth approximation using the smooth_approximation function
y_smooth = smooth_approximation(x, a, b, k);

% Plot the result
plot(x, y_smooth);
legend('part1','part2','smooth')


function result = smooth_approximation(x, a, b, k)
    % Sigmoid approximation for the transition step
    sigmoid = 1 ./ (1 + exp(-k * (x - b)));
    
    % Approximation for y = x * a - b if x >= b
    part1 = x .* a - b;
    
    % Approximation for y = x / a - b if x < b
    part2 = x ./ a - b;
    
    % Smoothly interpolate between the two parts using the sigmoid
    result = sigmoid .* part1 + (1 - sigmoid) .* part2;
end
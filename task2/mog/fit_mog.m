% Description: Fitting mixture of Gaussians.
% Input: X       - each row is one datapoint.
%        K       - number of Gaussians in the mixture.
%        precision - the algorithm stops when the difference between
%                    the previous and the new likelihood is < precision.
%                    Typically this is a small number like 0.01.
% Output:
%        lambda  - lambda(k) is the weight for the k-th Gaussian.
%        mu      - mu(k,:) is the mean for the k-th Gaussian.
%        sig     - sig{k} is the covariance matriX for the k-th Gaussian.
function [lambda, mu, sig, r] = fit_mog (X, K, precision, useKmeans)
test = 0;
% This avoids positive definite errors
extra_variance = 0.05;

%% Initialization
% Initialize all values in lambda to 1/K.
lambda = repmat (1/K, K, 1);

I = size (X, 1);

if useKmeans
    % Initialize the values of mu using the kmeans result
    [mu, assignm] = kmeans(X,K);
    iterations = 1;
    while length(unique(assignm)) < K
        fprintf('kmeans %d iteration\n', iterations);
        [mu, assignm] = kmeans(X,K);
        iterations = iterations + 1;
    end;
else
    % Initialize mu randomly
    K_random_unique_integers = randperm(I);
    K_random_unique_integers = K_random_unique_integers(1:K);
    mu = X (K_random_unique_integers,:);
end


% Initialize the variances in sig to the variance of the dataset.
sig = cell (1, K);
dimensionality = size (X, 2);
dataset_mean = sum(X,1) ./ I;
dataset_variance = zeros (dimensionality, dimensionality);
for i = 1 : I
    mat = X (i,:) - dataset_mean;
    mat = mat' * mat;
    dataset_variance = dataset_variance + mat;
end
dataset_variance = dataset_variance ./ I;

% Add extra offset in the diagonal to force the matrix to be positive
% definite
dataset_variance = dataset_variance + extra_variance * eye(dimensionality);
for i = 1 : K
    sig{i} = dataset_variance;
end

iterations = 0;
previous_L = 1000000; % just a random initialization

%% The main loop.
while true
    % Expectation step.
    l = zeros (I,K);
    r = zeros (I,K);
    % Compute the numerator of Bayes' rule.
    for k = 1 : K
        l(:,k) = lambda(k) * mvnpdf (X, mu(k,:), sig{k});
    end
    
    % Compute the responsibilities by normalizing.
    s = sum(l,2);
    for i = 1 : I
        r(i,:) = l(i,:) ./ s(i);
    end
    
    % Maximization step.
    r_summed_rows = sum (r,1);
    r_summed_all = sum(sum(r,1),2);
    for k = 1 : K
        % Update lambda.
        lambda(k) = r_summed_rows(k) / r_summed_all;
        
        % Update mu.
        new_mu = zeros (1,dimensionality);
        for i = 1 : I
            new_mu = new_mu + r(i,k)*X(i,:);
        end
        mu(k,:) = new_mu ./ r_summed_rows(k);
        
        % Update sigma.
        if test
            new_sigma_old = zeros (dimensionality,dimensionality);
            for i = 1 : I
                mat = X(i,:) - mu(k,:);
                mat = r(i,k) * (mat' * mat);
                new_sigma_old = new_sigma_old + mat;
            end
        end
        
        % Vectorized version of new sigma calculation
        x_minus_mu = bsxfun(@minus, X, mu(k,:));
        x_by_r = bsxfun(@times, x_minus_mu', r(:,k)');
        new_sigma = x_by_r * x_minus_mu;
        
        if test
            absTol = 1e-3;   %Tolerance factor
            absError = new_sigma(:)-new_sigma_old(:);
            same = all( (abs(absError) < absTol) );
            assert(same, 'Error on update sigma vectorized');
        end
        % Add extra offset in the diagonal to force the matrix to be positive
        % definite
        sig{k} = new_sigma ./ r_summed_rows(k) + extra_variance * eye(dimensionality);
    end
    
    % Compute the log likelihood L.
    temp = zeros (I,K);
    for k = 1 : K
        temp(:,k) = lambda(k) * mvnpdf (X, mu(k,:), sig{k});
    end
    temp = sum(temp,2);
    temp = log(temp);
    L = sum(temp);
    %disp(L);
    
    iterations = iterations + 1;
    %disp([num2str(iterations) ': ' num2str(L)]);
    if abs(L - previous_L) < precision
        %msg = [num2str(iterations) ' iterations, log-likelihood = ', ...
        %num2str(L)];
        %disp(msg);
        break;
    end
    
    previous_L = L;
end
end
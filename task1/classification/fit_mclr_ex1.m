close all;
clear all;

load('data/MNIST_Data.mat');

num_classes = length(unique(Y));
n_train = 2;
n_test = 2;

% Pick the first n_train samples for training
X_train = X(1:n_train, :);
Y_train = Y(1:n_train);

% And the next n_test samples for testing
X_test = X(n_train + 1:n_train + n_test, :);
Y_test = Y(n_train + 1:n_train + n_test);


% Format the data for fit_blogr
data_n_dims = size(X_train, 2);

X_train_mclr = sparse([ones(1,size(X_train,1)); X_train']);
X_test_mclr = sparse([ones(1,size(X_test,1)); X_test']);
w = Y_train + 1;

do_profile = 0;
do_time = 1;

if do_profile
    profile on;
end

if do_time
    tic;
end

% Fit a multi-class logistic regression model
Predictions = fit_mclr (X_train_mclr, w, X_test_mclr, num_classes);

if do_time
    toc;
end

if do_profile
    profile off;
end

% for i=1:2
%     figure; imshow(reshape(X( i,: ), 28, 28));
% end

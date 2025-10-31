function result = iqxydelay(data, fs, delay)
% Apply a <delay> to an input vector <data> with samplerate <fs>.
% <delay> is given in seconds (does not have to be multiple of the
% sample interval). 
% If data is complex, keeps the imaginary part unchanged.

% determine number of samples
[m,n] = size(data);

% make sure the input data has the right format (row-vector)
data = reshape(data, m, n);

% convert to frequency domain
% fdata = fftshift(fft(dataX))/n;
fdata=fftshift(fft(data,[],2),2)/n;

delay = reshape(delay, length(delay),1);
% create linear phase vector (= delay)
phd = bsxfun(@times,(-n/2:n/2-1)/n*2*pi*fs,delay);

% convert it into frequency domain
fdelay = exp(1j*(-phd));

% apply delay (convolution ~ multiplication)
fresult = fdata .* fdelay;
% ...and convert back into time domain
result = real(ifft(fftshift(fresult,2),[],2))*n;

% get imaginary part from input vector
% if (~isreal(data))
%     result = complex(real(dataX),result);
% end

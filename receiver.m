function [recovered_message] = receiver(input,preamble)
%RECEIVER Simplified wireless receiver signal processor.
%   This function takes an input signal and a known preamble (in complex
%   form) and goes through the process of downconverting, filtering,
%   downsampling, correlating the preamble to the start of the message,
%   symbol extraction, QAM demodulation, and finally conversion to ASCII.
%   Inputs should be string names of the files in the current working
%   directory.
%
%Usage: return_string = receiver('input.txt', 'preamble.txt')

% input to array
raw_input = importdata(input);
% orient the signal to match the rest of the code
raw_input = raw_input';

% since the given preamble is in complex form, we must handle reading in
% its values differently (they're treated as strings, so we need to iterate
% through the whole set and convert as we go)
handle = fopen(preamble);
preamble_arr = zeros(1,50);
i = 1;
while ~feof(handle)
    preamble_arr(i) = str2num(fgets(handle));
    i = i + 1;
end
fclose(handle);

% we must now prepare 2 oscillator signals for the downconversion process,
% sin and cos of the same 20Hz frequency sampled at 100Hz for 3000 samples
% (30 seconds)
t = (0:0.01:29.99);

osc_0 = cos(2*pi*20*t);
osc_1 = sin(2*pi*20*t);

% and downconvert into I and Q
I = raw_input .* osc_0;
Q = raw_input .* osc_1;

% This implementation transforms the signal components I and Q into
% their frequency domain representation, then uses a defined mask to set
% all frequencies outside of the desired range to 0.  The components are
% then transformed back to the time domain.

I_fft = fft(I, 3000);
Q_fft = fft(Q, 3000);

mask = zeros(size(I));
mask(1:153) = 1;
mask(3000-153:end) = 1;

I_fft = I_fft .* mask;
Q_fft = Q_fft .* mask;

f = (0:1:2999);
f = f .* (100/3000);

I_filt = ifft(I_fft, 3000, 'symmetric');
Q_filt = ifft(Q_fft, 3000, 'symmetric');

% Now I and Q are downesampled then combined into the real and imaginary
% parts of the reconstructed signal.
% NOTE: the signal apparently lost power/magnitude after filtering, so a
% factor of 2 brings them back up to scale.

I_reduced = 2 .* downsample(I_filt, 10);
Q_reduced = 2 .* downsample(Q_filt, 10);

reduced = I_reduced + (Q_reduced .* 1i);

% Uncomment to plot the received signal points and constellation markers
%{
figure, scatter(I_reduced(200:end), Q_reduced(200:end), 10, 'black', 'filled');
hold on;

% A matrix of constellation coordinates in order of 0 to 15.  Originally
% intended for use with a shortest-distance algorithm for decoding, but
% after realizing that my signal was losing magnitude (it was only ever
% resolving to the innermost 4 symbols) the qamdemod() function worked
% perfectly.  Now used for visualization.
symbol_points = [3 3; 1 3; -3 3; -1 3; 3 1; 1 1; -3 1; -1 1; 3 -3; 1 -3; -3 -3; -1 -3; 3 -1; 1 -1; -3 -1; -1 -1];

for x = 1:size(symbol_points, 1)
    plot(symbol_points(x, 1), symbol_points(x, 2), 'r*');
end
%}

% Now we run a correlation of the known preamble against the reconstructed
% signal to find the beginning of actual packet information
[~, pos] = max(abs(xcorr(preamble_arr, reduced)));

% Uncomment to see the correlation response
%figure, plot(abs(xcorr(preamble_arr, reduced)));

% With the correct position known we can take the good data and use QAM16
% demodulation with the given constellation to extract symbols, then
% convert them into binary in anticipation of binary to ASCII conversion of 
% the message.
symbols = qamdemod(reduced(pos-45:end), 16, [2 6 14 10 3 7 15 11 1 5 13 9 0 4 12 8]);  
symbols_bin =  de2bi(symbols, 4, 'left-msb');

% Binary to ASCII conversion could probably be done a lot more smoothly
% than this, but I'm just going to iterate with a step of 2 to grab bytes
% and convert them in a massively convoluted set of nested functions.  I'll
% preallocate an array to the length of the output string
characters = char(zeros(floor(size(symbols_bin, 1)/2)));
y = 1;

for z = 1:2:(size(symbols_bin, 1))
    characters(y) = char(bin2dec(num2str(horzcat(symbols_bin(z,:),symbols_bin(z+1,:)))));
    y = y + 1;
end

% And we have to do a little messing around to get it into a coherent
% string
characters = transpose(characters);
recovered_message = characters(1,:);

end


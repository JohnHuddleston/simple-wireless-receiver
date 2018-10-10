# simple-wireless-receiver
A simple MATLAB script that takes premade (real) input and (complex) preamble files to perform downconversion, filtering, downsampling, QAM16 demodulation, and finally symbol extraction and translation.

## Details
Inputs are a received signal sampled at 100Hz for 3000 samples and a 50-symbol long complex preamble for correlation.

**Downconversion:** This entails multitplying the input by two oscillators, a sin and cos of (2\*pi\*20\*t) to return the real and complex components (I and Q) to baseband.

**Filtering:** The I and Q components undergo a low-pass filtering process by Fourier transform, then having a bitmask applied to exclude all frequencies outside of (-5.1 Hz, 5.1 Hz).  An inverse Fourier transform then brings them back into the time domain, though they lose 1/2 of their magnitude and must be amplified.

**Downsampling:** Each component is downsampled to 1/10 of their original size.

**QAM16 Demodulation:** I + Q\*j represents a vector on the imaginary plane.  The shortest distance between the endpoint of this vector and one of the QAM16 constellation points denotes what symbol it will be decoded into.  Here's where the bit error start to become more obvious (especially in the plot).

**ASCII to text:** There MUST be a better way to do this, but I just clunkily iterated through by 2s, putting nibbles together into bytes, converting them to integers, then interpreting them as characters.  After a little more shuffling around the final message comes out.

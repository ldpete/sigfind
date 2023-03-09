# **“sigfind.m”, “sigfind_noisy.m”, “sigfind_outer.m” Documentation**

## **Issue Tracker**

### **NEEDS TO BE DONE:**

-   Rigorously test the threshold values used to exclude background peaks
-   Construct a function that averages the height of the background peaks and integrates over the length of the "signal" region to provide an estimate of the blank
-   Optimize the smoothing span; this may also be best accomplished with machine learning, or potentially Monte Carlo
-   Compile training dataset from online repositories to evaluate the efficacy of the code over a larger range of spectral formsAdd support for other file types

## **README**

### **Installation**

1.  Download the package from the repository
2.  Extract the codes, documentation, and example data to your working directory
    1.  NOTE: codes can be placed in a general formula directory separate from the data, however you will have to call this directory in your code; this also holds for data

### **Purpose of the Code**

The script was developed to automatically interpret FTIR spectra, with a focus on water in nominally anhydrous minerals (NAMs; i.e. olivine and pyroxene). The primary goals of the script are to:

1.  Identify the region of the spectra dominated by the signal of interest (for water in NAMs this is generally \~3800 cm-1 to 3100 cm-1)
    1.  The end points of this are denoted as the upper bound (UB) and lower bound (LB) of the “signal”
2.  Establish a smooth baseline beneath the signal region such that none of the “signal” lies below the baseline

### **Tutorial**

See tutorial files marked “sigfind_tutorial.m”,” sigfind_noisy.m”, and “sigfind_outer.m”.

| **Table 1: Correct Outputs for Tutorial Codes** |                |                    |                    |         |           |                 |              |                    |
|-------------------------------------------------|----------------|--------------------|--------------------|---------|-----------|-----------------|--------------|--------------------|
| *Function*                                      | *Data File*    | *Upper Bound (UB)* | *Lower Bound (LB)* | *Area*  | *Bell_Ol* | *Bell_Ol_error* | *Withers_Ol* | *Withers_Ol_error* |
| sigfind                                         | olivine1.CSV   | 316                | 85                 | 21.9835 | 4.1329    | 0.2638          | 2.616        | 0.1319             |
| sigfind_noisy                                   | olivine4.CSV   | 316                | 90                 | 16.9926 | 3.1946    | 0.2039          | 2.0221       | 0.1020             |
| sigfind_outer                                   | GRR1695.2b.CSV | 714                | 379                | 1.3123  | 0.2467    | 0.0157          | 0.1562       | 0.0079             |

### **Assumptions of the Code**

1.  The “signal” region is continuous (i.e. is simply contained in the range by UB and LB)
    1.  For different spectral regions and targets, like CO2, this assumption may not hold
    2.  For NAM samples this assumption may not hold; determination of satisfaction is left to the user
2.  The overall morphology of the region of interest in the spectra is convex
    1.  Note, background over the entire spectra can be approximated by many different functions (linear, quadratic, high order polynomials, sinusoidal, etc.)
3.  The spectra has a relatively high signal to noise/scattering ratio
    1.  If sigfind.m produces an erroneous result, try sigfind_noisy.m, if that doesn’t work hand-draw the baseline
4.  Scattering/interference only results in positive skewing of the data
5.  If using sigfind.m, background peaks do not exceed 5% of the max peak height
6.  If using sigfind_noisy.m, background peaks in the smoothed spectra do not exceed 15% of the max peak height of the smoothed spectra

### **Inputs**

-   file_name - Raw data file formatted as a “.csv”
-   t_um – thickness of the sample in microns

### **Outputs**

-   signal – matrix containing data over the region of interest; column 1 is wavenumber (cm-1) and column 2 is absorbance
-   background – matrix containing the data outside the region of interest; column 1 is wavenumber (cm-1) and column 2 is absorbance
-   data – matrix containing the raw thickness corrected data; column 1 is wavenumber (cm-1) and column 2 is absorbance
-   LB – lower bound of the “signal”; an index that corresponds to a value in data column 1
-   UB- upper bound of the “signal”; an index that corresponds to a value in data column 1

### **Decision Tree/Procedure for Selecting Processing Code**

1.  All data is initially processed using sigfind.m
2.  Evaluate the baseline (set by user outside of sigfind) for plausibility, if the baseline is plausible, end, if not, proceed to step 3
    1.  How to Determine Plausibility:
        1.  visually identify major peaks
        2.  draw/imagine a smoothed curve through the data that removes minor overlapping peaks and does not distort peak height or width
        3.  UB and LB should be located at the minima to the left and right of the left and right-most major peaks, respectively, be sure to visually adjust for distortion of the minima by curvature
            1.  Distortion by curvature is evident by sharp, nearly horizontal turns in the spectra outside of LB or UB
            2.  Occasionally UB and/or LB will be located far away from the location that should represent the anchor by visual approximation, this suggests you should run a different function
3.  If the sigfind.m baseline is determined to be implausible, run the data using sigfind_noisy
4.  Evaluate if the baseline resulting from sigfind_noisy is plausible, if plausible, end, if not proceed to step 5
5.  Run the data using sigfind_outer
6.  Evaluate if the baseline resulting from sigfind_outer is plausible, if plausible, end, if not proced to step 7
7.  Hand-draw the baseline attempting to follow the principles outlined by the included functions

### **General Procedure of sigfind.m**

1.  Take the convex hull beneath the data
    1.  This is also known as “Rubber-banding” in the context of baselines
    2.  The convex hull fits a piece-wise linear function that encloses the data using as few points as possible (see [here](https://www.researchgate.net/profile/Yuriy_Gnatenko2/post/Can_any_one_suggest_a_good_book_for_understanding_Raman_lasers/attachment/59d6216cc49f478072e987c3/AS%3A271832714809351%401441821377909/download/Raman+Scattering.zip) for more details)
2.  Using the convex hull as a first order approximation of the baseline, find the max peak height relative to the baseline
3.  Filter out all data that is less than 5% of the max peak height relative to the rubber band
4.  *Gently* smooth the raw data using a robust local regression using linear least squares and a 2nd order polynomial ([rloess](https://www.itl.nist.gov/div898/handbook/pmd/section1/pmd144.htm))
    1.  rloess was selected as the smoothing function as it weighs points closer to the point of estimation more, thereby limiting outlier effects from background/scattering and preventing strange artifacts generated from other smoothing functions like Savitzky-Golay
    2.  A span of 25 cm-1 is selected based on the method of [Baek et al. 2009](https://www-sciencedirect-com.proxy-um.researchport.umd.edu/science/article/pii/S016974390900094X) (see Ln, section 3); Note, a general value was selected for simplicity sake and based upon user experience examining target FTIR spectra
5.  Find all local maxima remaining in the data, these are considered “peaks”
6.  Find all minima and inflection points in the smoothed data
    1.  The smoothed data is used here to prevent false positives from small shoulder/overlapping peaks present on major peaks
7.  Find the left-most and right-most peaks in the spectra denote these as Ml and Mr, respectively
8.  Find the closest minima to the left of Ml and right of Mr, if no minima is present, select an inflection point; denote these as LB and UB, respectively
9.  Adjust LB and UB to the nearest anchor points of the convex hull of the raw data
    1.  Note, this should not be a drastic adjustment as the convex hull anchor points tend toward minima and inflection points in the spectra
10. Save the region between LB and UB in a matrix denoted as “signal”
11. Save all data outside LB and UB in a matrix denoted as “background”
12. Add any anchor points of the convex hull between LB and UB to the “background” matrix
    1.  These points are assumed to be estimates of where the signal meets the baseline

### **General Procedure of sigfind_noisy.m**

*A major issue with noisy data is that it can obscure peaks, cloud the “bounds” of the signal, and add extra background peaks which may throw off sigfind*

1.  Smooth the raw data following the same procedure as sigfind
2.  Find the convex hull under the *smoothed* data
    1.  The smoothed data is used in this step as the smoothed data tends to move up from the lowest values of the raw data in the noisy regions; however, the smoothed data still preserves approximate peak height and shape and preserves peaks hidden in the background/scattering
3.  Find the max height of the smoothed data relative to the convex hull of the smoothed data
4.  Find the max peak height of the smoothed data relative to the convex hull of the smoothed data
5.  Filter out all smoothed data that is less than 15% of the max peak height relative to the convex hull of the smoothed data
    1.  The 15% threshold is somewhat arbitrary and based on user experience; it should be more rigorously tuned
6.  Find the left-most (Ml) and right-most peaks (Mr)
7.  Find all minima and inflection points of the smoothed data
8.  Find the closest minima to the left of Ml and right of Mr, if no minima are present, select an inflection point; denote these as LB and UB, respectively
9.  Take the convexhull beneath the raw data
10. Adjust LB and UB to the nearest anchor point of the raw data
11. Create a matrix of the raw data between LB and UB, denote this as “signal”
12. Create a matrix of the raw data outside of LB and UB, denote this as “background”
13. Add any anchor points of the convex hull of the raw data between LB and UB to the “background” matrix

### **General Procedure of sigfind_outer.m**

*An issue encountered by sigfind and sigfind_noisy is presented by highly asymmetric overlapping/ major peaks where resulting in a single anchor point of the convex hull being closest to both LB and UB*

1.  Smooth the raw data following the same procedure as sigfind
2.  Find the convex hull under the *smoothed* data
    1.  The smoothed data is used in this step as the smoothed data tends to move up from the lowest values of the raw data in the noisy regions; however, the smoothed data still preserves approximate peak height and shape and preserves peaks hidden in the background/scattering
3.  Find the max height of the smoothed data relative to the convex hull of the smoothed data
4.  Find the max peak height of the smoothed data relative to the convex hull of the smoothed data
5.  Filter out all smoothed data that is less than 15% of the max peak height relative to the convex hull of the smoothed data
    1.  The 15% threshold is somewhat arbitrary and based on user experience; it should be more rigorously tuned
6.  Find the left-most (Ml) and right-most peaks (Mr)
7.  Find all minima and inflection points of the smoothed data
8.  Find the closest minima to the left of Ml and right of Mr, if no minima are present, select an inflection point; denote these as LB and UB, respectively
9.  Take the convexhull beneath the raw data
10. Adjust LB and UB to the nearest anchor point to the nearest anchor points to the left and right of LB and UB, respectively
11. Create a matrix of the raw data between LB and UB, denote this as “signal”
12. Create a matrix of the raw data outside of LB and UB, denote this as “background”
13. Add any anchor points of the convex hull of the raw data between LB and UB to the “background” matrix

### **Notes for Generalization/Use of other Baseline Estimations**

-   To implement another baseline fit over the “signal” region, simply create your fit (piece-wise linear, cubic spline, quadratic, higher order polynomial, etc.) using the LB, UB, and any anchor points of the convex hull between LB and UB
    -   Note, if the fit is discordant, try forcing the fit through LB, UB, and the anchor points while also including the other data present in the “background” matrix

### **References**

Bell, D.R., Ihinger, P.D., and Rossman, G.R., 1995, Quantitative analysis of trace OH in garnet and pyroxenes: American Mineralogist, v. 80, p. 465–474, doi:10.2138/am-1995-5-607.

Bell, D.R., Rossman, G.R., Maldener, J., Endisch, D., and Rauch, F., 2003, Hydroxide in olivine: A quantitative determination of the absolute amount and calibration of the IR spectrum: Journal of Geophysical Research: Solid Earth, v. 108, doi:10.1029/2001JB000679.

Withers, A.C., Bureau, H., Raepsaet, C., and Hirschmann, M.M., 2012, Calibration of infrared spectroscopy by elastic recoil detection analysis of H in synthetic olivine: Chemical Geology, v. 334, p. 92–98, doi:10.1016/j.chemgeo.2012.10.002.

### **Changelog**

-   v1.2
    -   changed the “length” function to “size” along the first dimension of the array/matrix to remove errors caused by 1x2 matrices
-   v1.1
    -   changed selection of minima or inflection points for LB and UB to isempty and isnan logical statements instead of a2\~[ ]
-   v1.0 created 05/05/2020 by Liam Peterson


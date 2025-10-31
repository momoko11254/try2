/*=================================================================
 *
 * kmeans_mex.cpp
 *
 * The calling syntax is:
 *
 * [rX, rY] = kmeans_mex(EtX, EtY, meansX, meansY, iterations, threads)
 *
 *
 * This is a MEX-file for MATLAB.
 *
 * v. 0.9
 *
 * N.B.
 * a) Operates on the input means (allows those to be reused).
 * b) Complex numbers are interfaced directly from Matlab's memory
 * [This works by interleaving the real and imaginary arrays in Matlab (as a double
 *  length real array) before passing to C++, then casting the real array as a complex
 *  array.  This is because Matlab stores complex numbers in a ridiculous way.]
 * c) Option for dual thread computation of for each polarization.
 *
 * Known bugs: no input/output verification
 *=================================================================*/
/* $Revision: 0.9 $ */
#if defined(_MSC_VER)
    #if _MSC_VER < 1800
        #error This project needs at least Visual Studio 2013
    #endif
#elif defined(GCC_VERSION)
    #if GCC_VERSION < 40200
        #error This project needs at least GCC 4.2 (tested with 4.7)
    #endif
#endif

#include <complex>
#include "mex.h"
#include <thread> // c++0x threads

using namespace std;

/* Input Arguments */
#define	ETX_IN		prhs[0]
#define	ETY_IN		prhs[1]
#define	MEANSX_IN	prhs[2]
#define	MEANSY_IN	prhs[3]
#define	ITER_IN	    prhs[4]
#define	THREADS_IN	prhs[5]

/* Output Arguments */
#define	RX_OUT       plhs[0]
#define	RY_OUT       plhs[1]

typedef complex<double> cmp;

/* use the following definitions for input verification
 * #if !defined(MAX)
 * #define	MAX(A, B)	((A) > (B) ? (A) : (B))
 * #endif
 *
 * #if !defined(MIN)
 * #define	MIN(A, B)	((A) < (B) ? (A) : (B))
 * #endif
 */

/* use the following lines for static input declarations */
//#define PI 3.14159265

void kmeans(cmp *et, cmp *means, int n, int meanslength, bool **rl, int iter){
    cmp temp1, temp2;
    int loc;
    double min;
    
    /* double vectors */
    double *d;
    d = (double*) mxCalloc(meanslength,sizeof(double));
    
    /* compute r matrix */
    for(int i=0;i<iter;i++){
        
        /* initialise r(:,:) to 0 for each iteration */
        for(int xindex = 0; xindex<meanslength; xindex++){
            for(int yindex = 0; yindex<n; yindex++){
                rl[xindex][yindex] = 0;
            }
        }
        
        /* Assign datapoints an expected mean value */
        for(int k=0;k<n;k++){
            for(int c=0;c<meanslength;c++){
                d[c] = abs(et[k]-means[c]);
            }
            
            min = d[0]; loc = 0;
            for(int index=1;index<meanslength;index++){
                if(min>d[index]){
                    min=d[index];
                    loc = index;
                }
            }
            rl[loc][k] = 1;
        }
        
        /* locate new means */
        for(int xindex = 0; xindex<meanslength; xindex++){
            temp1 = cmp(0.0,0.0); temp2 = cmp(0.0,0.0);
            for(int yindex = 0; yindex<n; yindex++){
                // sum(rl[xindex,:].*et[:])
                temp1 += ((double) rl[xindex][yindex])*et[yindex];
                // sum(rl[xindex,:])
                temp2 += rl[xindex][yindex];
            }
            means[xindex] = temp1/temp2;
        }
    }
}

void mexFunction( int nlhs, mxArray *plhs[],
        int nrhs, const mxArray*prhs[] ) {
    
    cmp *etX, *etY, *meansX, *meansY;
    int iter;
    int threads;
    double *rX_out, *rY_out;
    
    bool **rlX, **rlY;

    int m = mxGetM(ETX_IN);
    int n = mxGetN(ETX_IN)/2;                // /2 for interleaved inputs
    
    int meanslength = mxGetN(MEANSX_IN)/2;   // /2 for interleaved inputs
    
    iter = (int) mxGetScalar(ITER_IN);
    
    /* work out how many threads to use (1 if none specified)*/
    (nrhs==6) ? threads = (int) mxGetScalar(THREADS_IN) : threads = 1;
    
    /* Assign pointers in */
    etX = (cmp*) mxGetPr(ETX_IN);
    etY = (cmp*) mxGetPr(ETY_IN);
    
    meansX = (cmp*) mxGetPr(MEANSX_IN);
    meansY = (cmp*) mxGetPr(MEANSY_IN);
    
    /* Assign pointers out */
    RX_OUT = mxCreateDoubleMatrix(1, meanslength*n,  mxREAL);
    RY_OUT = mxCreateDoubleMatrix(1, meanslength*n,  mxREAL);
    rX_out = mxGetPr(RX_OUT);
    rY_out = mxGetPr(RY_OUT);
    
    /* boolean vectors */
    rlX = (bool**) mxCalloc(meanslength,sizeof(bool*));
    rlY = (bool**) mxCalloc(meanslength,sizeof(bool*));
    for (int i = 0; i < meanslength; i++){
        rlX[i] = (bool*) mxCalloc(n,sizeof(bool));
        rlY[i] = (bool*) mxCalloc(n,sizeof(bool));
    }
    
    /* Launch two threads to compute kmeans for both polarizations */
    if (threads>1){
        /* Declare 2 threads */
        thread* t = (thread*) mxCalloc(2,sizeof(thread)); // preallocate memory for

        /* run the CPE in two threads */
        t[0] = thread(kmeans,etX,meansX,n,meanslength,rlX,iter); // x-pol
        t[1] = thread(kmeans,etY,meansY,n,meanslength,rlY,iter); // y-pol
        
        for (int j = 0; j<2; ++j) t[j].join(); // join threads here (it'll crash if you don't)
    }else{
        /* single thread */
        kmeans(etX,meansX,n,meanslength,rlX,iter); // x-pol
        kmeans(etY,meansY,n,meanslength,rlY,iter); // y-pol
    }
    
    /* make output vectors vectors */
    for(int xindex = 0; xindex<meanslength; xindex++){
        for(int yindex = 0; yindex<n; yindex++){
            rX_out[(xindex*n)+yindex] = (double) rlX[xindex][yindex];
            rY_out[(xindex*n)+yindex] = (double) rlY[xindex][yindex];
        }
    }
    
    /* cleanup (none required) */
    /* return control to MATLAB */
    return;
}
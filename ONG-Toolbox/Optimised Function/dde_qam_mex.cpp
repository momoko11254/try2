/*=================================================================
 *
 * Linux: compile with -std=c++0x flag using gcc >4.7
 * Windows: compile using MS Visual Studio > 2013
 * Mac: not yet tested (probably use xcode)
 *
 * dde_qam_mex.cpp
 *
 * Decision directed equalisation algorithm for arbitrary m-qam.
 * (For use with MATLAB wrapper.)
 *
 *
 * The calling syntax is:
 *
 * [ETL,ETR,errorl,errorr] =
 *      dde_qam_mex(ETL,ETR,H11,H12,H21,H22,points,mu,threads);
 *
 * N.B. points are assumed to be the normalised
 *
 * This is a MEX-file for MATLAB.
 *
 * v. 0.9
 *
 * N.B.
 * a) From version 0.2, taps (H11,H12...) are overwritten in Matlab's memory space.
 * b) From version 0.2, complex numbers are interfaced directly from Matlab's memory
 * [This works by interleaving the real and imaginary arrays in Matlab (as a double
 *  length real array) before passing to C++, then casting the real array as a complex
 *  array.  This is because Matlab stores complex numbers in a ridiculous way.]
 * c) From version 0.9, option for dual thread computation of AFIR filter.
 *
 * Known bugs: no input/output verification
 *
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
/* the following lines test for full C++11 compliance, which is unlikely */
// #else __cplusplus <= 199711L
//    #error This project can only be compiled with a compiler that supports C++11 (e.g. Visual Studio 2013 or gcc 4.7)
// #endif

#include <complex>
#include "mex.h"
#include <thread> // c++0x threads

using namespace std;

/* Input Arguments */
#define	ETL_IN		prhs[0]
#define	ETR_IN		prhs[1]
#define	HXX_IN		prhs[2]
#define	HXY_IN		prhs[3]
#define	HYX_IN		prhs[4]
#define	HYY_IN		prhs[5]
#define	POINTS_IN	prhs[6]
#define	MU_IN		prhs[7]
#define	THREADS_IN	prhs[8]

/* Output Arguments */
#define	ETL_OUT		plhs[0]
#define	ETR_OUT		plhs[1]
#define	ERROR1_OUT	plhs[2]
#define	ERROR2_OUT	plhs[3]

//typedef complex<double> cmp;

#define cmp complex<double>

/* use the following definitions for input verification */
#if !defined(MAX)
#define	MAX(A, B)	((A) > (B) ? (A) : (B))
#endif

#if !defined(MIN)
#define	MIN(A, B)	((A) < (B) ? (A) : (B))
#endif

int minLocFunc(double points_in,double points[],int points_length){ // returns index of minimum deviation
    int mLoc = 0; // index of minimum
    double tempdev;
    double dev; // deviation from expected
  
    dev = abs(points_in-points[0]); 
    
    for(int j=1;j<points_length;j++){
        tempdev = abs(points_in-points[j]);
        if(dev>tempdev){
            dev = tempdev;
            mLoc = j;
        }
    }
    return mLoc;
}

/* filter x with h using nf taps starting on point s */
void firfilt(cmp* h, cmp* x, cmp* y, int s, int nf){
    for(int j=0;j<nf;++j){
        y[s] += h[j]*x[j+s-nf+1];
    }
}

/* adaptive filter: bulk of work is done here */
void afir(cmp* h11, cmp* h12, cmp* x1, cmp* x2, int nf,
        cmp* y, cmp* error, double* mu, double points[],
        int points_length, int start, int n) {
    int mLocR, mLocI;
    for(int s=start; s<n-1; s=s+2){
        /* filter x with h using nf taps starting on point s */
        /* symbol */
        firfilt(h11,x1,y,s,nf);
        firfilt(h12,x2,y,s,nf);
        /* transition */
        firfilt(h11,x1,y,s+1,nf); 
        firfilt(h12,x2,y,s+1,nf);
        
        /* compute error term */
        mLocR = minLocFunc(y[s].real(),points,points_length);
        mLocI = minLocFunc(y[s].imag(),points,points_length);
        error[s] = cmp(points[mLocR],points[mLocI])-y[s];
        
        /* filter tap weight updates */
        for(int j=0;j<nf;++j){
            h11[j]+=mu[j]*error[s]*conj(x1[j+s-nf+1]);
            h12[j]+=mu[j]*error[s]*conj(x2[j+s-nf+1]);
        }
    }
}

/* mex entry point */
void mexFunction( int nlhs, mxArray *plhs[],
        int nrhs, const mxArray*prhs[] )
{
    cmp *error1,*error2;
    double *mu;
    double *points;
    int m,n,mf,nf,points_length;
    int threads;
    cmp *etl, *etr, *etl_o, *etr_o, *hxx, *hxy, *hyx, *hyy;
    
    /* get electric field dimensions */
//     m = mxGetM(ETL_IN);
    n = mxGetN(ETL_IN)/2; // /2 for interleaved inputs
    
    /* get filter dimensions */
    mf = mxGetM(HXX_IN);
    nf = mxGetN(HXX_IN)/2; // /2 for interleaved inputs
    
    /* Assign pointers in */
    etl = (cmp*) mxGetPr(ETL_IN);
    etr = (cmp*) mxGetPr(ETR_IN);
    
    hxx  =  (cmp*) mxGetPr(HXX_IN);
    hxy  =  (cmp*) mxGetPr(HXY_IN);
    hyx  =  (cmp*) mxGetPr(HYX_IN);
    hyy  =  (cmp*) mxGetPr(HYY_IN);
    
    mu = mxGetPr(MU_IN);
    points = mxGetPr(POINTS_IN);
    
    /* work out how many threads to use (1 if none specified)*/
    (nrhs==9) ? threads = (int) mxGetScalar(THREADS_IN) : threads = 1;
    
    /* get # points */
    points_length = MAX(mxGetN(POINTS_IN),mxGetM(POINTS_IN));
    
    /* Assign pointers out */
    ETL_OUT = mxCreateDoubleMatrix(1, 2*n, mxREAL); // I don't know why this needs to be 2n long!
    ETR_OUT = mxCreateDoubleMatrix(1, 2*n, mxREAL);
    
    ERROR1_OUT = mxCreateDoubleMatrix(1, 2*n, mxREAL);
    ERROR2_OUT = mxCreateDoubleMatrix(1, 2*n, mxREAL);
    
    /* variable premaths */
    etl_o = (cmp*) mxGetPr(ETL_OUT);
    etr_o = (cmp*) mxGetPr(ETR_OUT);
    
    error1 = (cmp*) mxGetPr(ERROR1_OUT);
    error2 = (cmp*) mxGetPr(ERROR2_OUT);
    
    int start = int(2*ceil(nf/2.0))-1; // first symbol for EQ
    
    /* Godard EQ (AFIR loop at symbol spacing) */
    /* Launch two threads to compute equaliser */
    if (threads>1){
        /* Declare 2 threads */
        thread* t = (thread*) mxCalloc(2,sizeof(thread)); // preallocate memory for
        //     thread t[2]; // don't do this
        
        /* run the equaliser in two threads */
        t[0] = thread(afir,hxx,hxy,etl,etr,nf,etl_o,error1,mu,points,points_length,start,n); // x-pol
        t[1] = thread(afir,hyy,hyx,etr,etl,nf,etr_o,error2,mu,points,points_length,start,n); // y-pol
        
        for (int j = 0; j<2; ++j) t[j].join(); // join threads here (it'll crash if you don't)
    }else{
    	/* single thread */
        afir(hxx,hxy,etl,etr,nf,etl_o,error1,mu,points,points_length,start,n); // x-pol
        afir(hyy,hyx,etr,etl,nf,etr_o,error2,mu,points,points_length,start,n); // y-pol
    }
    
    /* no cleanup required */
    /* return control to MATLAB */
    return;
}

/*=================================================================
 *
 * Linux: compile with -std=c++0x flag using gcc >4.7
 * Windows: compile using MS Visual Studio > 2013
 * Mac: compile with clang++ 
 *
 * dd_qam_cpe_mex.cpp
 *
 * Performs decision directed phase estimation on M-QAM
 *
 * The calling syntax is:
 *
 * [phaseX, phaseY] = cpe_qam_dd_mex(EtX, EtY, Points, FilterHalfWidth)
 *
 * This is a MEX-file for MATLAB.
 *
 * v. 0.9
 * N.B.
 * a) From version 0.9, Operates on both polarizations. Additionl option 
 * for dual thread computation for each polarization.
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
#define	ETX_IN		prhs[0]
#define	ETY_IN		prhs[1]
#define	POINTS_IN  	prhs[2]
#define	FHW_IN  	prhs[3]
#define	THREADS_IN	prhs[4]

/* Output Arguments */
#define	PHASEX_OUT	plhs[0]
#define	PHASEY_OUT	plhs[1]

typedef complex<double> cmp;

/* use the following definitions for input verification */
#if !defined(MAX)
#define	MAX(A, B)	((A) > (B) ? (A) : (B))
#endif

#if !defined(MIN)
#define	MIN(A, B)	((A) < (B) ? (A) : (B))
#endif

/* returns index of minimum deviation */
int minLocFunc(double point_in,double points[],int points_length){ // returns index of minimum deviation
    int mLoc = 0; // index of minimum
    double tempdev;
    double dev; // deviation from expected
    
    dev = abs(point_in-points[0]);
    
    for(int j=1;j<points_length;j++){
        tempdev = abs(point_in-points[j]);
        if(dev>tempdev){
            dev = tempdev;
            mLoc = j;
        }
    }
    return mLoc;
}

void cpe(cmp* et, cmp* CorrWindow, double* realDec, double* imagDec, 
        double* phase, double* points, int FilterHalfWidth, int points_length,
        int start, int end){
    
    cmp temp;
    for(int s=start;s<end;s++){
        temp = cmp(0, 0);
        /* FFE Corrected with previous estimate of Phi */
        for(int i=(s-FilterHalfWidth); i<(s+FilterHalfWidth+1); i++){
            CorrWindow[i-s+FilterHalfWidth] = et[i]*exp(-cmp(0,1)*phase[s-1]);  /* rotate et by estimated phase */
        }
        
        for(int i=0; i<(2*FilterHalfWidth+1); i++){
            /* make decisions on QAM symbols */
            realDec[i] = points[minLocFunc(CorrWindow[i].real(),points,points_length)];
            imagDec[i] = points[minLocFunc(CorrWindow[i].imag(),points,points_length)];
            
            /* Average change in phase on Pol */
            temp += CorrWindow[i]*(realDec[i]-cmp(0,1)*imagDec[i]);
        }
        /* Accumulated Phase */
        phase[s] = phase[s-1]+arg(temp);
    }
}

void mexFunction( int nlhs, mxArray *plhs[],
        int nrhs, const mxArray*prhs[] ) {
    
    double *phaseX, *phaseY;
    double *points;
    int FilterHalfWidth, points_length;
    int threads;
    cmp *etX, *etY;
    cmp *CorrWindowX, *CorrWindowY;
    double *realDecX, *imagDecX, *realDecY, *imagDecY;
    
    int m = mxGetM(ETX_IN);
    int n = mxGetN(ETX_IN)/2;                // /2 for interleaved inputs;
    
    points = (double*) mxGetPr(POINTS_IN);
    FilterHalfWidth = (int) mxGetScalar(FHW_IN);
    points_length = MAX(mxGetN(POINTS_IN),mxGetM(POINTS_IN));
    
    /* Assign pointers in */
    etX = (cmp*) mxGetPr(ETX_IN);
    etY = (cmp*) mxGetPr(ETY_IN);
    
    /* work out how many threads to use (1 if none specified)*/
    (nrhs==5) ? threads = (int) mxGetScalar(THREADS_IN) : threads = 1;
    
    /* Assign pointers out */
    PHASEX_OUT = mxCreateDoubleMatrix(1, n,  mxREAL);
    PHASEY_OUT = mxCreateDoubleMatrix(1, n,  mxREAL);
    phaseX = mxGetPr(PHASEX_OUT);
    phaseY = mxGetPr(PHASEY_OUT);
    
    /* reassign pointers in to complex doubles */
    CorrWindowX = (cmp*) mxCalloc(2*FilterHalfWidth+1,sizeof(cmp));
    CorrWindowY = (cmp*) mxCalloc(2*FilterHalfWidth+1,sizeof(cmp));
    realDecX = (double*) mxCalloc(2*FilterHalfWidth+1,sizeof(double));
    imagDecX = (double*) mxCalloc(2*FilterHalfWidth+1,sizeof(double));
    realDecY = (double*) mxCalloc(2*FilterHalfWidth+1,sizeof(double));
    imagDecY = (double*) mxCalloc(2*FilterHalfWidth+1,sizeof(double));
    
    /* memset works on mac os, but not with gcc 4.4.7*/
    // memset(phaseX, 0.0, n);
    // memset(phaseY, 0.0, n);
    
    /* start and end conditions */
    int end = n-FilterHalfWidth-1;
    int start = FilterHalfWidth;
    
    for(int i=0;i<start;i++){
        phaseX[i] = 0.0;
        phaseY[i] = 0.0;
    }
    
    /* begin cpe */
    if (threads>1){
        /* Declare 2 threads */
        thread* t = (thread*) mxCalloc(2,sizeof(thread)); // preallocate memory for
        
        /* run the CPE in two threads */
        t[0] = thread(cpe,etX,CorrWindowX,realDecX,imagDecX,phaseX,points,FilterHalfWidth,points_length,start,end); // x-pol
        t[1] = thread(cpe,etY,CorrWindowY,realDecY,imagDecY,phaseY,points,FilterHalfWidth,points_length,start,end); // y-pol
        
        for (int j = 0; j<2; ++j) t[j].join(); // join threads here (it'll crash if you don't)
    }else{
        /* single thread */
        cpe(etX,CorrWindowX,realDecX,imagDecX,phaseX,points,FilterHalfWidth,points_length,start,end); // x-pol
        cpe(etY,CorrWindowY,realDecY,imagDecY,phaseY,points,FilterHalfWidth,points_length,start,end); // y-pol
    }
    
    /* cleanup (none required) */
    /* return control to MATLAB */
    return;
}
/*=================================================================
 *
 * pde_qam_mex.cpp
 *
 * Phase decision equalisation algorithm for arbitrary m-qam.
 * (For use with MATLAB wrapper.)
 *
 *
 * The calling syntax is:
 *
 * [ETL,ETR,errorl,errorr,hxx,hxy,hyx,hyy,phase1,phase2] = 
 *      pde_qam_mex(fout2n1,fout2n2,H11,H12,H21,H22,points,cpewindow,mu);
 *
 * N.B. points are assumed to be the normalised
 *
 * This is a MEX-file for MATLAB.
 *
 * v. 0.1
 *
 * Known bugs: Memory handling untested; no input/output verification
 *
 *=================================================================*/
/* $Revision: 0.1 $ */
#include <complex>
#include "mex.h"

using namespace std;

/* Input Arguments */
#define	ETL_IN		prhs[0]
#define	ETR_IN		prhs[1]
#define	HXX_IN		prhs[2]
#define	HXY_IN		prhs[3]
#define	HYX_IN		prhs[4]
#define	HYY_IN		prhs[5]
#define	POINTS_IN	prhs[6]
#define	CPE_IN		prhs[7]
#define	MU_IN		prhs[8]

/* Output Arguments */
#define	ETL_OUT		plhs[0]
#define	ETR_OUT		plhs[1]
#define	ERROR1_OUT	plhs[2]
#define	ERROR2_OUT	plhs[3]
#define	HXX_OUT		plhs[4]
#define	HXY_OUT		plhs[5]
#define	HYX_OUT		plhs[6]
#define	HYY_OUT		plhs[7]
#define	PHASE1_OUT	plhs[8]
#define	PHASE2_OUT	plhs[9]

//typedef complex<double> cmp;
#define cmp complex<double>

/* use the following definitions for input verification */
#if !defined(MAX)
#define	MAX(A, B)	((A) > (B) ? (A) : (B))
#endif

#if !defined(MIN)
#define	MIN(A, B)	((A) < (B) ? (A) : (B))
#endif

//#define PI 3.14159265

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

void mexFunction( int nlhs, mxArray *plhs[], 
		  int nrhs, const mxArray*prhs[] ) 
{ 
    double *etlr,*etli,*etrr,*etri;
    double *hxxr,*hxyr,*hyxr,*hyyr,*hxxi,*hxyi,*hyxi,*hyyi;
    double *hxxr_o,*hxyr_o,*hyxr_o,*hyyr_o,*hxxi_o,*hxyi_o,*hyxi_o,*hyyi_o;
    double *etlr_o,*etli_o,*etrr_o,*etri_o;
    double *error1r,*error1i,*error2r,*error2i;
    double *mu;
    double *points;
    double *phase1, *phase2;
    int n,nf,points_length,cpewindow;
    cmp *etl, *etr, *etl_o, *etr_o, *hxx, *hxy, *hyx, *hyy, *error1, *error2;
    
    /* get electric field dimensions */
    n = MAX(mxGetN(ETL_IN),mxGetM(ETL_IN));
    
    /* get filter dimensions */
    nf = MAX(mxGetN(HXX_IN),mxGetM(HXX_IN));

    /* Assign pointers in */ 
    etlr = mxGetPr(ETL_IN);
    etli = mxGetPi(ETL_IN);
    
    etrr = mxGetPr(ETR_IN);
    etri = mxGetPi(ETR_IN);
    
    hxxr = mxGetPr(HXX_IN);
    hxyr = mxGetPr(HXY_IN); 
    hyxr = mxGetPr(HYX_IN); 
    hyyr = mxGetPr(HYY_IN);
    
    hxxi = mxGetPi(HXX_IN);
    hxyi = mxGetPi(HXY_IN);
    hyxi = mxGetPi(HYX_IN);
    hyyi = mxGetPi(HYY_IN);
    
    cpewindow = (int) mxGetScalar(CPE_IN);
    mu = mxGetPr(MU_IN);
    points = mxGetPr(POINTS_IN);
   
    /* get # points */
    points_length = MAX(mxGetN(POINTS_IN),mxGetM(POINTS_IN));

    /* reassign pointers in to complex doubles */
    etl = (cmp*) mxCalloc(n,sizeof(cmp));
    etr = (cmp*) mxCalloc(n,sizeof(cmp));
    etl_o = (cmp*) mxCalloc(n,sizeof(cmp));
    etr_o = (cmp*) mxCalloc(n,sizeof(cmp));
    
    error1 = (cmp*) mxCalloc(n,sizeof(cmp));
    error2 = (cmp*) mxCalloc(n,sizeof(cmp));

    for(int i=0;i<n;i++){
        etl[i] = cmp(etlr[i],etli[i]);
        etr[i] = cmp(etrr[i],etri[i]);
        
        etl_o[i] = cmp(0,0);
        etr_o[i] = cmp(0,0);
        
        error1[i] = cmp(0,0);
        error2[i] = cmp(0,0);
    }
    
    /* vars for CPE */
    cmp *CorrWindowl,*DecWindowl,*AvWindowl,*CorrWindowr,*DecWindowr,*AvWindowr;
    double *realDecl, *imagDecl, *RotWindowl, *realDecr, *imagDecr, *RotWindowr;
    
    CorrWindowl = (cmp*) mxCalloc(4*cpewindow,sizeof(cmp));
    CorrWindowr = (cmp*) mxCalloc(4*cpewindow,sizeof(cmp));
    realDecl = (double*) mxCalloc(4*cpewindow,sizeof(double));
    realDecr = (double*) mxCalloc(4*cpewindow,sizeof(double));
    imagDecl = (double*) mxCalloc(4*cpewindow,sizeof(double));
    imagDecr = (double*) mxCalloc(4*cpewindow,sizeof(double));
    RotWindowl = (double*) mxCalloc(4*cpewindow,sizeof(double));
    RotWindowr = (double*) mxCalloc(4*cpewindow,sizeof(double));
    AvWindowl = (cmp*) mxCalloc(4*cpewindow,sizeof(cmp));
    AvWindowr = (cmp*) mxCalloc(4*cpewindow,sizeof(cmp));
    DecWindowl = (cmp*) mxCalloc(4*cpewindow,sizeof(cmp));
    DecWindowr = (cmp*) mxCalloc(4*cpewindow,sizeof(cmp));

    for(int i=0;i<4*cpewindow;i++){
        CorrWindowl[i] = cmp(0,0);
        CorrWindowr[i] = cmp(0,0);
        realDecl[i] = 0.0;
        realDecr[i] = 0.0;
        imagDecl[i] = 0.0;
        imagDecr[i] = 0.0;
        RotWindowl[i] = 0.0;
        RotWindowr[i] = 0.0;
        AvWindowl[i] = cmp(0,0);
        AvWindowr[i] = cmp(0,0);
        DecWindowl[i] = cmp(0,0);
        DecWindowr[i] = cmp(0,0);
    }

    hxx = (cmp*) mxCalloc(nf,sizeof(cmp));
    hxy = (cmp*) mxCalloc(nf,sizeof(cmp));
    hyx = (cmp*) mxCalloc(nf,sizeof(cmp));
    hyy = (cmp*) mxCalloc(nf,sizeof(cmp));    
  
    for(int i=0;i<nf;i++){
        hxx[i] = cmp(hxxr[i],hxxi[i]);
        hxy[i] = cmp(hxyr[i],hxyi[i]);
        hyx[i] = cmp(hyxr[i],hyxi[i]);
        hyy[i] = cmp(hyyr[i],hyyi[i]);
    }

    /* Assign pointers out */ 
    ETL_OUT = mxCreateDoubleMatrix(1, n, mxCOMPLEX);
    ETR_OUT = mxCreateDoubleMatrix(1, n, mxCOMPLEX);
    ERROR1_OUT = mxCreateDoubleMatrix(1, n, mxCOMPLEX);
    ERROR2_OUT = mxCreateDoubleMatrix(1, n, mxCOMPLEX);
    HXX_OUT = mxCreateDoubleMatrix(1, nf, mxCOMPLEX);
    HXY_OUT = mxCreateDoubleMatrix(1, nf, mxCOMPLEX);
    HYX_OUT = mxCreateDoubleMatrix(1, nf, mxCOMPLEX);
    HYY_OUT = mxCreateDoubleMatrix(1, nf, mxCOMPLEX);
    PHASE1_OUT = mxCreateDoubleMatrix(1, n, mxREAL);
    PHASE2_OUT = mxCreateDoubleMatrix(1, n, mxREAL);

    /* variable premaths */
    etlr_o = mxGetPr(ETL_OUT);
    etli_o = mxGetPi(ETL_OUT);
    
    etrr_o = mxGetPr(ETR_OUT);
    etri_o = mxGetPi(ETR_OUT);
    
    error1r = mxGetPr(ERROR1_OUT);
    error1i = mxGetPi(ERROR1_OUT);
    error2r = mxGetPr(ERROR2_OUT);
    error2i = mxGetPi(ERROR2_OUT);
   
    hxxr_o = mxGetPr(HXX_OUT);
    hxxi_o = mxGetPi(HXX_OUT);

    hxyr_o = mxGetPr(HXY_OUT);
    hxyi_o = mxGetPi(HXY_OUT);
    
    hyxr_o = mxGetPr(HYX_OUT);
    hyxi_o = mxGetPi(HYX_OUT);
    
    hyyr_o = mxGetPr(HYY_OUT);
    hyyi_o = mxGetPi(HYY_OUT);
    
    phase1 = mxGetPr(PHASE1_OUT);
    phase2 = mxGetPr(PHASE2_OUT);

    for(int i=0;i<n;i++){
        etlr_o[i] = 0;
        etli_o[i] = 0;

        etrr_o[i] = 0;
        etri_o[i] = 0;
        
        phase1[i] = 0;
        phase2[i] = 0;
        
        error1r[i] = 0.0;
        error1i[i] = 0.0;
        error2r[i] = 0.0;
        error2i[i] = 0.0;
    
    }

    cmp temp1,temp2,temp3,temp4,temp5,temp6,temp7,temp8,templ,tempr;
    double temp_err,errorR,errorI;
    int mLocR,mLocI;
    int start = int(2*ceil(nf/2.0)); // first symbol for EQ
    int end = n-2*cpewindow;
    
    start = (start>2*cpewindow) ? start : 2*cpewindow;
    start = int(2*ceil(start/2.0))-1;

//     mexPrintf("%d\n", start);
    /* Godard EQ (AFIR loop at symbol spacing) */
    for(int s=start; s<end-1; s=s+2){
        
        for(int ss=s; ss<(s+2*cpewindow); ss=ss+2){
            /* calculate AFIR output 1... */
            temp1 = cmp(0,0); temp2 = cmp(0,0); temp3 = cmp(0,0); temp4 = cmp(0,0);
            temp5 = cmp(0,0); temp6 = cmp(0,0); temp7 = cmp(0,0); temp8 = cmp(0,0);
            for(int j=0;j<nf;j++){
            /* ...on symbol */
                    temp1=temp1+hxx[j]*etl[j+ss-nf+1];
                    temp2=temp2+hxy[j]*etr[j+ss-nf+1];
                    temp3=temp3+hyx[j]*etl[j+ss-nf+1];
                    temp4=temp4+hyy[j]*etr[j+ss-nf+1];
            /* ...on transition */
                temp5=temp5+hxx[j]*etl[j+ss-nf+2];
                temp6=temp6+hxy[j]*etr[j+ss-nf+2];
                temp7=temp7+hyx[j]*etl[j+ss-nf+2];
                temp8=temp8+hyy[j]*etr[j+ss-nf+2];
            }
            etl_o[ss] = temp1+temp2;
            etr_o[ss] = temp3+temp4; 
            etl_o[ss+1] = temp5+temp6;
            etr_o[ss+1] = temp7+temp8;
        }
        
        /* Carrier Phase Estimation */
        templ = cmp(0,0); tempr = cmp(0,0);
        /* FFE Corrected with previous estimate of phase */
        for(int i=(s-2*cpewindow); i<(s+2*cpewindow); i=i+2){
            CorrWindowl[i-s+2*cpewindow] = etl_o[i]*exp(-cmp(0,1)*cmp(phase1[s-2],0));
            CorrWindowr[i-s+2*cpewindow] = etr_o[i]*exp(-cmp(0,1)*cmp(phase2[s-2],0));
        }
        for(int i=0; i<(4*cpewindow); i=i+2){
        /* make decisions on symbols */
            realDecl[i] = points[minLocFunc(CorrWindowl[i].real(),points,points_length)];
            imagDecl[i] = points[minLocFunc(CorrWindowl[i].imag(),points,points_length)];

            realDecr[i] = points[minLocFunc(CorrWindowr[i].real(),points,points_length)];
            imagDecr[i] = points[minLocFunc(CorrWindowr[i].imag(),points,points_length)];
            
        /*  */
            AvWindowl[i] = CorrWindowl[i]*(realDecl[i]-cmp(0,1)*imagDecl[i]);
            AvWindowr[i] = CorrWindowr[i]*(realDecr[i]-cmp(0,1)*imagDecr[i]);
            
            templ += AvWindowl[i]; /* Average change in phase on Pol1 */
            tempr += AvWindowr[i]; /* Average change in phase on Pol2 */
        }
        phase1[s] = phase1[s-2]+arg(templ);          /* Accumulated Phase */
        phase2[s] = phase2[s-2]+arg(tempr);          /* Accumulated Phase */
        
        
        etl_o[s] = etl_o[s]*exp(-cmp(0,1)*phase1[s]);
        etr_o[s] = etr_o[s]*exp(-cmp(0,1)*phase2[s]);
        
        /* decision and error on radius */
        mLocR = minLocFunc(etl_o[s].real(),points,points_length);
        mLocI = minLocFunc(etl_o[s].imag(),points,points_length);
//         error1[s] = cmp(points[mLocR],points[mLocI])-etl_o[s];
        error1[s] = exp(cmp(0,1)*phase1[s])*(cmp(points[mLocR],points[mLocI])-etl_o[s]);

        mLocR = minLocFunc(etr_o[s].real(),points,points_length);
        mLocI = minLocFunc(etr_o[s].imag(),points,points_length);
//         error2[s] = cmp(points[mLocR],points[mLocI])-etr_o[s];
        error2[s] = exp(cmp(0,1)*phase2[s])*(cmp(points[mLocR],points[mLocI])-etr_o[s]);
        
        etl_o[s] = etl_o[s]*exp(cmp(0,1)*phase1[s]);
        etr_o[s] = etr_o[s]*exp(cmp(0,1)*phase2[s]);
        
	/* new tap weights */
        for(int j=0;j<nf;j++){
            hxx[j]=hxx[j]+mu[j]*error1[s]*conj(etl[j+s-nf+1]);
            hxy[j]=hxy[j]+mu[j]*error1[s]*conj(etr[j+s-nf+1]);
            hyx[j]=hyx[j]+mu[j]*error2[s]*conj(etl[j+s-nf+1]);
            hyy[j]=hyy[j]+mu[j]*error2[s]*conj(etr[j+s-nf+1]);
        }
    }
    
    /* make lhs vectors */
    for(int i=0;i<n;i++){
            etlr_o[i] = etl_o[i].real();
            etli_o[i] = etl_o[i].imag();
            etrr_o[i] = etr_o[i].real();
            etri_o[i] = etr_o[i].imag();
            
            error1r[i] = error1[i].real();
            error1i[i] = error1[i].imag();
            error2r[i] = error2[i].real();
            error2i[i] = error2[i].imag();
        }
    
     for(int i=0;i<nf;i++){
        hxxr_o[i] = hxx[i].real();
        hxxi_o[i] = hxx[i].imag();

        hxyr_o[i] = hxy[i].real();
        hxyi_o[i] = hxy[i].imag();
        
        hyxr_o[i] = hyx[i].real();
        hyxi_o[i] = hyx[i].imag();
       
        hyyr_o[i] = hyy[i].real();
        hyyi_o[i] = hyy[i].imag();
     }

    /* cleanup */
    /* none! */
    /* return control to MATLAB */
    return;
}

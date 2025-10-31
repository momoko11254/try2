/*=================================================================
 *
 * rde_qam_4x4_mex.cpp
 *
 * 4x4 MIMO implementation of the radially directed equalisation algorithm
 * for arbitrary m-qam. (For use with MATLAB wrapper.)
 *
 *
 * The calling syntax is:
 *
 * [out1,out2,out3,out4,error1,error2] = 
 *      rde_qam_4x4_mex(fout2n1,fout2n2,fout2n3,fout2n4,H11,H12,H13,H14,H21,H22,H23,H24,H31,H32,H33,H34,H41,H42,H43,H44,radii,mu);
 *
 * N.B. radii are assumed to be the normalised
 *
 * This is a MEX-file for MATLAB.
 *
 * v. 0.2
 *
 * N.B. From version 0.2, taps (H11,H12...) are overwritten in Matlab's memory space.
 * Known bugs: no input/output verification
 *
 *=================================================================*/
/* $Revision: 0.2 $ */
#include <complex>
#include "mex.h"

using namespace std;
/* Input Arguments */
#define	ET1R_IN		prhs[0]
#define	ET1I_IN		prhs[1]
#define	ET2R_IN		prhs[2]
#define	ET2I_IN		prhs[3]
#define	H11_IN		prhs[4]
#define	H12_IN		prhs[5]
#define	H13_IN		prhs[6]
#define	H14_IN		prhs[7]
#define	H21_IN		prhs[8]
#define	H22_IN		prhs[9]
#define	H23_IN		prhs[10]
#define	H24_IN		prhs[11]
#define	H31_IN		prhs[12]
#define	H32_IN		prhs[13]
#define	H33_IN		prhs[14]
#define	H34_IN		prhs[15]
#define	H41_IN		prhs[16]
#define	H42_IN		prhs[17]
#define	H43_IN		prhs[18]
#define	H44_IN		prhs[19]
#define	RADII_IN	prhs[20]
#define	MU_IN		prhs[21]

/* Output Arguments */
#define	ET1R_OUT	plhs[0]
#define	ET1I_OUT	plhs[1]
#define	ET2R_OUT	plhs[2]
#define	ET2I_OUT    plhs[3]
#define	ERROR1_OUT	plhs[4]
#define	ERROR2_OUT	plhs[5]

//typedef complex<double> cmp;
// #define cmp complex<double>

/* use the following definitions for input verification */
#if !defined(MAX)
#define	MAX(A, B)	((A) > (B) ? (A) : (B))
#endif

#if !defined(MIN)
#define	MIN(A, B)	((A) < (B) ? (A) : (B))
#endif

//#define PI 3.14159265

int minLocFunc(double point_in,double radii[],int radii_length){ // returns index of minimum deviation
    int mLoc = 0; // index of minimum
    double tempdev;
    double dev; // deviation from expected
  
    dev = abs(point_in-radii[0]); 
    
//     mexPrintf("point_in =  %f dev = %f", point_in, dev);
    for(int j=1;j<radii_length;j++){
        tempdev = abs(point_in-radii[j]);
//         mexPrintf(" tempdev =  %f: ", tempdev);
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
    double *error1,*error2;
    double *et1r, *et1i, *et2r, *et2i,
           *et1r_o, *et1i_o, *et2r_o, *et2i_o;
    double *h11, *h12, *h13, *h14,
           *h21, *h22, *h23, *h24,
           *h31, *h32, *h33, *h34,
           *h41, *h42, *h43, *h44;
    double *radii;
    double *mu;
    int m,n,mf,nf,radii_length;
    
    /* get electric field dimensions */
    m = mxGetM(ET1R_IN);
    n = mxGetN(ET1R_IN);
    
    /* get filter dimensions */
    mf = mxGetM(H11_IN);
    nf = mxGetN(H11_IN);
    
    /* Assign pointers in */ 
    et1r = mxGetPr(ET1R_IN);
    et1i = mxGetPr(ET1I_IN);
    et2r = mxGetPr(ET2R_IN);
    et2i = mxGetPr(ET2I_IN);
    
    h11 = mxGetPr(H11_IN);
    h12 = mxGetPr(H12_IN);
    h13 = mxGetPr(H13_IN);
    h14 = mxGetPr(H14_IN);
    
    h21 = mxGetPr(H21_IN);
    h22 = mxGetPr(H22_IN);
    h23 = mxGetPr(H23_IN);
    h24 = mxGetPr(H24_IN);
    
    h31 = mxGetPr(H31_IN);
    h32 = mxGetPr(H32_IN);
    h33 = mxGetPr(H33_IN);
    h34 = mxGetPr(H34_IN);
    
    h41 = mxGetPr(H41_IN);
    h42 = mxGetPr(H42_IN);
    h43 = mxGetPr(H43_IN);
    h44 = mxGetPr(H44_IN);

    mu = mxGetPr(MU_IN);
    radii = mxGetPr(RADII_IN);
    
    /* get # radii */
    radii_length = MAX(mxGetN(RADII_IN),mxGetM(RADII_IN));
    
    /* Assign pointers out */ 
    ET1R_OUT = mxCreateDoubleMatrix(1, n, mxREAL);
    ET1I_OUT = mxCreateDoubleMatrix(1, n, mxREAL);
    ET2R_OUT = mxCreateDoubleMatrix(1, n, mxREAL);
    ET2I_OUT = mxCreateDoubleMatrix(1, n, mxREAL);
    
    ERROR1_OUT = mxCreateDoubleMatrix(1, n, mxREAL);
    ERROR2_OUT = mxCreateDoubleMatrix(1, n, mxREAL);

    /* variable premaths */
    et1r_o = mxGetPr(ET1R_OUT);
    et1i_o = mxGetPr(ET1I_OUT);
    et2r_o = mxGetPr(ET2R_OUT);
    et2i_o = mxGetPr(ET2I_OUT);
    
    error1 = mxGetPr(ERROR1_OUT);
    error2 = mxGetPr(ERROR2_OUT);
    
    for(int i=0;i<n;i++){
        et1r_o[i] = 0.0;
        et1i_o[i] = 0.0;
        et2r_o[i] = 0.0;
        et2i_o[i] = 0.0;
        
        error1[i] = 0.0;
        error2[i] = 0.0;
    }
    
    double temp1,temp2,temp3,temp4,temp5,temp6,temp7,temp8;
    int start = int(2*ceil(nf/2.0))-1; // first symbol for EQ
    
    /* 4x4 EQ (AFIR loop at symbol spacing) */
    for(int s=start; s<n-1; s=s+2){

	/* calculate AFIR output 1... */
        temp1 = 0.0; temp2 = 0.0; temp3 = 0.0; temp4 = 0.0;
        temp5 = 0.0; temp6 = 0.0; temp7 = 0.0; temp8 = 0.0;
        for(int j=0;j<nf;j++){
		/* ...on symbol */
            temp1=temp1+h11[j]*et1r[j+s-nf+1]+h12[j]*et1i[j+s-nf+1]
                       +h13[j]*et2r[j+s-nf+1]+h14[j]*et2i[j+s-nf+1];
            
            temp2=temp2+h21[j]*et1r[j+s-nf+1]+h22[j]*et1i[j+s-nf+1]
                       +h23[j]*et2r[j+s-nf+1]+h24[j]*et2i[j+s-nf+1];
            
            temp3=temp3+h31[j]*et1r[j+s-nf+1]+h32[j]*et1i[j+s-nf+1]
                       +h33[j]*et2r[j+s-nf+1]+h34[j]*et2i[j+s-nf+1];
            
            temp4=temp4+h41[j]*et1r[j+s-nf+1]+h42[j]*et1i[j+s-nf+1]
                       +h43[j]*et2r[j+s-nf+1]+h44[j]*et2i[j+s-nf+1];
		
       /* ...on transition */
            temp5=temp5+h11[j]*et1r[j+s-nf+2]+h12[j]*et1i[j+s-nf+2]
                       +h13[j]*et2r[j+s-nf+2]+h14[j]*et2i[j+s-nf+2];
            
            temp6=temp6+h21[j]*et1r[j+s-nf+2]+h22[j]*et1i[j+s-nf+2]
                       +h23[j]*et2r[j+s-nf+2]+h24[j]*et2i[j+s-nf+2];
            
            temp7=temp7+h31[j]*et1r[j+s-nf+2]+h32[j]*et1i[j+s-nf+2]
                       +h33[j]*et2r[j+s-nf+2]+h34[j]*et2i[j+s-nf+2];
            
            temp8=temp8+h41[j]*et1r[j+s-nf+2]+h42[j]*et1i[j+s-nf+2]
                       +h43[j]*et2r[j+s-nf+2]+h44[j]*et2i[j+s-nf+2];
        }
        et1r_o[s] = temp1;
        et1i_o[s] = temp2;
        et2r_o[s] = temp3;
        et2i_o[s] = temp4;
 
        et1r_o[s+1] = temp5;
        et1i_o[s+1] = temp6;
        et2r_o[s+1] = temp7;
        et2i_o[s+1] = temp8;
        
        /* absolute values squared */
        temp1 = pow(et1r_o[s],2) + pow(et1i_o[s],2);
        temp2 = pow(et2r_o[s],2) + pow(et2i_o[s],2);
        
        /* decision and error on radius */
        error1[s] = pow(radii[minLocFunc(sqrt(temp1),radii,radii_length)],2)-temp1;
        error2[s] = pow(radii[minLocFunc(sqrt(temp2),radii,radii_length)],2)-temp2;
        
	/* new tap weights */
        for(int j=0;j<nf;j++){
            h11[j]=h11[j]+mu[j]*error1[s]*et1r_o[s]*et1r[j+s-nf+1];
            h12[j]=h12[j]+mu[j]*error1[s]*et1r_o[s]*et1i[j+s-nf+1];
            h13[j]=h13[j]+mu[j]*error1[s]*et1r_o[s]*et2r[j+s-nf+1];
            h14[j]=h14[j]+mu[j]*error1[s]*et1r_o[s]*et2i[j+s-nf+1];
            
            h21[j]=h21[j]+mu[j]*error1[s]*et1i_o[s]*et1r[j+s-nf+1];
            h22[j]=h22[j]+mu[j]*error1[s]*et1i_o[s]*et1i[j+s-nf+1];
            h23[j]=h23[j]+mu[j]*error1[s]*et1i_o[s]*et2r[j+s-nf+1];
            h24[j]=h24[j]+mu[j]*error1[s]*et1i_o[s]*et2i[j+s-nf+1];
            
            h31[j]=h31[j]+mu[j]*error2[s]*et2r_o[s]*et1r[j+s-nf+1];
            h32[j]=h32[j]+mu[j]*error2[s]*et2r_o[s]*et1i[j+s-nf+1];
            h33[j]=h33[j]+mu[j]*error2[s]*et2r_o[s]*et2r[j+s-nf+1];
            h34[j]=h34[j]+mu[j]*error2[s]*et2r_o[s]*et2i[j+s-nf+1];
            
            h41[j]=h41[j]+mu[j]*error2[s]*et2i_o[s]*et1r[j+s-nf+1];
            h42[j]=h42[j]+mu[j]*error2[s]*et2i_o[s]*et1i[j+s-nf+1];
            h43[j]=h43[j]+mu[j]*error2[s]*et2i_o[s]*et2r[j+s-nf+1];
            h44[j]=h44[j]+mu[j]*error2[s]*et2i_o[s]*et2i[j+s-nf+1];            
        }   
    }

    /* no cleanup required */
    /* return control to MATLAB */
    return;
}

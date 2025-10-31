/*=================================================================
 *
 * prbs_mex.cpp
 *
 * The calling syntax is:
 *
 * [pattern] = prbs_mex(Nb, PatternLength, Seed)
 *
 *
 * This is a MEX-file for MATLAB.
 *
 *=================================================================*/
/* $Revision: 0.20 $ */
#include <cmath> /* this is ok because cmath doesn't interface with matlab directly */
#include "mex.h"

using namespace std;

/* Input Arguments */
#define	NB_IN		prhs[0]
#define	PL_IN		prhs[1]
#define	SEED_IN		prhs[2]

/* Output Arguments */
#define	PATTERN_OUT	plhs[0]

/* use the following definitions for input verification
 * #if !defined(MAX)
 * #define	MAX(A, B)	((A) > (B) ? (A) : (B))
 * #endif
 *
 * #if !defined(MIN)
 * #define	MIN(A, B)	((A) < (B) ? (A) : (B))
 * #endif
 */

//#define PI 3.14159265

/* computes positive powers of integers */
long long int myPow(int x, int p)
{
    if (p == 0) return 1;
    if (p == 1) return x;
    
    long long int tmp = myPow(x, p/2);
    if (p%2 == 0) return tmp * tmp;
    else return x * tmp * tmp;
}

/* mex starts here */
void mexFunction( int nlhs, mxArray *plhs[],
        int nrhs, const mxArray*prhs[] )
{
//    double *etlr,*etli,*etrr,*etri;
    int Nb, Pl, Seed;
    unsigned long long ShiftReg, ShiftMask, Mask;
    double *pattern;
    
    Nb = int(*mxGetPr(NB_IN));
    Pl = int(*mxGetPr(PL_IN));
    Seed = int(*mxGetPr(SEED_IN));
    
    /* Assign pointers out */
    PATTERN_OUT = mxCreateDoubleMatrix(1, Nb,  mxREAL);
    pattern = mxGetPr(PATTERN_OUT);
    
    switch ( Pl ) {
        case 1:
        case 2:
        case 3:
        case 4:
        case 6:
        case 7:
        case 15:
            Mask=1;
            break;
        case 5:
            Mask=2;
            break;
        case 8:
            Mask=14;
            break;
        case 9:
            Mask=8;
            break;
        case 10:
            Mask=4;
            break;
        case 11:
            Mask=2;
            break;
        case 12:
            Mask=41;
            break;
        case 13:
            Mask=13;
            break;
        case 14:
            Mask=21;
            break;
        case 16:
            Mask=20488;
            break;
        case 17:
            Mask=8192;
            break;
        case 18:
            Mask=132096;
            break;
        case 19:
            Mask=35;
            break;
        case 20:
            Mask=65536;
            break;
        case 21:
            Mask=262144;
            break;
        case 22:
            Mask=1048576;
            break;
        case 23:
            Mask=131072;
            break;
        case 24:
            Mask=6356992;
            break;
        case 25:
            Mask=2097152;
            break;
        case 26:
            Mask=35;
            break;
        case 27:
            Mask=19;
            break;
        case 28:
            Mask=16777216;
            break;
        case 29:
            Mask=67108864;
            break;
        case 30:
            Mask=41;
            break;
        case 31: /* untested below this point */
            Mask=134217728;
            break;
        case 32:
            Mask=2097155;
            break;
        case 33:
            Mask=524288;
            break;
        case 34:
            Mask=67108867;
            break;
        case 35:
            Mask=4294967296;
            break;
        case 36:
            Mask=16777216;
            break;
        case 37:
            Mask=31;
            break;
        case 38:
            Mask=49;
            break;
        case 39:
            Mask=myPow(2,34);
            break;
        case 40:
            Mask=myPow(2,37)+myPow(2,20)+myPow(2,18);
            break;
        case 41:
            Mask=myPow(2,37);
            break;
        case 42:
            Mask=myPow(2,40)+myPow(2,19)+myPow(2,18);
            break;
        case 43:
            Mask=myPow(2,41)+myPow(2,37)+myPow(2,36);
            break;
        case 44:
            Mask=myPow(2,42)+myPow(2,17)+myPow(2,16);
            break;
        case 45:
            Mask=myPow(2,43)+myPow(2,41)+myPow(2,40);
            break;
        case 46:
            Mask=myPow(2,44)+myPow(2,25)+myPow(2,24);
            break;
        case 47:
            Mask=myPow(2,41);
            break;
        case 48:
            Mask=myPow(2,46)+myPow(2,20)+myPow(2,19);
            break;
        case 49:
            Mask=myPow(2,39);
            break;
        case 50:
            Mask=myPow(2,48)+myPow(2,23)+myPow(2,22);
            break;
        case 51:
            Mask=myPow(2,49)+myPow(2,35)+myPow(2,34);
            break;
        case 52:
            Mask=myPow(2,48);
            break;
        case 53:
            Mask=myPow(2,51)+myPow(2,37)+myPow(2,36);
            break;
        case 54:
            Mask=myPow(2,52)+myPow(2,17)+myPow(2,16);
            break;
        case 55:
            Mask=myPow(2,30);
            break;
        case 56:
            Mask=myPow(2,54)+myPow(2,34)+myPow(2,33);
            break;
        case 57:
            Mask=myPow(2,48)+myPow(2,23)+myPow(2,22);
            break;
        case 58:
            Mask=myPow(2,49);
            break;
        case 59:
            Mask=myPow(2,57)+myPow(2,37)+myPow(2,36);
            break;
        case 60:
            Mask=myPow(2,58);
            break;
        case 61:
            Mask=myPow(2,59)+myPow(2,45)+myPow(2,44);
            break;
        case 62:
            Mask=myPow(2,60)+myPow(2,5)+myPow(2,4);
            break;
        case 63:
            Mask=myPow(2,61);
            break;
        case 64:
            Mask=myPow(2,62)+myPow(2,60)+myPow(2,59);
            break;
//         case 65:
//             Mask=myPow(2,46);
//             break;
//         case 66:
//             Mask=myPow(2,64)+myPow(2,56)+myPow(2,22);
//             break;
//         case 67:
//             Mask=myPow(2,65)+myPow(2,57)+myPow(2,56);
//             break;
//         case 68:
//             Mask=myPow(2,58);
//             break;
//         case 69:
//             Mask=myPow(2,66)+myPow(2,41)+myPow(2,39);
//             break;
//         case 70:
//             Mask=myPow(2,68)+myPow(2,54)+myPow(2,53);
//             break;            
        default :
            Mask=1;
    }
    
    /* rev0.20: these are now long for computing pattern lengths >17 (i.e. >2bytes) */
    ShiftReg = (unsigned long long) Seed;
    ShiftMask= (unsigned long long) pow(2.0,(Pl-1)) + 0.5;
    
    /* DEBUG output */
// mexPrintf("ShiftReg: %f\n", (double) ShiftReg);
    /* end DEBUG */
    
    /* Generate PRBS */
    for(int n=0; n<Nb; n++){
        if(ShiftReg & ShiftMask){
            ShiftReg = (unsigned long long) (((ShiftReg^Mask) << 1) + 1); /* XOR masked bits, logical shift left, put 1 in bit 1 */
            pattern[n]=1;
        }else{
            ShiftReg=ShiftReg << 1;
            pattern[n]=0;
        }
    }
    
    /* make lhs vectors */
    /* for(int i=0;i<Nb;i++){
     * // not required
     * } */
    
    /* cleanup (none required) */
    /* return control to MATLAB */
    return;
}

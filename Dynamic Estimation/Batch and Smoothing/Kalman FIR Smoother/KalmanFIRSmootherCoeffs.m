function [A, B, PkN]=KalmanFIRSmootherCoeffs(H,F,R,Q,kD)
%%KALMANFIRSMOOTHERCOEFFS  Obtain the coefficients for a linear Kalman finite
%                     impulse response (FIR) smoother such that one can
%                     obtain a state and state covariance estimate from a
%                     batch of measurements and a set of control inputs
%                     with no prior information.
%
%INPUTS:    H   The zDim X xDim X N hypermatrix of measurement matrices
%               such that H(:,:,k)*x+w is the measurement at time k, where
%               x is the state and w is zero-mean Gaussian noise with
%               covariance matrix R (:,:,k).
%           F   The xDim X xDim X (N-1) hypermatrix of state transition
%               matrices. The state at discrete-time k is modeled as
%               F(:,:,k) times the state at time k plus zero-mean
%               Gaussian process noise with covariance matrix Q(:,:,k).
%           R   The zDim X zDim X N hypermatrix of measurement covariance
%               matrices.
%           Q   The xDim X xDim X (N-1) hypermatrix of process noise
%               covariance matrices.
%           kD  The discrete time-step at which the smoothed state estimate
%               is desired, where z(:,1) is at discrete time-step 1 (not
%               0).
%
%OUTPUTS:   A   An xDim X zDim X N matrix of coefficients for the
%               measurements.
%           B   An xDim X gDim X (N-1) matrix of coefficients for the 
%               control inputs. The control input at time N only affects
%               the state at time N+1 and thus is not needed.
%           PkN The covariance matrix cooresponding to the smoothed at
%               discrete-time kD that one can obtain using the matrices A
%               and B.
%
%The sum of A(:,:,k)*z(:,k)+B(:,:,k)*u(:,k), where z and u are the
%measurement and control input at time k over all k, provides the estimate.
%The assumed forward-time dynamic equations are
%x(:,k)=F(:,:,k-1)*x(:,k-1)+u(:,k-1)+noise
%z(k)=H(:,:,k)*x(:,k)+noise
%where x is the target state, u is a control input, and z is the
%measurement.
%
%The algorithm is that given in [1]. Note that the orderings of the
%products of the D terms in the code below are very important. This was not
%made clear in the paper. The matrix G in the paper is omitted, since any
%control input can be pre-multipled by the matrix.
%
%Given the coefficients generated by this function, the smoothed state
%estimate xEst at discrete step kD can be computed using 
%xEst=zeros(xDim,1);
%for idx=1:(N-1)
%    xEst=xEst+A(:,:,idx)*z(:,idx)+B(:,:,idx)*u(:,idx);
%end
%xEst=xEst+A(:,:,end)*z(:,end);
%
%REFERENCES:
%[1] D. F. Crouse, P. Willett, and Y. Bar-Shalom, "A low-complexity
%    sliding- window Kalman FIR smoother for discrete-time models," IEEE
%    Signal Processing Letters, vol. 17, no. 2, pp. 177-180, Feb. 2009.
%
%October 2013 David F. Crouse, Naval Research Laboratory, Washington D.C.
%(UNCLASSIFIED) DISTRIBUTION STATEMENT A. Approved for public release.

zDim=size(H,1);
xDim=size(H,2);
N=size(H,3);%The number of steps.

%The forwards filter only runds until step kD, since terms beyind that are
%not needed.
PInv1=zeros(xDim,xDim,kD);
PInvPred1=zeros(xDim,xDim,kD);
D1=zeros(xDim,xDim,kD);

%First, compute The FORWARD-time inverse covariance PInv1, predicted
%inverse covariance PInvPred1 and D1 term in the information filter at all
%of the time-steps using information filter equations.
PInv1(:,:,1)=H(:,:,1)'/R(:,:,1)*H(:,:,1);
for k=2:kD
    DInv1=F(:,:,k-1)'+PInv1(:,:,k-1)/F(:,:,k-1)*Q(:,:,k-1);
    PInvPred1(:,:,k-1)=DInv1\PInv1(:,:,k-1)/F(:,:,k-1);
    PInv1(:,:,k)=PInvPred1(:,:,k-1)+H(:,:,k)'/R(:,:,k)*H(:,:,k);
    D1(:,:,k-1)=inv(DInv1);
end

%Next, compute the REVERSE-time equations for covariance terms
PInvN=zeros(xDim,xDim,N);
PInvPredN=zeros(xDim,xDim,N);
DN=zeros(xDim,xDim,N);

PInvN(:,:,N)=H(:,:,N)'/R(:,:,N)*H(:,:,N);
%The backwards filter only runs back until step kD, since terms beyond that
%are not needed.
for k=(N-1):-1:kD
    DInvN=inv(F(:,:,k))'+PInvN(:,:,k+1)*Q(:,:,k)/(F(:,:,k)');
    PInvPredN(:,:,k+1)=DInvN\PInvN(:,:,k+1)*F(:,:,k);
    PInvN(:,:,k)=PInvPredN(:,:,k+1)+H(:,:,k)'/R(:,:,k)*H(:,:,k);
    DN(:,:,k+1)=inv(DInvN);
end

%Allocate space for the results.
A=zeros(xDim,zDim,N);
B=zeros(xDim,xDim,N-1);

%Compute the A and B coefficients.
%The inverse of the 
if(kD>1)
    PInvkN=PInvPred1(:,:,kD-1)+PInvN(:,:,kD);
else
    PInvkN=PInvN(:,:,kD);
end

PkN=inv(PInvkN);

%The forward coefficients
for j=1:max((kD-1),1)
    %The order of the matrix product over D MUST be backwards as shown.
    DProd=eye(xDim);
    for n=(kD-1):-1:j
        DProd=DProd*D1(:,:,n);
    end
    A(:,:,j)=PInvkN\DProd*H(:,:,j)'/R(:,:,j);
    
    %The B coefficient lacks the first term.
    DProd=eye(xDim);
    for n=(kD-1):-1:(j+1)
        DProd=DProd*D1(:,:,n);
    end
    B(:,:,j)=PInvkN\DProd*PInvPred1(:,:,j);
end

%The backward coefficients
for j=kD:N
    DProd=eye(xDim);
    %The order of the matrix product over DN MUST be forwards, as shown.
    for n=(kD+1):j
        DProd=DProd*DN(:,:,n);
    end
    A(:,:,j)=PInvkN\DProd*H(:,:,j)'/R(:,:,j);
    
    if(j<N)
        DProd=eye(xDim);
        for n=(kD+1):j
            DProd=DProd*DN(:,:,n);
        end
        B(:,:,j)=-PInvkN\DProd*PInvPredN(:,:,j+1)/F(:,:,j);
    end
end
end

%LICENSE:
%
%The source code is in the public domain and not licensed or under
%copyright. The information and software may be used freely by the public.
%As required by 17 U.S.C. 403, third parties producing copyrighted works
%consisting predominantly of the material produced by U.S. government
%agencies must provide notice with such work(s) identifying the U.S.
%Government material incorporated and stating that such material is not
%subject to copyright protection.
%
%Derived works shall not identify themselves in a manner that implies an
%endorsement by or an affiliation with the Naval Research Laboratory.
%
%RECIPIENT BEARS ALL RISK RELATING TO QUALITY AND PERFORMANCE OF THE
%SOFTWARE AND ANY RELATED MATERIALS, AND AGREES TO INDEMNIFY THE NAVAL
%RESEARCH LABORATORY FOR ALL THIRD-PARTY CLAIMS RESULTING FROM THE ACTIONS
%OF RECIPIENT IN THE USE OF THE SOFTWARE.
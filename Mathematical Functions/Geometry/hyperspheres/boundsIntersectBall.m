function val=boundsIntersectBall(point,rSquared,rectMin,rectMax)%BOUNDSINTERSECTBALL Determines whether a (hyper)sphere of a given squared%                    radius centered at the given point intersects a%                    hyperrectangular region.%%INPUTS: point A kX1 dimensional point.%     rSquared A scalar squared distance about the point that describes%              the spherical region that will be tested for intersection%              with the hyperrectangle.%      rectMin A kX1 vector of the lower bounds of each of the dimensions%              of the k-dimensional hyperrectangle.%      rectMax A kX1 vector of the upper bounds of the hyperectangle.%%OUTPUTS: val A boolean value that is true if the ball intersects the%             hyperrectangular region and false otherwise.%%December 2013 David F. Crouse, Naval Research Laboratory, Washington D.C.%(UNCLASSIFIED) DISTRIBUTION STATEMENT A. Approved for public release.numDim=length(point);cumDist=0;for curDim=1:numDim    dist1=(point(curDim)-rectMin(curDim))^2;    dist2=(point(curDim)-rectMax(curDim))^2;    if(dist1<rSquared&&dist2<rSquared)        continue;    end    minDist=min(dist1,dist2);    cumDist=cumDist+minDist;    if(cumDist>rSquared)        val=false;        return    endend    val=true;    returnend%LICENSE:%%The source code is in the public domain and not licensed or under%copyright. The information and software may be used freely by the public.%As required by 17 U.S.C. 403, third parties producing copyrighted works%consisting predominantly of the material produced by U.S. government%agencies must provide notice with such work(s) identifying the U.S.%Government material incorporated and stating that such material is not%subject to copyright protection.%%Derived works shall not identify themselves in a manner that implies an%endorsement by or an affiliation with the Naval Research Laboratory.%%RECIPIENT BEARS ALL RISK RELATING TO QUALITY AND PERFORMANCE OF THE%SOFTWARE AND ANY RELATED MATERIALS, AND AGREES TO INDEMNIFY THE NAVAL%RESEARCH LABORATORY FOR ALL THIRD-PARTY CLAIMS RESULTING FROM THE ACTIONS%OF RECIPIENT IN THE USE OF THE SOFTWARE.
function outmat = eclddist(xmid,ymid,dim_x,dim_y)

A=zeros(x_dim,y_dim);
for i=1:dim_x
    for j=1:dim_y
       A(i,j)=sqrt[(xmid-i)^2+(ymid-j)^2]
    end
end
outmat=A;

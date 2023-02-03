function [A,t]=Positive_Area(Area_Data,time)
A=Area_Data(1);
k=2;
u=A(1);
idx=[];
for i=2:length(Area_Data)
    v=Area_Data(i);
    if u<v
       A(k,1)=v;
       u=v;
       k=k+1;
    else
        idx=[idx;i];
    end
end
time(idx)=[];
t=time;
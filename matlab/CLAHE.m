close all;
%%
fname = 'E:/my_verilog/prev_y.bin';

fd = fopen(fname,'rb');

height = 720;
width = 1280;
img = zeros(height,width);

for i=1:height
    img(i,:) = fread(fd, width, 'uint8');
end

%%
fips=fopen('E:\my_verilog\AXI\CLAHE\CLAHE\CLAHE\CLAHE.bin','r');
% fips=fopen('D:\1_my_verilog\CLAHE\par2\sim\CLAHE.bin','r');
[my_CLAHE,numy]=fscanf(fips,'%02x',[1280 inf]);
% my_CLAHE = my_CLAHE(:,1281:1280*2);
my_CLAHE = my_CLAHE';
my_CLAHE = my_CLAHE(721:1440,1:1280);
figure(1)
imshow(uint8(my_CLAHE))

%%
%matlab计算
% fip=fopen('E:\my_verilog\prev.bin','rb');
% [prev,num]=fread(fip,[720 1280],'uint8');%inf表示读取文件中的所有数据，[M,N]表
prev = img;

clahe_m = adapthisteq(uint8(prev),'NumTiles',[4,4]);
figure(2)
imshow(clahe_m)

 %%
%  block1 = prev((1 - 1)*180 + 1 : 1*180,(1 - 1)*320 + 1: 1*320);
%  k = zeros(1,320);
%  for i = 1:320
%      k(i) = length(find(block1(:,i) == 255));
%  end
%  for i = 1:319
%     k(i+1) = k(i+1) + k(i); 
%  end
%%
%查看灰度直方图
fiph=fopen('E:\my_verilog\AXI\CLAHE\CLAHE\CLAHE\histogram.bin','r');
[my_hist,numh]=fscanf(fiph,'%04x',[256 inf]);
my_hist = [my_hist(256,:);my_hist(1:255,:)];
H = zeros(256,16);
for i =1:4
   for j = 1:4
        num = j + (i - 1)*4;
        hh =  my_hist(:,num);
        block = prev((i - 1)*180 + 1 : i*180,(j - 1)*320 + 1: j*320);
        H(:,num) = imhist(uint8(block),256);
   
        figure('Name',strcat('block',num2str(num)))
        plot(H(:,num));
        hold on
        plot(hh)
   end
end

 sum(my_hist,1)
 df_hist = H-my_hist(:,1:16);
 %%
 %求excess
 H_c = zeros(256,16);
 ex = zeros(1,16);
 for i = 1:16
     if(H(1,i) >= 576)
        ex(i) = H(1,i) - 576;
        H_c(1,i) = 576;
     else
         ex(i) = 0;
         H_c(1,i) = H(1,i);
     end
     
    for j = 2:256
        if(H(j,i) >= 576)
           ex(i) = ex(i) + H(j,i) - 576;
           H_c(j,i) = H_c(j - 1,i) + 576;
        else
            H_c(j,i) = H_c(j - 1,i) + H(j,i);
        end
    end
 end
 ex = ex./255;
 %%
 for i = 1:16
     for j = 1:256
        H_c(j,i) =  round(H_c(j,i) + (j - 1)*ex(i));
     end
 end
 H_c = round(H_c./57600.*255);
 %%
 prev_ed = zeros(720,1280);
 for i = 1:720
    for j = 1:1280
       [w1,w2,w3,w4,block1,block2,block3,block4] = get_weight(i,j);
       prev_ed(i,j) = w1*H_c(img(i,j) + 1, block1) + w2*H_c(img(i,j) + 1, block2) +...
                      w3*H_c(img(i,j) + 1, block3) + w4*H_c(img(i,j) + 1, block4);
    end
 end
 h4 = imhist(uint8(prev_ed),256);
 figure;
 imshow(uint8(prev_ed))
%%
% df = abs(my_CLAHE - double(clahe_m));

% figure();
% x = 1:1:720;
% y = 1:1:1280;
% plot3(df)

%%
% clahe_cv = imread('clhae_cv.tif');
% ficv=fopen('D:\1_my_verilog\CLAHE2\opencv\clahe_cv.bin','rb');
% [clahe_cv,num]=fread(ficv,[720,1280],'uint8');%inf表示读取文件中的所有数据，[M,N]表
% df_cv = abs(double(clahe_cv) - my_CLAHE);
% 
% df_cv_m = abs(double(clahe_cv) - double(clahe_m));
%%
%对比直方图
figure()
h1 = imhist(uint8(prev),256);
h2 = imhist(clahe_m,256);
h3 = imhist(uint8(my_CLAHE),256);

% h5 = imhist(uint8(clahe_cv),256);
% plot(h1);
% hold on
% plot(h2)
% hold on
% plot(h3)

subplot(3,1,1);plot(h2);title('adapthisteq计算结果');
subplot(3,1,2);plot(h4);title('算法MATLAB计算结果');
%subplot(4,1,3);plot(h5);title('opencv结果');
subplot(3,1,3);plot(h3);title('仿真结果');

figure()
subplot(3,1,1);imshow(clahe_m);title('adapthisteq计算结果');
subplot(3,1,2);imshow(uint8(prev_ed));title('算法MATLAB计算结果');
subplot(3,1,3);imshow(uint8(my_CLAHE));title('仿真结果');
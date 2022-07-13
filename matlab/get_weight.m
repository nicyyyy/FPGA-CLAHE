function [w1,w2,w3,w4,block1,block2,block3,block4] = get_weight(height_cnt,width_cnt)
%UNTITLED 此处显示有关此函数的摘要
%   此处显示详细说明
if(height_cnt <= 180)
    block_height = 1;
elseif(height_cnt > 180 && height_cnt <= 360)
    block_height = 2;
elseif(height_cnt > 360 && height_cnt <= 540)
     block_height = 3;
elseif(height_cnt > 540 && height_cnt <= 720)
    block_height = 4;
end

if(width_cnt <= 320)
   block_width = 1;
elseif(width_cnt > 320 && width_cnt <= 640)
    block_width = 2;
elseif(width_cnt > 640 && width_cnt <= 960)
    block_width = 3;
elseif(width_cnt > 960 && width_cnt <= 1280)
    block_width = 4;
end

block = block_width + (block_height - 1)*4;

zone_non = 0000001;
zone_linear_v = 0000010;
zone_linear_h = 0000100;
zone_bilinear_r = 0001000;
zone_bilinear_ru = 0010000;
zone_bilinear_ld = 0100000;
zone_bilinear_l = 1000000;
if(((height_cnt <= 90) && (width_cnt <= 160)) || ...
				((height_cnt > 630) && (width_cnt <= 160)) ||...
				((height_cnt <= 90) && (width_cnt > 1120)) ||...
				((height_cnt > 630) && (width_cnt > 1120)) )
				state = zone_non;
				
elseif(((height_cnt > 90) && (height_cnt <= 630) && (width_cnt <= 160)) || ...
					  ((height_cnt > 90) && (height_cnt <= 630) && (width_cnt > 1120)) )
				state = zone_linear_v;
				
elseif(((height_cnt <= 90) && (width_cnt > 160) && (width_cnt <= 1120)) ||...
					  ((height_cnt > 630) && (width_cnt > 160) && (width_cnt <= 1120)) )
				state = zone_linear_h;
				
elseif(((height_cnt > 90) && (height_cnt <= 540) && (width_cnt > 160) && (width_cnt <= 960)))...
				state = zone_bilinear_r;
				
% elseif((height_cnt > 540) && (height_cnt <= 630) && (width_cnt > 160) && (width_cnt <= 960))
% 				state = zone_bilinear_ru;
elseif((height_cnt > 540) && (height_cnt <= 630) && (width_cnt > 160) && (width_cnt <= 960))
				state = zone_bilinear_r;
elseif((height_cnt > 540) && (height_cnt <= 630) && (width_cnt > 160) && (width_cnt <= 960))
				state = zone_bilinear_ru;				
% elseif((height_cnt > 90) && (height_cnt <= 540) && (width_cnt > 960) && (width_cnt <= 1120))
% 				state = zone_bilinear_ld;
elseif((height_cnt > 90) && (height_cnt <= 540) && (width_cnt > 960) && (width_cnt <= 1120))
				state = zone_bilinear_r;
else
				state = zone_bilinear_l;
end

if(state == zone_non)
    block1 = block;
    block2 = block;
    block3 = block;
    block4 = block;
    
    u1 = 0.5;
    u2 = 0.5;
    v1 = 0.5;
    v2 = 0.5;
elseif(state == zone_linear_v)
    block1 = block;
    block2 = block;
    block3 = block + 4;
    block4 = block + 4;
    if(block3 > 16)
        block3 = block -4;
        block4 = block -4;
    end
    
    if(block3 < 16)
       r1 = abs((block_height + 1)*180 -90 - height_cnt);
       r2 = abs((block_height)*180 -90 - height_cnt);
    else
       r1 = abs((block_height - 1)*180 -90 - height_cnt);
       r2 = abs((block_height)*180 -90 - height_cnt);
    end
    u1 = r1/(r1 + r2);
    u2 = r2/(r1 + r2);
    v1 = 0.5;
    v2 = 0.5;
    
elseif(state == zone_linear_h)
    block1 = block;
    block2 = block;
    block3 = block + 1;
    block4 = block + 1;
    if(block == 4 || block == 16)
        block3 = block -1;
        block4 = block -1;
    end
    
    if(block == 4 || block == 16)
        s1 = abs((block_width - 1)*320 -160 - width_cnt);
        s2 = abs((block_width)*320 -160 - width_cnt);
    else
        s1 = abs((block_width + 1)*320 -160 - width_cnt);
        s2 = abs((block_width)*320 -160 - width_cnt);
    end
    
    v1 = s1/(s1 + s2);
    v2 = s2/(s1 + s2);
    u1 = 0.5;
    u2 = 0.5;
elseif(state == zone_bilinear_r)
    block1 = block;
    block2 = block + 4;
    block3 = block + 1;
    block4 = block + 5;
    
    r1 = abs((block_height + 1)*180 - 90 - height_cnt);
    r2 = abs((block_height)*180 - 90 - height_cnt);
    
    u1 = r1/(r1 + r2);
    u2 = r2/(r1 + r2);
    
    s1 = abs((block_width + 1)*320 -160 - width_cnt);
    s2 = abs((block_width)*320 -160 - width_cnt);
        
    v1 = s1/(s1 + s2);
    v2 = s2/(s1 + s2);
elseif(state == zone_bilinear_ru)
    block1 = block;
    block2 = block - 4;
    block3 = block + 1;
    block4 = block - 3;
    
    r1 = abs((block_height - 1)*180 - 90 - height_cnt);
    r2 = abs((block_height)*180 - 90 - height_cnt);
    
    u1 = r1/(r1 + r2);
    u2 = r2/(r1 + r2);
    
    s1 = abs((block_width + 1)*320 -160 - width_cnt);
    s2 = abs((block_width)*320 -160 - width_cnt);
        
    v1 = s1/(s1 + s2);
    v2 = s2/(s1 + s2);
elseif(state == zone_bilinear_ld)
    block1 = block;
    block2 = block + 4;
    block3 = block - 1;
    block4 = block + 3;
    
    r1 = abs((block_height + 1)*180 - 90 - height_cnt);
    r2 = abs((block_height)*180 - 90 - height_cnt);
    
    u1 = r1/(r1 + r2);
    u2 = r2/(r1 + r2);
    
    s1 = abs((block_width - 1)*320 -160 - width_cnt);
    s2 = abs((block_width)*320 -160 - width_cnt);
    
    v1 = s1/(s1 + s2);
    v2 = s2/(s1 + s2);
elseif(state == zone_bilinear_l)
    block1 = block;
    block2 = block - 4;
    block3 = block - 1;
    block4 = block - 5;
    
    r1 = abs((block_height - 1)*180 - 90 - height_cnt);
    r2 = abs((block_height)*180 - 90 - height_cnt);
    
    u1 = r1/(r1 + r2);
    u2 = r2/(r1 + r2);
    
    s1 = abs((block_width - 1)*320 -160 - width_cnt);
    s2 = abs((block_width)*320 -160 - width_cnt);
    
    v1 = s1/(s1 + s2);
    v2 = s2/(s1 + s2);
end

w1 = u1*v1;
w2 = u1*v2;
w3 = u2*v1;
w4 = u2*v2;
end


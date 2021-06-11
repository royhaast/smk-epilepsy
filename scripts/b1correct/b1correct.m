function b1correct(in,out)

addpath(genpath('./MP2RAGE-related-scripts'));

load('./parameters.mat');

B1     = load_untouch_nii(in);
B1.img = double(B1.img)./double(B1.img);

T1     = load_untouch_nii(in);

[tmp, UNI] = T1toMP2RAGE(B1, [], T1, MP2RAGE, [], 0.96);

MP2RAGEnew = T1;
MP2RAGEnew.img = UNI.img;

save_untouch_nii(MP2RAGEnew, out);
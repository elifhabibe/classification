
%% SAB�TLER
clear; clc;
DizinResimler='03.Data';
SinifExcelDosya='S�n�fAdlar�2.xlsx';

EgitimSetiYuzde=80;
YSATekrarSayisi=5;%YSA modeli ba�tan 5 kez tekrar edilecek demek. Nedeni ise YSA n�n ba�lang�� �artlar�na ba�l� olmas�.Yani sistem 5 kez deneyip en iyisini se�ecek
 
%% DOSYALAR
%ResimDosyalar = getirResimDosyalar(DizinResimler);
[~,~,DataSinif] = xlsread(SinifExcelDosya); 
DataSinif=DataSinif(2:end,:);

[ResimSinif1, ResimSinif2, ResimSinif3] = sinifAta(DataSinif);
clear DataSinif ResimDosyalar SinifExcelDosya 

% kod i�inde daha sonra kullanmayaca��m de�i�kenler, hafizade yer tutmas�n
% diye sildim zaten bu de�i�keler ilerde kullan�lmayacak o y�zden sildim

%% EGITIM VE TEST DOSYALARIN ATANMASI
[EgitimResim,EgitimResimSinif,TestResim,TestResimSinif] = ysaGirisCikis(EgitimSetiYuzde,ResimSinif1,ResimSinif2,ResimSinif3); 
clear Resim* TrainingPercentage
%excel dosyas�ndaki resim s�n�flar� bilgisi, ve e�itim y�zdesi parametrelerine g�re resimleri, E�itim ve Test olarak ikiye ay�r�yor.
%% YSA E��T�M
[EgitimData,EgitimSinif] = resim2data(DizinResimler,EgitimResim,EgitimResimSinif);
if ~isequal(size(EgitimData,2),size(EgitimSinif,2)), error('YSA E��T�M veri boyutlar� uyu�muyor'); end
clear EgitimResim EgitimResimSinif EgitimSetiYuzde
%Herbir E�itim Resim dosyas�n�n verisini ve s�n�f bilgisini ilgili parametreleri kullanarak okuyor
%resim2data fonk bu i�i yap�yor a��a��da tam�nlad�m

HataOpt=1e10;  % Ba�lang�� i�in uydurma de�er 
for k=1:YSATekrarSayisi %E�itim ba�l�yor.Bu bloktaki i�lem 5 kez tekrarlan�yor demek ayn� modeli, farkl� "ilk a��rl�k" de�erleri ile yeniden �al��t�rmak
    net = patternnet(5); %3 sat�rda YSA modeli tan�mlan�yor patternnet s�n�fland�rmaya �zel a�"patternnet(5)" demek, bir giri� bir ��k�� katman� ve bir de gizli katmandan olu�uyor demek.gizli katmandaki m�ron say�s� 5 demek A��rl�k de�erleri burda rastgele belirleniyor her seferinde.
    net.trainParam.showWindow=false;
    net = train(net,EgitimData,EgitimSinif);%olu�turulan net, e�itim data ve s�n�flar� ile e�itiliyor
    yy = net(EgitimData); %e�itilen net, e�itim datas� i�in bir sonu� veriyor
    % yy, herbir e�itim giri�i i�in 3 ��kt� �retiyor. Bunlar�n herbiri 0-1 aral���nda.
    if ~isequal(unique(yy(:)),[0; 1])
        yy = sonuc2sinif(yy); %bu fonk a�� tan�mlad�m. 100 001 gibi de�erler d�nd�r�yor.Bunu yaparken de ilgili s�n�f i�in en y�ksek "�yelik de�erini" kullan�yor.[0.6 0.1 0.3] i�in [1 0 0] birinci s�n�f
    end
    
    [~,HataYuzde] = TestDegerlendirme(EgitimSinif,yy);%Elimizde YSA ��kt� de�erleri ve ger�ek de�erler var."TestDegerlendirme" fonksiyonu da ikisini k�yaslayarak HataYuzde de�eri hesapl�yor Yani modelin, ger�e�e ne kadar uzak oldu�unu buluyor
    %HataSTD=std(EgitimSinif(:)-yy(:));
    fprintf(1,'YSA Modelleme Tekrar: %02d  > Hata (%%): %.4f\n',k,HataYuzde);
    if HataYuzde<HataOpt %bu hata de�erini en k���k olacak �ekilde kontrol ediyor ve e�er en k���kten k���k ise hem YSA modelini (netOpt olarak) hem de hatay�(HataOpt) sakl�yor.en uygun modeli, en az hata ile buluyor.
        netOpt=net;
        HataOpt=HataYuzde;        
    end
    clear net yy HataSTD 
end %for un sonu 5 kere d�ncek
fprintf(1,'\n');
fprintf(1,'Min Hata(%%): %.4f\n\n',HataOpt);
yyEgitimOpt=netOpt(EgitimData);
yyEgitimOpt = sonuc2sinif(yyEgitimOpt);
if ~isequal(unique(yyEgitimOpt(:)),[0; 1])
    yyEgitimOpt = sonuc2sinif(yyEgitimOpt);
end
clear EgitimData EgitimSinif k HataOpt yyEgitimOpt YSATekrarSayisi k
%e�itilmi� bir YSA modelimiz var.Bunu elimizdeki test verisi ile deneyebilriz.
%% YSA TEST
[TestData,TestSinif] = resim2data(DizinResimler,TestResim,TestResimSinif);% bu fonk ile  test resimlerine ait veri ve s�n�f bilgileri �a�r�l�yor
if ~isequal(size(TestData,2),size(TestSinif,2)), error('YSA TEST veri boyutlar� uyu�muyor'); end
clear EgitimResim EgitimResimSinif
yyTahmin=netOpt(TestData);%test datas�n� girdi olarak alarak test k�mesindeki herbir resim i�in yyTahmin �retiyor.
if ~isequal(unique(yyTahmin(:)),[0; 1])
    yyTahmin = sonuc2sinif(yyTahmin);
end
[TestKiyasSonuc,HataYuzde] = TestDegerlendirme(TestSinif,yyTahmin);%elde edilen sonu�lar ile ger�ek de�erler k�yaslanarak Hata miktar� elde ediliyor.burada elde edilen ��kt�, herbir test resmine ait.

%% SONU�LARIN YAZDIRILMASI
TestKiyasSonucStr=cell(size(TestKiyasSonuc));
for k=1:size(TestKiyasSonuc,1)
    for j=1:size(TestKiyasSonuc,2)-1
        if TestKiyasSonuc(k,j)==1% 1=k, 2=O, 3=B demek
            TestKiyasSonucStr{k,j}='K���k';
        elseif TestKiyasSonuc(k,j)==2
            TestKiyasSonucStr{k,j}='Orta';
        elseif TestKiyasSonuc(k,j)==3
            TestKiyasSonucStr{k,j}='B�y�k';
        else
            error('S�n�f 1, 2, 3 den farkl�!');
        end
    end
    TestKiyasSonucStr{k,3}=TestKiyasSonuc(k,3);
end
            
fprintf('\n');
fprintf(1,'YSA TEST SONU�LARI:\n\n');
fprintf(1,'      Dosya    ORIGINAL SINIF    YSA SINIF   BA�ARI\n');
fprintf(1,'     -------  ---------------    ---------   -------\n');

for k=1:length(TestKiyasSonucStr)
    fprintf('%02d  %8s %10s %16s %8d\n', k, TestResim{k},TestKiyasSonucStr{k,1},TestKiyasSonucStr{k,2},TestKiyasSonucStr{k,3});
end

fprintf('\n');
fprintf('T�m Test resimleri Ba�ar� Oran�(%%): %.2f [%d/%d] \n\n', 100.*(sum(TestKiyasSonuc(:,3))./numel(TestKiyasSonuc(:,3))), sum(TestKiyasSonuc(:,3)),numel(TestKiyasSonuc(:,3)));


function yySinif = sonuc2sinif(yy)
yySinif=zeros(size(yy));
for k=1:length(yy)
    [~,i]=max(yy(:,k));
    if isempty(i), error('MAX verisi belirlenemedi!'); end
    if ~isequal(size(i),[1 1]), error('MAX verisi birden fazla s�n�fa ait!'); end
    yySinif(i,k)=1;
    clear i
end
end

function [TestKiyasSonuc,HataYuzde] = TestDegerlendirme(TestSinif,yyTahmin)
if ~isequal(size(TestSinif),size(yyTahmin)), error('Test ve Tahmin veri boyutlar� ayn� de�il!'); end

% TestKiyasSonuc=[Ger�ek Test Sonu�];
TestKiyasSonuc=nan(length(TestSinif),3);
for k=1:length(TestSinif)
    p=find(TestSinif(:,k)==1);
    if isempty(p), error('TEST verisinde S�n�f Belirtilmemi�!'); end
    if ~isequal(size(p),[1 1]), error('TEST verisinde birden fazla s�n�f atanm��!'); end
    TestKiyasSonuc(k,1)=p;
    
    p=find(yyTahmin(:,k)==1);
    if isempty(p), error('TAHM�N verisinde S�n�f Belirtilmemi�!'); end
    if ~isequal(size(p),[1 1]), error('TAHM�N verisinde birden fazla s�n�f atanm��!'); end
    TestKiyasSonuc(k,2)=p;
    clear p
end
TestKiyasSonuc(:,3)=1; %varsay�lan olarak atanmas�
mask= TestKiyasSonuc(:,1) ~= TestKiyasSonuc(:,2);  
TestKiyasSonuc(mask,3)=0;
HataYuzde = 100 - (sum(TestKiyasSonuc(:,3))/numel(TestKiyasSonuc(:,3))).*100;
end

function [Data,Sinif] = resim2data(DizinResimler,Resim,ResimSinif)
Data1=imread(fullfile(DizinResimler,Resim{1}));
[N,M,T]=size(Data1); clear Data1;

Data=nan(N*M*T,length(Resim));

for k=1:length(Resim)
    A=imread(fullfile(DizinResimler,Resim{k}));
    if ~isequal(size(A),[N,M,T]), error('Resim boyutu standard de�il!'); end
    Data(:,k) = double(A(:));
    clear A
end
Sinif=ResimSinif';
end

function [EgitimResim,EgitimResimSinif,TestResim,TestResimSinif] = ysaGirisCikis(TrainingPercentage,ResimSinif1,ResimSinif2,ResimSinif3)

d=min([length(ResimSinif1) length(ResimSinif2) length(ResimSinif3)]);
nEgitim=floor(d*(TrainingPercentage/100));

% A.) EGITIM KUMES�
EgitimResim=[];
EgitimResimSinif=[];
% S�n�f1 (K)  atamas�
EgitimResim=[EgitimResim; ResimSinif1(1:nEgitim)];
EgitimResimSinif=[EgitimResimSinif;repmat([ 1 0 0],nEgitim,1)];

% S�n�f2 (O) atamas�
EgitimResim=[EgitimResim; ResimSinif2(1:nEgitim)];
EgitimResimSinif=[EgitimResimSinif;repmat([ 0 1 0],nEgitim,1)];

% S�n�f3 (B) atamas�
EgitimResim=[EgitimResim; ResimSinif3(1:nEgitim)];
EgitimResimSinif=[EgitimResimSinif;repmat([ 0 0 1],nEgitim,1)];
if ~isequal(size(EgitimResim,1),size(EgitimResimSinif,1)), error('E�itimResim dosya ve s�n�f say�s�nda sorun var'); end
if ~isequal(length(EgitimResim),length(unique(EgitimResim))), error('E�itimResim atamas�nda sorun var'); end

%-------------------------------------------------------------
% B.) TEST KUMES�
TestResim=[];
TestResimSinif=[];
% S�n�f1 (K)  atamas�
TestFiles=ResimSinif1(nEgitim+1:end);
TestResim=[TestResim; TestFiles];
TestResimSinif=[TestResimSinif;repmat([ 1 0 0],length(TestFiles),1)];

% S�n�f2 (O) atamas�
TestFiles=ResimSinif2(nEgitim+1:end);
TestResim=[TestResim; TestFiles];
TestResimSinif=[TestResimSinif;repmat([ 0 1 0],length(TestFiles),1)];

% S�n�f3 (B) atamas�
TestFiles=ResimSinif3(nEgitim+1:end);
TestResim=[TestResim; TestFiles];
TestResimSinif=[TestResimSinif;repmat([ 0 0 1],length(TestFiles),1)];
if ~isequal(size(TestResim,1),size(TestResimSinif,1)), error('TestResim dosya ve s�n�f say�s�nda sorun var'); end
if ~isequal(length(TestResim),length(unique(TestResim))), error('TestResim atamas�nda sorun var'); end
end

function [ResimSinif1, ResimSinif2, ResimSinif3] = sinifAta(DataSinif)
m1=0;
m2=0;
m3=0;
for k=1:length(DataSinif)
    if strcmpi(DataSinif{k,2},'K')
        m1=m1+1;
        ResimSinif1{m1,1}=DataSinif{k,1};
    elseif strcmpi(DataSinif{k,2},'O')
         m2=m2+1;
        ResimSinif2{m2,1}=DataSinif{k,1};
    elseif strcmpi(DataSinif{k,2},'B')
         m3=m3+1;
        ResimSinif3{m3,1}=DataSinif{k,1};
    else
        error('S�n�f K, O, veya B de�erlerinden biri de�il!')
    end
end
end

function ResimDosyalar = getirResimDosyalar(DizinResimler)

% Training images
ResimDosyalar=dir(DizinResimler);
ResimDosyalar=ResimDosyalar(3:end,:);
ResimDosyalar=struct2cell(ResimDosyalar);
ResimDosyalar=ResimDosyalar(1,:);
ResimDosyalar=ResimDosyalar';
end
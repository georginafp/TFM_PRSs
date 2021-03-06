### 1. CREATING M1
The matrix M1 will be the matrix that will contain all the individuals with available genetic information (in columns), accompanied by the best PRS values of each phenotype (BW, GA, BMI, SBP, DBP, FEV, HGT, FVC, FM, WC) of interest as well as its first 10 principal component values. 

```{r}

# Establishing the working directory 
setwd("D:/Georgina/Documents/Creating_M1")

# Listing all the elements present in the directory 
fold <- as.factor(list.files())

# Only the folders from the 10 phenotypes are going to be processed
t <- length(fold) - 10 

# Save its length in a new  variable 
n <- length(fold)-t

# Create an empty list 
datalist = list()

# For each elements in the directory, enter to each folder and establish it as the working directory 
for (i in 1:n){
  setwd(paste0("D:/Georgina/Documents/Creating_M1", "/", fold[[i]]))  									                  
  fileNames1 <- list.files(pattern = ".summary")	 		        	# List files with extension = .summary					
  library(data.table)  
  dat <- fread(fileNames1)                                      # Read the files 
  
  fileNames2 <- list.files(pattern = "scaled_PRSvalues.txt")    # List files with extension = . scaled_PRSvalues.txt
  dat1 <- fread(fileNames2)                                     # Read the files 
  
  threshold <- dat$Threshold		                                # Save the threshold in a new variable 								                          
  threshold <- paste0("Pt_", threshold)	                        # Paste the preffix Pt_ used in the files 

  library(dplyr)    
  dat2 <- dat1 %>%                                              # select only values from the best threshold (according to what PRSice has generated )
    select(c(FID, IID, threshold))
  
  datalist[[i]] <- dat2                                         # Save each element in a list (the empty one created above)

}

big_data = do.call(cbind, datalist)                             # join all the elements from the list together 
colnames(big_data)[1] <- "F_ID"                                 # change the first levels so that one can keep them and delete the others 
colnames(big_data)[2] <- "I_ID"

rm_col <- c("FID", "IID")

big_data2 <- big_data[, !(colnames(big_data) %in% rm_col), drop = FALSE]
which_yes <- which(big_data2 == "TRUE")                         # save the index of the columns that are ids                    

big_data3 <- big_data[, which_yes, with = FALSE]                # keep only columns that are not in the index list containing columns of IDS 

colnames(big_data3)[1] <- "FID"                                 # rename the columns as they were initially named
colnames(big_data3)[2] <- "IID"

# Load the phenofiles where the 10 GWAS PCs are stored in 
bmi <- fread("pheno_data_BMIMETAB.tsv")
bmi <- bmi[bmi$FINAL_ancestry == "EUR", ]
resp <- fread("pheno_data_RESPALLER.tsv")
resp <- resp[resp$FINAL_ancestry == "EUR", ]
repr <- fread("pheno_data_REPR.tsv")
repr <- repr[repr$FINAL_ancestry == "EUR", ]

# Are they identical? 
identical(bmi$PC1, resp$PC1) # TRUE 
identical(repr$PC1, resp$PC1) # TRUE 
identical(repr$PC1, bmi$PC1) # TRUE 


PCs <- data.frame(bmi$FID,bmi$PC1,bmi$PC2, bmi$PC3, bmi$PC4, bmi$PC5, bmi$PC6, 
                  bmi$PC7, bmi$PC8, bmi$PC9, bmi$PC10)
names(PCs) <- c("FID", "PC1", "PC2", "PC3", "PC4", "PC5", "PC6","PC7", "PC8", "PC9", "PC10") 

big_data3 = big_data3[!duplicated(big_data3$FID),] # no duplicated individuals 
PCs = PCs[!duplicated(big_data3$FID),] # no duplicated individuals 

# When x has some duplicated column name(s) they need to be renamed 
names(big_data3) <- c("FID", "IID", "Pt_0.01_BW", "Pt_0.05_GA", "Pt_0.05_BMI", "Pt_1_SBP", "Pt_0.01_DBP", "Pt_0.01_FEV", "Pt_0.001_HGT", "Pt_0.001_FVC", "Pt_0.05_FM", "Pt_0.001_WC")

# Merging both dataframes keeping all individuals from the PRS (those that have available genetic information). The default argument is used so that only matching items will be kept
M1=merge(big_data3, PCs ,by="FID") # 1155 x 22
M1 = M1[!duplicated(M1$FID),] # 1155

```

### 2. CREATING M2 

The matrix M2 will be the matrix that will contain the individuals with available information regarding the covariates of interest (age, sex, smoking information, and maternal education). 

```{r}

# Load the database that contains covariate information 
dat <- fread("HELIX_smok.txt")

# Database containing only IDS and smoking-related information
smoking <- data.frame(dat$HelixID, dat$msmok_a) # 10980
# Change the labels 
names(smoking) <- c("FID", "msmok_a")
# Database containing only IDS and sex and age information 
covariates <- data.frame(bmi$FID, bmi$e3_sex, bmi$age_sample_months) # 1304
# Change the labels 
names(covariates) <- c("FID", "sex", "age_sample_months")

# Merge them by FID keeping ALL the individuals 
M2.1=merge(covariates, smoking, by="FID", all=T) # 10980

# Load the database that contains maternal education 
mat_ed <- fread("pheno_with_maternaleducation.tsv")
mat_ed <- mat_ed[,-2]

# Merge maternal education with the covariates + smoking any matrix (M2.1)
# The default argument so that only matching items will be kept
M2.2=merge(M2.1, mat_ed, by="FID") # 1429

# Apply complete cases so any NAs is keept
M2.3 <- M2.2[complete.cases(M2.2), ]  # 1198
M2.3 = M2.3[!duplicated(M2.3$FID),] #1086

# Now we need to add tobacco information but from the other variables.
# The ones that were considering smoking during trimestres (msmok_s) and its dose (msmok_d)
smoking_others <- data.frame(dat$HelixID, dat$msmok_s, dat$msmok_d)
# Change the labels 
names(smoking_others) <- c("FID", "msmok_s", "msmok_d")

# Merge it with the matrix before containing only complete cases
M2.4=merge(M2.3, smoking_others, by="FID", all.x = T) # 1198 x 7
M2.4 = M2.4[!duplicated(M2.4$FID),] # 1086

```


### 3. CREATING M3 

The matrix M3 will be the matrix that will contain all the original HELIX phenotype information. In other words, it will contain the individuals that have at least information of one phenotype.


```{r}

# Keep IDS and phenotypic information from the repr database 
REPR <- data.frame(repr$FID, repr$IID, repr$e3_bw, repr$e3_gac)
names(REPR) <- c("FID", "IID", "BW", "GA")

# Keep IDS and phenotypic information from the bmi database 
BMI <- data.frame(bmi$FID, bmi$IID, bmi$hs_zbmi_who, bmi$hs_c_height,
                  bmi$hs_z_fatprop_bia, bmi$hs_z_waist, bmi$hs_zsys_bp, 
                  bmi$hs_zdia_bp)
names(BMI) <- c("FID", "IID", "BMI", "HGT", "FM", "WC", "SBP", "DBP")

# Keep IDS and phenotypic information from the resp database 
RESP <- data.frame(resp$FID, resp$IID, resp$fev1_pp, resp$fvc_pp)
names(RESP) <- c("FID", "IID", "FEV", "FVC")

M3.1=merge(REPR, BMI, by="FID", all=T) # 1155 x 11

M3.2 <- merge(M3.1, RESP, by="FID", all=T)  # 1155 x 14
M3.2 = M3.2[!duplicated(M3.2$FID),] # 1155

# Is there any individual that has missings in ALL the phenotypes?
t <- apply(M3.2, 1, function(x) length(which(is.na(x))))
max(t) # maximum number of NAs is in 4 phenotypes 

```

### 4. CREATING M4

The matrix M4 will contain the individuals that have complete information of covariates and tobacco variable any (msmok_a), together with tobacco information of the rest of the variables (msmok_s and msmok_d), joined with the original HELIX phenotypic information. In other words, M2.4 and M3.2 will be joined (merged). 

```{r}
# Merge them by IDS using the default argument so that only matching items will be kept
M4 <- merge(M2.4, M3.2, by="FID") # 1086 x 20

# Let's remove some duplicated columns (IDs, sex...)
colnames(M4)
M4 <- subset(M4, select=c(1:7,9,10,12:17,19,20)) #1086 x 17
M4 = M4[!duplicated(M4$FID),] # 1086

```


### 5. CREATING M5

The following matrix will contain all the individuals that have available genetic information and covariates and maternal education and smoking and original HELIX phenotypes. 
In other words, M4 and M5 will be merged. 

```{r}
# Merge them by IDs using the default argument so that only matching items will be kept
M5 <- merge(M1, M4, by="FID") #1086 x 38
M5 = M5[!duplicated(M5$FID),] #1086
# Let's export the table/matrix M5
write.table(M5, "M5_results.txt", row.names=F, quote=F)

```

library(ggplot2)
library(dplyr)
library(corrplot)
library(psych)

#load the dataset
fifa_data <- read.csv("../data/FIFA22_official_data_preprocessed.csv")

summary(fifa_data)

shape <- dim(fifa_data)
shape


# > shape <- dim(fifa_data)
# > shape
# [1] 15818    64

# check if all the missing value have been processed
sum(is.na(fifa_data))

# since I have 64 features here, and some of variable are not useful for my pca
# and factor analysis, I decide to select some of most important features to
# complete the analysis.

# subsetting the data with selected features
selected_columns <- fifa_data %>% 
  select(Overall, Potential, Crossing, Finishing, Dribbling, BallControl, Acceleration, SprintSpeed, 
         Agility, Strength, Interceptions, Vision, Composure, Positioning, Stamina)

# preview the selected data
head(selected_columns)


# ----------------------------------------------

# Run PCA on the selected data
pca_result <- prcomp(selected_columns, scale. = TRUE)

# View summary of PCA result to understand the proportion of variance explained by each component
summary(pca_result)

# Get the loadings (which original features contribute to each principal component)
pca_result$rotation

# Scree plot to visualize the explained variance
plot(pca_result, type = "lines")

# Scatter plot of the first three principal components
pca_scores <- data.frame(pca_result$x)
ggplot(pca_scores, aes(x = PC1, y = PC2, color = PC3)) +
  geom_point(alpha = 0.5) +
  labs(title = "PCA: First Two Principal Components", x = "PC1", y = "PC2") +
  theme_minimal()


# ------------------------------------------------


# determine the number of factors to extract
fa_parallel <- fa.parallel(selected_columns, fa = "fa")

# use the Bartlett method to estimate factor scores
factor_analysis_result <- fa(selected_columns, nfactors = 3, rotate = "varimax", scores = "Bartlett")

# view the loadings to see which variables load onto which factors
print(factor_analysis_result$loadings)

# visualize factor loadings
fa.diagram(factor_analysis_result)

# factor scores: these are the new low-dimensional representations
factor_scores <- factor_analysis_result$scores

# convert these factor scores to a data frame and analyze further
factor_scores_df <- data.frame(factor_scores)

# check the names of the columns in factor_scores_df
names(factor_scores_df)

# visualizing the first two factors, MR1 ,MR2 and MR3
ggplot(factor_scores_df, aes(x = MR1, y = MR2, color = MR3)) +
  geom_point(alpha = 0.8) +
  labs(title = "Factor Analysis: First Two Factors (MR1 vs MR2)", x = "MR1", y = "MR2") +
  theme_minimal()

# ---------------------------
# Assuming you have selected specific original variables related to your hypotheses
original_features <- fifa_data %>% 
  select(Overall, Potential, Crossing, Finishing, Dribbling, BallControl, Acceleration, SprintSpeed, 
         Agility, Strength, Interceptions, Vision, Composure, Positioning, Stamina)

# Run K-means clustering
set.seed(123)
kmeans_original <- kmeans(original_features, centers = 3)  # Adjust the number of clusters (centers) as needed

# Add cluster assignments to your data
fifa_data$Cluster_Original <- as.factor(kmeans_original$cluster)

# Visualize the clusters using PCA for original features
ggplot(pca_scores, aes(x = PC1, y = PC2, color = fifa_data$Cluster_Original)) +
  geom_point(alpha = 0.5) +
  labs(title = "K-Means Clustering on Original Features (PCA: PC1 vs PC2)", x = "PC1", y = "PC2") +
  theme_minimal()



# Run K-means clustering on the first few principal components
set.seed(123)
kmeans_pca <- kmeans(pca_scores[, 1:3], centers = 3)  # Adjust the number of clusters and PCs as needed

# Add cluster assignments to your PCA scores data frame
pca_scores$Cluster_PCA <- as.factor(kmeans_pca$cluster)

# Visualize the clusters in the PCA space
ggplot(pca_scores, aes(x = PC1, y = PC2, color = Cluster_PCA)) +
  geom_point(alpha = 0.5) +
  labs(title = "K-Means Clustering on PCA Scores (PC1 vs PC2)", x = "PC1", y = "PC2") +
  theme_minimal()

# ---------------------
# Run K-means clustering on factor scores
set.seed(123)
kmeans_factors <- kmeans(factor_scores_df[, 1:3], centers = 3)  # Adjust the number of clusters and factors as needed

# Add cluster assignments to your factor scores data frame
factor_scores_df$Cluster_Factor <- as.factor(kmeans_factors$cluster)

# Visualize the clusters in the factor analysis space
ggplot(factor_scores_df, aes(x = MR1, y = MR2, color = Cluster_Factor)) +
  geom_point(alpha = 0.5) +
  labs(title = "K-Means Clustering on Factor Scores (MR1 vs MR2)", x = "MR1", y = "MR2") +
  theme_minimal()

# ------------------------------
# Clean the 'Position' column using regular expression
fifa_data$Position <- gsub('<span class="pos pos[0-9]+">', '', fifa_data$Position)

# Extract unique values in the 'Position' column
unique_positions <- unique(fifa_data$Position)

# Print the unique positions
print(unique_positions)

# Remove rows with 'nan' in the Position column
fifa_data_clean <- fifa_data %>% filter(Position != "nan")

# Define defensive and offensive positions
defensive_positions <- c("CB", "LB", "RB", "LWB", "RWB", "CDM", "LDM", "RDM", "LCB", "RCB")
offensive_positions <- c("ST", "CF", "CAM", "LW", "RW", "LS", "RS", "LF", "RF", "RAM", "LAM", "RM", "LM", "RCM", "LCM", "CM")

# Classify positions into defensive, offensive, or goalkeeper roles
fifa_data_clean$Role <- ifelse(fifa_data_clean$Position %in% defensive_positions, "Defensive",
                               ifelse(fifa_data_clean$Position %in% offensive_positions, "Offensive",
                                      ifelse(fifa_data_clean$Position == "GK", "Goalkeeper", NA)))


# Remove rows where Role is NA
fifa_data_clean <- fifa_data_clean %>% filter(!is.na(Role))

# Check the distribution of roles
table(fifa_data_clean$Role)


# Remove 'cm' from Height and convert to numeric
fifa_data_clean$Height <- as.numeric(gsub("cm", "", fifa_data_clean$Height))

# Remove 'kg' from Weight and convert to numeric
fifa_data_clean$Weight <- as.numeric(gsub("kg", "", fifa_data_clean$Weight))

# Check the first few rows to confirm the conversion
head(fifa_data_clean[, c("Height", "Weight")])


# Summary statistics by Role
summary_stats <- fifa_data_clean %>%
  group_by(Role) %>%
  summarise(
    Avg_Height = mean(Height, na.rm = TRUE),
    Avg_Weight = mean(Weight, na.rm = TRUE),
    Avg_Strength = mean(Strength, na.rm = TRUE)
  )

print(summary_stats)

# Visualize distributions
ggplot(fifa_data_clean, aes(x = Role, y = Height, fill = Role)) +
  geom_boxplot() +
  labs(title = "Height Distribution by Role", x = "Role", y = "Height (cm)") +
  theme_minimal()

ggplot(fifa_data_clean, aes(x = Role, y = Weight, fill = Role)) +
  geom_boxplot() +
  labs(title = "Weight Distribution by Role", x = "Role", y = "Weight (kg)") +
  theme_minimal()




# -----------------------------------------
# Subset the data to include only goalkeepers
goalkeepers <- fifa_data_clean %>% filter(Position == "GK")

# Calculate the correlation between Reflexes and Overall rating
cor_goalkeepers <- cor(goalkeepers$GKReflexes, goalkeepers$Overall, use = "complete.obs")
print(cor_goalkeepers)

# Scatter plot of Reflexes vs Overall rating
ggplot(goalkeepers, aes(x = GKReflexes, y = Overall)) +
  geom_point(alpha = 0.6) +
  geom_smooth(method = "lm", col = "blue") +  # Add a linear regression line
  labs(title = "Relationship between Reflexes and Overall Rating for Goalkeepers",
       x = "GK Reflexes", y = "Overall Rating") +
  theme_minimal()


# Fit a linear regression model
lm_goalkeepers <- lm(Overall ~ GKReflexes, data = goalkeepers)

# Summary of the regression model
summary(lm_goalkeepers)

# --------------------------------------

# Calculate average overall rating by club
club_prestige <- fifa_data_clean %>%
  group_by(Club) %>%
  summarise(Avg_Overall = mean(Overall, na.rm = TRUE)) %>%
  arrange(desc(Avg_Overall)) %>%
  slice_head(n = 10)  # Select the top 10 clubs

# Check the result to make sure Avg_Overall is calculated
print(club_prestige)

# Merge the club prestige back into the original data
fifa_data_clean_top10 <- fifa_data_clean %>%
  filter(Club %in% club_prestige$Club) %>%
  left_join(club_prestige, by = "Club")

# Check the column names in fifa_data_clean_top10 to ensure Avg_Overall is there
print(names(fifa_data_clean_top10))


# Function to convert '€107.5M' to numeric value 107.5 million
convert_value <- function(value) {
  # Remove the euro symbol and commas
  value <- gsub("€", "", value)
  
  # Convert 'M' to million and 'K' to thousand
  value <- ifelse(grepl("M", value), 
                  as.numeric(gsub("M", "", value)) * 1e6, 
                  ifelse(grepl("K", value), 
                         as.numeric(gsub("K", "", value)) * 1e3, 
                         as.numeric(value)))
  return(value)
}

# Apply the function to the Value column
fifa_data_clean_top10$Value <- sapply(fifa_data_clean_top10$Value, convert_value)

# Verify the conversion
head(fifa_data_clean_top10$Value)

# Scatter plot of Club Prestige vs Market Value for Top 10 Clubs
ggplot(fifa_data_clean_top10, aes(x = Avg_Overall, y = Value, color = Club)) +
  geom_point(alpha = 0.7, size = 2) +
  geom_smooth(method = "lm", col = "blue", size = 0.5) +  # Make the regression line thinner
  labs(title = "Club Prestige (Avg Overall) vs Market Value for Top 10 Clubs", 
       x = "Club Prestige (Avg Overall)", y = "Market Value (€)") +
  theme_minimal() +
  scale_color_discrete(name = "Club") +
  scale_y_continuous(labels = scales::comma)


# Calculate the correlation between Club Prestige and Market Value
correlation <- cor(fifa_data_clean_top10$Avg_Overall, fifa_data_clean_top10$Value, use = "complete.obs")
print(paste("Correlation between Club Prestige and Market Value: ", round(correlation, 2)))

# Fit a linear regression model
lm_model <- lm(Value ~ Avg_Overall, data = fifa_data_clean_top10)

# Summary of the regression model
summary(lm_model)







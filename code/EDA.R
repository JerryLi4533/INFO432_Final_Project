library(ggplot2)
library(dplyr)
library(corrplot)

#load the dataset
fifa_data <- read.csv("../data/FIFA22_official_data.csv") 

# get information about dataset
head(fifa_data)
str(fifa_data)
summary(fifa_data)

# find the shape of dataset
shape <- dim(fifa_data)
shape

## > shape
## [1] 16710    65

# find the missing value
sum(is.na(fifa_data))

# find the missing value in each column
missing_values_per_column <- colSums(is.na(fifa_data))
missing_values_per_column

# I find I get 15818 data have missing value in marking column, which is abnormal, 
# so I check the data and found this is data for legend players. 
# Since this project I only want to focus on current player, I decided to remove these players.
fifa_data_clean <- fifa_data[is.na(fifa_data$Marking), ]
dim(fifa_data_clean)

# After I remove all the legend player, almost all the missing value problem have solved.
# I still have 16 players have missing value in Jersy.Number, so I decided to use mode of jersy number to replace them.
missing_values_per_column_clean <- colSums(is.na(fifa_data_clean))
missing_values_per_column_clean

# use mode to replace missing value in jersey number
jersey_mode <- as.numeric(names(sort(table(fifa_data_clean$Jersey.Number), decreasing = TRUE)[1]))
fifa_data_clean$Jersey.Number[is.na(fifa_data_clean$Jersey.Number)] <- jersey_mode


missing_values_per_column_clean <- colSums(is.na(fifa_data_clean))
missing_values_per_column_clean

# Since current player don't have marking, I decide to remove this column
fifa_data_clean <- fifa_data_clean %>% select(-Marking)

# check if all the missing value have been processed
sum(is.na(fifa_data_clean))

# get overall view of each column
summary(fifa_data_clean)

# save the preprocessed dataset
write.csv(fifa_data_clean, "../data/FIFA22_official_data_preprocessed.csv", row.names = FALSE)

# Find distribution of overall player rating distribution
ggplot(fifa_data_clean, aes(x=Overall)) + 
  geom_histogram(binwidth=1, fill="lightblue", color="black") +
  labs(title="Overall Rating Distribution", x="Overall Rating", y="Frequency")

# Analyse player age distribution
ggplot(fifa_data_clean, aes(x=Age)) +
  geom_histogram(binwidth=1, fill="lightblue", color="black") +
  labs(title="Age Distribution", x="Age", y="Frequency")

# Analyse preferred foot distribution
ggplot(fifa_data_clean, aes(x=Preferred.Foot)) +
  geom_bar(fill="darkgreen") +
  labs(title="Preferred Foot Distribution", x="Preferred Foot", y="Frequency")

# find club that have top 10 overall player rating
top_10_clubs <- fifa_data_clean %>%
  group_by(Club) %>%
  summarize(Average_Overall = mean(Overall, na.rm = TRUE)) %>%
  arrange(desc(Average_Overall)) %>%
  slice_head(n = 10)

# find the top 10 clubs 
top_10_clubs_data <- fifa_data_clean %>%
  filter(Club %in% top_10_clubs$Club)

# plot the box plot
ggplot(top_10_clubs_data, aes(x = reorder(Club, Overall, FUN = median), y = Overall)) +
  geom_boxplot(fill = "lightblue", color = NA) +
  stat_summary(fun = mean, geom = "point", shape = 21, size = 1, fill = "blue") +
  stat_summary(fun = mean, geom = "text", aes(label = round(..y..)), vjust = -0.5, color = "black", size = 3) + # use integer to show average rating
  coord_flip() +
  labs(title = "Top 10 Club Overall Rating Distribution", x = "Club", y = "Overall Rating") +
  theme_minimal()


# find the top 10 countries that by calculating the top 50 player's average score
top_10_countries <- fifa_data_clean %>%
  group_by(Nationality) %>%
  arrange(desc(Overall)) %>%
  slice_max(Overall, n = 50, with_ties = FALSE) %>%
  summarize(Average_Overall = mean(Overall, na.rm = TRUE)) %>%
  arrange(desc(Average_Overall)) %>%
  top_n(10, wt = Average_Overall)

# find the top 10 countries from dataset
top_10_countries_data <- fifa_data_clean %>%
  filter(Nationality %in% top_10_countries$Nationality)


# plotting the overall score distribution of the top 50 players from the top 10 countries
ggplot(top_10_countries_data, aes(x = reorder(Nationality, Overall, FUN = median), y = Overall)) +
  geom_boxplot(fill = "lightblue", color = NA) +
  stat_summary(fun = mean, geom = "point", shape = 21, size = 1, fill = "blue") +
  stat_summary(fun = mean, geom = "text", aes(label = round(..y..)), vjust = -0.5, color = "black", size = 3) +  # use integer to show average rating
  coord_flip() +
  labs(title = "Overall Score Distribution of Top 50 Players from the Top 10 Countries", x = "Nationality", y = "Overall Score") +
  theme_minimal()

# plotting the relationship between player age and potential rating
ggplot(fifa_data_clean, aes(x = Age, y = Potential)) +
  geom_point(alpha = 0.5) +
  geom_smooth(method = "loess", color = "blue", se = FALSE) +
  labs(title = "Player Age vs. Potential", x = "Age", y = "Potential") +
  theme_minimal()



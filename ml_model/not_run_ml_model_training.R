# 1. Load the required R libraries

#############REPLACE WITH QUANTEDA????

# Package names
packages <- c("tidyr", "dplyr", "data.table", "tm", "textclean", "wordcloud", "e1071", "caret", "randomForest", "cvms", "tidytext", "readr", "gt", "ranger")

# Install packages not yet installed
installed_packages <- packages %in% rownames(installed.packages())
if (any(installed_packages == FALSE)) {
  install.packages(packages[!installed_packages])
}

# Packages loading
invisible(lapply(packages, library, character.only = TRUE))

# 2. Create corpus
# Load raw dataset without the company info (which we do not need for this machine learning model) 
# We have 3789 transactions with labels of type 
raw_transaction_dataset <- readRDS("ml_model/1_text_classification_non_tokenized_company_info.rds") %>% 
 select(-firma)

# Remove non-ASCII characters from Czech language, which could pose problem.
raw_transaction_dataset$zprava <- replace_non_ascii(raw_transaction_dataset$zprava)

# Separate transaction type labels to a factor vector
all_transaction_labels <- as.factor(raw_transaction_dataset$typ)

# Create corpus with the tm package of the text. Each line is a separate "document"
# This corpus serves as a basis for all other data manipulations and cleanings
transaction_corpus <- Corpus(VectorSource(raw_transaction_dataset$zprava))

print(transaction_corpus)

inspect(transaction_corpus[1:10])


# MODELS: SET 1 (TF Weighting) -----------------------------------------------------------

# 3. Create Document-Term Matrix
# This sparse matrix has 3966 columns
transaction_dtm <- DocumentTermMatrix(transaction_corpus, control = list(
  tolower = TRUE,
  removeNumbers = TRUE,
  removePunctuation = TRUE,
  stripWhitespace = TRUE,
  stopwords = FALSE,
  PlainTextDocument = TRUE
))

print(transaction_dtm)

inspect(transaction_dtm[1:10, 1:10])

# Remove a part of sparse items, which might not add much value

transaction_dtm_sparse <- removeSparseTerms(transaction_dtm, 0.9995)

# Convert to matrix for modelling

transaction_matrix <- as.matrix(transaction_dtm_sparse)



# 4. Train ML models part 1: split data into training and testing parts
# First, create training indices
sample_size <- floor(0.75 * length(all_transaction_labels))
set.seed(2021)
train_transaction_labels_index <- sample(length(all_transaction_labels), size = sample_size)
train_transaction_labels <- all_transaction_labels[train_transaction_labels_index]
test_transaction_labels <- all_transaction_labels[-train_transaction_labels_index]

# Proportions of labels in the training data and the testing data
data.frame(prop.table(table(train_transaction_labels)), prop.table(table(test_transaction_labels)))

# Partition the DTM as well
train_transaction_matrix  <- transaction_matrix[train_transaction_labels_index,]
test_transaction_matrix  <- transaction_matrix[-train_transaction_labels_index,]

# 5. Train ML models part 2:
set.seed(2021)
model_nb_1 <- naiveBayes(formula = train_transaction_labels ~ ., x = train_transaction_matrix, y = train_transaction_labels) 

set.seed(2021)
model_svm_1 <- svm(formula = train_transaction_labels ~ ., x = train_transaction_matrix, y = train_transaction_labels, scale = FALSE) 

set.seed(2021)
model_rf_1 <- randomForest(x = train_transaction_matrix, y = train_transaction_labels, do.trace = 100, ntree = 500) 

summary(model_nb_1)
summary(model_svm_1)
summary(model_rf_1)

# Test with test data
pred_nb_1 <- predict(object = model_nb_1, newdata = test_transaction_matrix)
pred_svm_1 <- predict(object = model_svm_1, newdata = test_transaction_matrix)
pred_rf_1 <- predict(object = model_rf_1, newdata = test_transaction_matrix)

# Check accuracy:
table(pred_nb_1, test_transaction_labels)
table(pred_svm_1, test_transaction_labels)
table(pred_rf_1, test_transaction_labels)

confusionMatrix(data = pred_nb_1, reference = test_transaction_labels)
confusionMatrix(data = pred_svm_1, reference = test_transaction_labels)
confusionMatrix(data = pred_rf_1, reference = test_transaction_labels)

# Save models to RDS
saveRDS(model_nb_1, "doc/ml_models/nb_1.rds")
saveRDS(model_svm_1, "doc/ml_models/svm_1.rds")
saveRDS(model_rf_1, "doc/ml_models/rf_1.rds")

# Results summary:
# Model 1. TF weighting, remove sparse =  0.9995
# - Accuracy: SVM: 45%, RandomForest: 80%, NaiveBayes: 15%


# MODELS: SET 2 (weigthing TF-IDF) -----------------------------------------------------------

# Input data
# 3. Create Document-Term Matrix
transaction_dtm <- DocumentTermMatrix(transaction_corpus, control = list(
  # weighting = weightTfIdf,
  tolower = TRUE,
  removeNumbers = TRUE,
  removePunctuation = TRUE,
  stripWhitespace = TRUE,
  stopwords = FALSE,
  PlainTextDocument = TRUE
))

print(transaction_dtm)

# Remove a part of sparse items, which might not add much value
transaction_dtm_sparse <- removeSparseTerms(transaction_dtm, 0.9995)

# Lowering the amount of terms to 1342
print(transaction_dtm_sparse)

# Convert to matrix for modelling
transaction_matrix <- as.matrix(transaction_dtm_sparse)

# Indices
sample_size <- floor(0.8 * length(all_transaction_labels))
set.seed(2021)
train_transaction_labels_index <- sample(length(all_transaction_labels), size = sample_size)
train_transaction_labels <- all_transaction_labels[train_transaction_labels_index]
test_transaction_labels <- all_transaction_labels[-train_transaction_labels_index]

# Partition the DTM
train_transaction_matrix  <- transaction_matrix[train_transaction_labels_index,]
test_transaction_matrix  <- transaction_matrix[-train_transaction_labels_index,]

# Training
set.seed(2021)
model_nb_2 <- naiveBayes( x = train_transaction_matrix, y = train_transaction_labels, laplace = 1) 

set.seed(2021)
model_svm_2 <- svm(x = train_transaction_matrix, y = train_transaction_labels, scale = FALSE) 

set.seed(2021)
tuned_rf <- tuneRF(x = train_transaction_matrix, y = train_transaction_labels, mtryStart = 576, ntreeTry = 100) # mtry = 144 is suggested
model_rf_2 <- randomForest(x = train_transaction_matrix, y = train_transaction_labels, do.trace = 100, ntree = 500, mtry = 144) 
model_rf_2_ra <- ranger(x = train_transaction_matrix, y = train_transaction_labels, num.trees = 1000, mtry = 288, importance = "impurity") 

summary(model_nb_2)
summary(model_svm_2)
summary(model_rf_2)

# Test with test data
set.seed(2021)
pred_nb_2 <- predict(object = model_nb_2, newdata = test_transaction_matrix)

set.seed(2021)
pred_svm_2 <- predict(object = model_svm_2, newdata = test_transaction_matrix)

set.seed(2021)
pred_rf_2 <- predict(object = model_rf_2, newdata = test_transaction_matrix)

set.seed(2021)
pred_rf_2_ra <- predict(object = random_forest_classification_model, newdata = test_transaction_matrix)

# Check accuracy:
confusionMatrix(data = pred_nb_2, reference = test_transaction_labels)
confusionMatrix(data = pred_svm_2, reference = test_transaction_labels)
confusionMatrix(data = pred_rf_2, reference = test_transaction_labels)
confusionMatrix(data = pred_rf_2_ra, reference = test_transaction_labels)


# Save models to RDS
saveRDS(model_nb_2, "ml_model/nb_2.rds")
saveRDS(model_svm_2, "ml_model/svm_2.rds")
saveRDS(model_rf_2, "ml_model/random_forest_classification_model.rds")


# 5. VERDICT: Best performing model is Random Forest trained on 1342 features, 500 trees, mtry parameter of 144 and 80/20 training-test split
saveRDS(model_rf_2, "doc/ml_models/rf_classification_model.rds")

# 6. Create Vizualizations that summarize the model performance
varImpPlot(model_rf_2, sort = TRUE, n.var = 50, pch = 16, main = "Random Forest Model: most important variables (terms = 1342, ntree = 500, mtry = 144, 80/20 split)")

basic_table <- as_tibble(table(tibble(test_transaction_labels,
                                      pred_rf_2)))
plot_confusion_matrix(basic_table, 
                      target_col = "test_transaction_labels", 
                      prediction_col = "pred_rf_2",
                      counts_col = "n",
                      add_normalized = FALSE,
                      diag_percentages_only = FALSE,
                      add_row_percentages = TRUE,
                      add_col_percentages = TRUE)

# Visualize differences between categories in a WordCloud
transaction_dataset_tokenized <- raw_transaction_dataset %>% 
  unnest_tokens(output = "word", token = "words", input = zprava) %>%
  count(typ, word) 

# Apply basic text cleaning steps 
stop_words_cz <- read_csv(
  "https://raw.githubusercontent.com/stopwords-iso/stopwords-cs/master/stopwords-cs.txt", 
  col_names = "word")


transaction_dataset_tokenized$word <- removeNumbers(transaction_dataset_tokenized$word)
transaction_dataset_tokenized$word <- removePunctuation(transaction_dataset_tokenized$word)
transaction_dataset_tokenized$word <- stripWhitespace(transaction_dataset_tokenized$word)
transaction_dataset_tokenized <-  as_tibble(transaction_dataset_tokenized) %>% 
  anti_join(stop_words_cz)

# Define a color palette for the Word Cloud
palette <- brewer.pal(8, "Dark2")

# Generate wordcloud
set.seed(2021)
transaction_dataset_tokenized %>% 
    filter(typ == "s") %>% 
    with(wordcloud(word,
                      n, 
                      random.order = FALSE, 
                      scale = c(5,.3), 
                      min.freq = 3, 
                      max.words = 100,
                      colors = palette))

# Create table, which summarizes transaction type labels
# How many categories of transactions do we have?
categories_overview <- raw_transaction_dataset  %>% 
  group_by(as.vector(typ)) %>% 
  count() %>% 
  arrange(desc(n)) %>% 
  ungroup() %>% 
  rename(transaction_type = `as.vector(typ)`,
         number = n)

 gt_table <- gt(categories_overview) %>% tab_header(
   title = "Number of labelled transaction types in our training dataset"
 )
 
 gtsave(gt_table, "doc/ml_model_training/dataset_transaction_types_training_data.png")
 
 
 

#### PREDICTION ON NEW DATA
 
 prediction_model <- readRDS("doc/ml_model_training/random_forest_classification_model.rds")
 
 new_dataset <- readRDS("data/merged_data.rds")   
 
  
 new_dataset$text <- paste(new_dataset$message_for_recipient, new_dataset$note)
 
 new_dataset$text <- replace_non_ascii(new_dataset$text)
 
 
 # Names of variables used for prediction
 
  new_corpus <- Corpus(VectorSource(new_dataset$text))
 
 new_dtm <- DocumentTermMatrix(new_corpus, control = list(
   tolower = TRUE,
   removeNumbers = TRUE,
   removePunctuation = TRUE,
   stripWhitespace = TRUE,
   stopwords = FALSE,
   PlainTextDocument = TRUE
 ))
 
  new_matrix <- as.matrix(new_dtm)

  # what are the columns that are in common among the new and old data?
  col_names_old <- names(prediction_model$forest$ncat)
  col_names_new <- colnames(new_matrix)
 
  new_matrix_common <- new_matrix[, intersect(col_names_new, col_names_old)]
  
  # To simplify this code - WORK IN PROGRESS
  
  old_matrix_empty <- matrix(ncol = length(col_names_old), nrow = nrow(new_matrix_common), dimnames = list(1:nrow(new_matrix_common), col_names_old))
  
  # old_matrix_empty_index <- as.numeric(!colnames(old_matrix_empty) %in% intersect(col_names_new, col_names_old))
  # 
  # old_matrix_empty <- old_matrix_empty[, old_matrix_empty_index]
  
  old_matrix_empty[is.na(old_matrix_empty)] <- 0
 
  combined_matrix <- cbind(new_matrix_common, old_matrix_empty)
 
 # Make predictions and add prediction labels as a column to the dataset
 
  prediction_new_data <- predict(object = prediction_model, newdata = combined_matrix)
  
  new_dataset_with_predictions <- cbind(new_dataset, prediction_new_data)
 
  categories_overview_new_data <- new_dataset_with_predictions  %>% 
    select(prediction_new_data) %>% 
    group_by(as.vector(prediction_new_data)) %>% 
    count() %>% 
    arrange(desc(n)) %>% 
    ungroup() %>% 
    rename(transaction_type = `as.vector(prediction_new_data)`,
           number = n)
  
  gt_table <- gt(categories_overview_new_data) %>% tab_header(
    title = "Number of labelled transaction types in our new real-life data"
  )
  
  gtsave(gt_table, "doc/ml_model_training/dataset_transaction_types_new_data.png")
  
  # Export the experimentally labelled dataset
  
  fwrite(new_dataset_with_predictions, "doc/ml_model_training/experimental_labelled_dataset.csv")  

  

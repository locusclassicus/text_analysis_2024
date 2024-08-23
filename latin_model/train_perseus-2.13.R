# https://github.com/UniversalDependencies/UD_Latin-Perseus
# https://www.bnosac.be/index.php/blog/102-udpipe-r-package-updated

# download the treebank
library(utils)
settings <- list()
settings$ud.train    <- "https://raw.githubusercontent.com/UniversalDependencies/UD_Latin-Perseus/master/la_perseus-ud-train.conllu"
settings$ud.test     <- "https://github.com/UniversalDependencies/UD_Latin-Perseus/blob/master/la_perseus-ud-test.conllu"


download.file(url = settings$ud.train, destfile = "train.conllu")
download.file(url = settings$ud.test,  destfile = "test.conllu")

## Build a word2vec model using out R package word2vec
library(udpipe)
library(word2vec)
txt <- udpipe_read_conllu("train.conllu")
txt <- paste.data.frame(txt, term = "token", group = c("doc_id", "paragraph_id", "sentence_id"), collapse = " ")
txt <- txt$token
w2v <- word2vec(txt, type = "skip-gram", dim = 50, window = 10, min_count = 2, negative = 5, iter = 15, threads = 1)
write.word2vec(w2v, file = "wordvectors.vec", type = "txt", encoding = "UTF-8")
predict(w2v, c("exercitus", "flumen"), type = "nearest", top = 20)

## And train the model (this takes a while!)
print(Sys.time())
m <- udpipe_train(file = "la_perseus-2.13-20231115.udpipe", 
                  files_conllu_training = "train.conllu", 
                  annotation_tokenizer = list(dimension = 64, epochs = 100, segment_size=200, initialization_range = 0.1, 
                                              batch_size = 50, learning_rate = 0.002, learning_rate_final=0, dropout = 0.1, 
                                              early_stopping = 1),
                  annotation_tagger = list(models = 2, 
                                           templates_1 = "lemmatizer", 
                                           guesser_suffix_rules_1 = 8, guesser_enrich_dictionary_1 = 4, 
                                           guesser_prefixes_max_1 = 4, 
                                           use_lemma_1 = 1,provide_lemma_1 = 1, use_xpostag_1 = 0, provide_xpostag_1 = 0, 
                                           use_feats_1 = 0, provide_feats_1 = 0, prune_features_1 = 1, 
                                           templates_2 = "tagger", 
                                           guesser_suffix_rules_2 = 8, guesser_enrich_dictionary_2 = 4, 
                                           guesser_prefixes_max_2 = 0, 
                                           use_lemma_2 = 1, provide_lemma_2 = 0, use_xpostag_2 = 1, provide_xpostag_2 = 1, 
                                           use_feats_2 = 1, provide_feats_2 = 1, prune_features_2 = 1),
                  annotation_parser = list(iterations = 30, 
                                           embedding_upostag = 20, embedding_feats = 20, embedding_xpostag = 0, 
                                           embedding_form = 50, embedding_form_file = "wordvectors.vec", 
                                           embedding_lemma = 0, embedding_deprel = 20, learning_rate = 0.01, 
                                           learning_rate_final = 0.001, l2 = 0.5, hidden_layer = 200, 
                                           batch_size = 10, transition_system = "projective", transition_oracle = "dynamic", 
                                           structured_interval = 8))
print(Sys.time())

## Evaluate the accuracy
m <- udpipe_load_model("la_perseus-2.13-20231115.udpipe")
goodness_of_fit <- udpipe_accuracy(m, "test.conllu", 
                                   tokenizer = "default", 
                                   tagger = "default", 
                                   parser = "default")
cat(goodness_of_fit$accuracy, sep = "\n") 

## Evaluate the accuracy of the prebuilt model
goodness_of_fit_old <- udpipe_accuracy(latin_perseus, "test.conllu", 
                                   tokenizer = "default", 
                                   tagger = "default", 
                                   parser = "default")
cat(goodness_of_fit_old$accuracy, sep = "\n") 

## Annotate new text
caesar_annotate2 <- udpipe_annotate(m, caesar$text[1])

caesar_pos2 <- as_tibble(caesar_annotate2) |> 
  select(-doc_id, -paragraph_id)

caesar_pos2


## join for comparison
caesar_pos2_sel <- caesar_pos2 |> 
  filter(row_number() < 101) |>
  select(lemma, upos, xpos, feats) |> 
  rename(lemma_new = lemma, upos_new = upos, xpos_new = xpos, feats_new = feats)


check_data <- caesar_pos |> 
  select(token, lemma, upos, xpos, feats) |> 
  filter(row_number() < 101) |> 
  rename(lemma_old = lemma, upos_old = upos, xpos_old = xpos, feats_old = feats) |> 
  bind_cols(caesar_pos2_sel)

write_csv2(check_data, file = "check_data.csv")

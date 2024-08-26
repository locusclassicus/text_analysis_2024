library(udpipe)

# load text
liza <- readLines(con = "karamzin_liza.txt")

# annotate
russian_syntagrus <- udpipe_load_model(file = "russian-syntagrus-ud-2.5-191206.udpipe")
liza_ann <- udpipe_annotate(russian_syntagrus, liza)
liza_tbl <- as_tibble(liza_ann) |> 
  select(-paragraph_id, -sentence, -xpos)

save(liza_tbl, file = "../data/liza_tbl.Rdata")



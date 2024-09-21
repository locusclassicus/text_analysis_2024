url <- "https://github.com/locusclassicus/text_analysis_2024/raw/main/files/manual_title_subset.tsv"
download.file(url, destfile = "../files/manual_title_subset.tsv")

# прежде всего избавимся от лишних столбцов 
library(tidyverse)
noveltm <- read_tsv("./files/manual_title_subset.tsv")

noveltm <- noveltm |> 
  select(author, inferreddate, latestcomp, gender, nationality, shorttitle, category)


# в наших данных сведения о публикации хранятся в столбце `inferreddate`, 
# а названия -- в столбце `shorttitle`. Количество слов в названии придется посчитать: 
# для этого можно посчитать количество пробелов и добавить единицу.  

noveltm <- noveltm |> 
  mutate(n_words = str_count(shorttitle, " "))

save(noveltm, file = "./data/noveltm.Rdata")


Нужный нам файл (в формате tsv) [скопирован](https://github.com/locusclassicus/text_analysis_2024/raw/main/files/manual_title_subset.tsv) в репозиторий курса. 
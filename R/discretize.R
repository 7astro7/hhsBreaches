
library(dplyr)

discretize = function(df, col_string) {
    # gets the discretized (or as close to discretized as is needed, 
    # some have slashes) elements of the column with name col_string.
    # col_string is used because the column isn't selectable otherwise 

    # distinct rows are retrieved from extracted_col; the object 
    # returned is a tbl_df. distinct rows are passed as input to 
    # as.character(), applied to the whole list. the list of 
    # distinct rows now stored as character type is passed as 
    # input to strsplit, splitting on commas, applied to the 
    # whole list. row values are effectively atomic at this point and so 
    # the larger-scope list is passed as input to unlist, returning 
    # a list with one layer of redundant nesting removed 
    distinct_and_split_col = df %>% 
                select(all_of(col_string)) %>% 
                distinct() %>% 
                lapply(as.character) %>%
                lapply(strsplit, ",") %>% 
                lapply(unlist)
    
    # distinct_and_split_col now holds a sequence that's identified 
    # with the column name. e.g., calling the method 
    # names(distinct_and_split_col) at this point might return 
    # "type_of_breach". to make the elements of the vector accessible 
    # to str_trim() and str_to_lower() the vector actually storing 
    # relevant elements at index 1 is used 
    # whitespace is removed from the elements and each is made 
    # lowercase for standardization
    discretized_col = distinct_and_split_col[[1]] %>% 
                str_trim() %>% 
                str_to_lower()

    # unique is assigned the set of discrete elements found in the 
    # vector. NA may be contained in the set
    unique = c()
    for (i in 1:length(discretized_col)) {
        distinct_element = !(discretized_col[i] %in% unique)
        if (distinct_element) {
            unique[length(unique) + 1] = discretized_col[i]
        }
    }
    return (unique)
}


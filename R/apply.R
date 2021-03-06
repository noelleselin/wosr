#' Run \code{pull_wos} across multiple queries
#'
#' @inheritParams query_wos
#' @param queries Vector of queries to issue to the WoS API and pull data for.
#'
#' @return The same set of data frames that \code{\link{pull_wos}} returns, with
#' the addition of a data frame named \code{query}. This data frame frame tells
#' you which publications were returned by a given query.
#'
#' @examples
#' \dontrun{
#'
#' queries <- c('TS = "dog welfare"', 'TS = "cat welfare"')
#' # we can name the queries so that these names appear in the queries data
#' # frame returned by pull_wos_apply():
#' names(queries) <- c("dog welfare", "cat welfare")
#' pull_wos_apply(queries)
#'}
#' @export
pull_wos_apply <- function(queries,
                           editions = c("SCI", "SSCI", "AHCI", "ISTP", "ISSHP",
                                        "BSCI", "BHCI", "IC", "CCR", "ESCI"),
                           sid = auth(Sys.getenv("WOS_USERNAME"),
                                      Sys.getenv("WOS_PASSWORD")),
                           ...) {
  if (is.null(names(queries))) {
    names(queries) <- queries
  }
  query_names <- names(queries)
  if (length(query_names) != length(unique(query_names))) {
    stop("The names of your queries must be unique", call. = FALSE)
  }

  res_list <- pbapply::pblapply(
    query_names, one_pull_wos_apply,
    queries = queries,
    editions = editions,
    sid = sid,
    ... = ...
  )

  df_names <- c(unique(schema$df), "query")
  out <- lapply2(
    df_names,
    function(x) unique(do.call(rbind, lapply(res_list, function(y) y[[x]])))
  )

  append_class(out, "wos_data")
}

one_pull_wos_apply <- function(query_name, queries, editions, sid, ...) {
  query <- queries[[query_name]]
  message("\n\nPulling WoS data for the following query: ", query_name, "\n\n")
  wos_out <- pull_wos(query = query, editions = editions, sid = sid, ...)
  uts <- wos_out[["publication"]][["ut"]]
  num_pubs <- length(uts)
  if (num_pubs == 0)
    query_df <- data.frame(
      ut = character(),
      query = character(),
      stringsAsFactors = FALSE
    )
  else
    query_df <- data.frame(
      ut = uts,
      query = rep(query_name, num_pubs),
      stringsAsFactors = FALSE
    )
  wos_out$query <- query_df
  wos_out
}

#' Run \code{query_wos} across multiple queries
#'
#' @inheritParams query_wos
#' @param queries Vector of queries run.
#'
#' @return A data frame which lists the number of records returned by each of
#' your queries.
#'
#' @examples
#' \dontrun{
#'
#' queries <- c('TS = "dog welfare"', 'TS = "cat welfare"')
#' query_wos_apply(queries)
#'}
#' @export
query_wos_apply <- function(queries,
                            editions = c("SCI", "SSCI", "AHCI", "ISTP", "ISSHP",
                                         "BSCI", "BHCI", "IC", "CCR", "ESCI"),
                            sid = auth(Sys.getenv("WOS_USERNAME"),
                                       Sys.getenv("WOS_PASSWORD")),
                            ...) {

  if (is.null(names(queries))) {
    names(queries) <- queries
  }
  query_names <- names(queries)
  if (length(query_names) != length(unique(query_names))) {
    stop("The names of your queries must be unique", call. = FALSE)
  }

  rec_cnt <- vapply(
    queries, one_query_wos_apply,
    editions = editions,
    sid = sid,
    ... = ...,
    FUN.VALUE = numeric(1)
  )

  data.frame(
    query = query_names,
    rec_cnt = unname(rec_cnt),
    stringsAsFactors = FALSE
  )
}

one_query_wos_apply <- function(query, editions, sid, ...) {
  q_out <- query_wos(query, editions, sid, ...)
  q_out$rec_cnt
}

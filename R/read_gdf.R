#' Read in a gdf file
#'
#' Read in a gdf file and return an igraph graph
#'
#' @importFrom igraph graph_from_data_frame
#' @importFrom stringr str_detect
#' @importFrom readr read_lines
#' @importFrom data.table fread
#' @importFrom stats median
#'
#' @param filepath File to import
#' @param as_igraph Return as igraph graph. If \code{FALSE} it returns a list with the node and edge data, respectively, instead.
#' @param verbose Whether to print progress in the console.
#' @export
read_gdf <- function(filepath, as_igraph = TRUE, verbose = FALSE) {

  if (verbose) message("1: Reading in raw file")
  gdf <- readr::read_lines(filepath, progress = verbose)

  if (verbose) message("2: Extracting edge data")
  edge_place_l <- stringr::str_detect(gdf, "edgedef>")
  edge_place <- which(edge_place_l)
  if (length(edge_place) > 0) {
    has_edge_data <- any(edge_place_l) & (length(edge_place:length(gdf)) > 1)
    node_data <- gdf[1:(edge_place - 1)]
  } else {
    has_edge_data <- FALSE
    node_data <- gdf
  }

  if (has_edge_data) {
    edge_data <- gdf[edge_place:length(gdf)]
    edge_data[1] <- gsub("edgedef>node", "node", edge_data[1])
    edge_data[1] <- paste0(sapply(strsplit(edge_data[1], ","), function(x) gsub("^(.*) [A-Z]+$", "\\1", x)), collapse = ",")
    edge_data <- paste0(edge_data, collapse = "\n")
    edge_data <- data.table::fread(edge_data,
                                   sep = ",",
                                   header = TRUE,
                                   data.table = FALSE,
                                   integer64 = "double",
                                   verbose = FALSE,
                                   showProgress = verbose)
  } else {
    if (verbose) message("(Didn't find edge data)")
    edge_data <- data.frame()
  }

  if (verbose) message("3: Extracting node data")
  node_data[1] <- gsub("nodedef>name", "name", node_data[1])
  node_data[1] <- paste0(sapply(strsplit(node_data[1], ","), function(x) gsub("^(.*) [A-Z]+$", "\\1", x)), collapse = ",")

  ## Some links have commas in them wo/quotation marks, thus messing
  ## up the fread. We just remove troubled rows, and check n commas in
  ## the header row
  n_sep <- stringr::str_count(node_data, ",")
  bad_apples <- which(n_sep != median(n_sep[2:length(n_sep)]))
  bad_apples <- bad_apples[bad_apples != 1]
  if (length(bad_apples) > 0) {
    node_data <- node_data[-bad_apples]
    warning(paste0("Removed ", length(bad_apples), " row(s) due to comma error in file"))
  }
  if (n_sep[1] < median(n_sep)) {
    node_data[1] <- paste0(node_data[1], paste0(rep(",", (median(n_sep[2:length(n_sep)]) - n_sep[1]), collapse = "")))
  }
  ## The combine and fread, if there is any node data.
  if (length(node_data) > 1) {
    node_data <- paste0(node_data, collapse = "\n")
    node_data <- data.table::fread(node_data,
                                   select = 1:median(n_sep),
                                   sep = ",",
                                   header = TRUE,
                                   data.table = FALSE,
                                   integer64 = "double",
                                   verbose = FALSE,
                                   showProgress = verbose)
    duplics <- duplicated(node_data$name)
    has_node_data <- TRUE
    if (any(duplics)) {
      node_data <- node_data[-c(which(duplics)), ]  # Remove duplicated nodes
    }
  } else {
    node_data <- data.frame()
    has_node_data <- FALSE
    warning("No eligable node data")
  }

  ## Return data
  if (as_igraph & has_edge_data) {
    if (verbose) message("4: Converting to igraph")
    out <- igraph::graph_from_data_frame(d = edge_data,
                                         directed = TRUE,
                                         vertices = ifelse(has_node_data, node_data, NULL))
  } else {
    if (!has_edge_data | !has_node_data)
      warning("Not returning an igraph object due to missing edge or node data")
    out <- list(node_data, edge_data)
  }
  return(out)
}

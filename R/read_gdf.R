#' Read in a gdf file
#'
#' Read in a gdf file and return an igraph graph
#'
#' @importFrom igraph graph_from_data_frame
#' @importFrom stringr str_detect
#' @importFrom readr read_lines
#' @importFrom data.table fread
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
  has_edge_data <- any(edge_place_l)
  if (has_edge_data) {
    edge_place <- which(edge_place_l)
    node_data <- gdf[1:(edge_place - 1)]
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
    node_data <- gdf
    edge_data <- ""
  }
  if (verbose) message("3: Extracting node data")
  node_data[1] <- gsub("nodedef>name", "name", node_data[1])
  node_data[1] <- paste0(sapply(strsplit(node_data[1], ","), function(x) gsub("^(.*) [A-Z]+$", "\\1", x)), collapse = ",")
  node_data <- paste0(node_data, collapse = "\n")
  node_data <- data.table::fread(node_data,
                                 sep = ",",
                                 header = TRUE,
                                 data.table = FALSE,
                                 integer64 = "double",
                                 verbose = FALSE,
                                 showProgress = verbose)
  duplics <- duplicated(node_data$name)
  if (any(duplics)) {
    node_data <- node_data[-c(which(duplics)), ]  # Remove duplicated nodes
  }
  if (as_igraph & has_edge_data) {
    if (verbose) message("4: Converting to igraph")
    out <- igraph::graph_from_data_frame(d = edge_data,
                                         directed = TRUE,
                                         vertices = node_data)
  } else {
    out <- list(node_data, edge_data)
  }
  return(out)
}

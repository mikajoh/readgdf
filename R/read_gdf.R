#' Read in a gdf file and return an igraph data frame
#'
#' Read in a gdf file and return an igraph data frame
#'
#' @importFrom igraph graph_from_data_frame
#' @importFrom data.table fread
#' @importFrom bit64 integer64
#'
#' @param filepath File to import
#' @param as_igraph Return as igraph graph. If \code{FALSE}, it returns a list with the node and edge data, respectively.
#' @param verbose Whether to print progress in console.
#' @export
read_gdf <- function(filepath, as_igraph = TRUE, verbose = TRUE) {
  if (verbose) message("1: Reading in raw file")
  gdf <- readLines(filepath, warn = FALSE)
  if (verbose) message("2: Extracting edge data")
  edge_place_l <- grepl("edgedef>", gdf)
  has_edge_data <- any(edge_place_l)
  if (has_edge_data) {
    edge_place <- which(edge_place_l)
    node_data <- gdf[1:(edge_place - 1)]
    edge_data <- gdf[edge_place:length(gdf)]
    edge_data <- gsub("edgedef>node", "node", edge_data)
    edge_data[1] <- paste0(sapply(strsplit(edge_data[1], ","), function(x) gsub("^(.*) [A-Z]+$", "\\1", x)), collapse = ",")
    edge_data_collapsed <- paste0(edge_data, collapse = "\n")
    edge_data <- as.data.frame(data.table::fread(edge_data_collapsed, sep = ",", header = TRUE))
  } else {
    if (verbose) message("(Didn't find edge data)")
    node_data <- gdf
    edge_data <- ""
  }
  if (verbose) message("3: Extracting node data")
  node_data <- gsub("nodedef>name", "name", node_data)
  node_data[1] <- paste0(sapply(strsplit(node_data[1], ","), function(x) gsub("^(.*) [A-Z]+$", "\\1", x)), collapse = ",")
  node_data_collapsed <- paste0(node_data, collapse = "\n")
  node_data <- as.data.frame(data.table::fread(node_data_collapsed, sep = ",", header = TRUE))
  node_data <- node_data[-c(which(duplicated(node_data$name))), ]  # Remove duplicated nodes
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

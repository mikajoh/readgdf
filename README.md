## readgdf: Import gdf files as igraph graph

Extract network data from gdf files and imports it into R as an igraph graph.

Install the package using devtools (you have to have devtools installed):

``` R
devtools::install_github("mikaelpoul/readgdf", dependencies = TRUE)
```

Then simply load the package and read file with `read_gdf`:

``` R
library(readgdf)
data <- read_gdf("path/to/gdf_file.gdf")
```

It will return an igraph object by default, but you can set `as_igraph = FALSE` to make it return a list with the node and edge data, respectively.




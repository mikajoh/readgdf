readgdf: Read gdf files
---------------

[![Build Status](https://travis-ci.org/mikaelpoul/readgdf.svg?branch=master)](https://travis-ci.org/mikaelpoul/readgdf)
[![Build status](https://ci.appveyor.com/api/projects/status/y212iri5joxyln10?svg=true)](https://ci.appveyor.com/project/mikaelpoul/readgdf)

Import gdf files into R as igraph graphs.

**This is work in progress**

Install the package using devtools (use `install.packages("devtools")` if you don't have it installed):

``` R
devtools::install_github("mikaelpoul/readgdf")
```

Then simply load the package and read your gdf file with `read_gdf`:

``` R
library(readgdf)
data <- read_gdf("path/to/gdf_file.gdf")
```

It will return an igraph graph object by default, but you can set `as_igraph = FALSE` to make it return a list with the node and edge data, respectively, instead. To print the progress while reading set `verbose = TRUE`.

---------------

If come you across any issues, please open an issue or [email me](mailto:mikajoh@gmail.com).

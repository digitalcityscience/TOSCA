#! /bin/bash

# Remove unneccessary items from the mapset

g.remove -f type=vector pattern=*temp*
g.remove -f type=vector pattern=*_*
g.remove -f type=raster pattern=*
exit

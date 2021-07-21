
from qgis.core import *
from qgis.gui import *
from qgis.analysis import *

from qgis.PyQt.QtCore import *
from qgis.PyQt.QtGui import *

from qgis.utils import iface

import sys

from qgis.core import (
     QgsApplication,
     QgsProcessingFeedback,
     QgsVectorLayer
)
from qgis.core import (
    QgsCoordinateReferenceSystem,
    QgsCoordinateTransform,
    QgsProject,
    QgsPointXY,
)

sys.path.append('/usr/share/qgis/python/plugins')


# See https://gis.stackexchange.com/a/155852/4972 for details about the prefix
QgsApplication.setPrefixPath('/usr', True)
qgs = QgsApplication([], False)
qgs.initQgis()

# Append the path where processing plugin can be found
import processing
from processing.core.Processing import Processing

Processing.initialize()

from qgis._analysis import QgsNativeAlgorithms
QgsApplication.processingRegistry().addProvider(QgsNativeAlgorithms())

if(sys.argv[3] == "fromLayer"):
     params = { 'DEFAULT_DIRECTION' : 2, 'DEFAULT_SPEED' : 50, 'DIRECTION_FIELD' : '', 'INCLUDE_BOUNDS' : False,
         'INPUT' : '/home/warr/oct_user/oct/open-city-toolkit/webapp/scripts/servicearea/Road_Network.shp',
         'OUTPUT_LINES' : '/home/warr/oct_user/oct/open-city-toolkit/geoserver_data_dir/data/service_area/Service_Area_Map.shp', 'SPEED_FIELD' : '',
         'START_POINTS' : '/home/warr/oct_user/oct/open-city-toolkit/webapp/scripts/servicearea/Data/'+ sys.argv[2] +'.shp', 'STRATEGY' : 0,
         'TOLERANCE' : 0, 'TRAVEL_COST2' : sys.argv[1], 'VALUE_BACKWARD' : '', 'VALUE_BOTH' : '', 'VALUE_FORWARD' : '' }

     processing.run("qgis:serviceareafromlayer", params)

if(sys.argv[3] == "fromPoint"):

     # Change projection from EPSG:4326 -> EPSG:3857
     crsSrc = QgsCoordinateReferenceSystem("EPSG:4326")   
     crsDest = QgsCoordinateReferenceSystem("EPSG:3857")  
     transformContext = QgsProject.instance().transformContext()
     xform = QgsCoordinateTransform(crsSrc, crsDest, transformContext)

     # forward transformation: src -> dest
     intl = (sys.argv[2]).split(",")
     numX = float(intl[0])
     numY = float(intl[1])
     pt1 = xform.transform(QgsPointXY(numX, numY)) #longitude, lattitude

     params2 = { 'DEFAULT_DIRECTION' : 2, 'DEFAULT_SPEED' : 50, 'DIRECTION_FIELD' : '', 'INCLUDE_BOUNDS' : False,
           'INPUT' : '/home/warr/oct_user/oct/open-city-toolkit/webapp/scripts/servicearea/Road_Network.shp',
           'OUTPUT_LINES' : '/home/warr/oct_user/oct/open-city-toolkit/geoserver_data_dir/data/service_area/Service_Area_Map.shp',
           'SPEED_FIELD' : '', 'START_POINT' : str(pt1[0]) + ',' + str(pt1[1]) + ' [EPSG:3857]', 'STRATEGY' : 0,
           'TOLERANCE' : 0, 'TRAVEL_COST2' : sys.argv[1], 'VALUE_BACKWARD' : '', 'VALUE_BOTH' : '', 'VALUE_FORWARD' : '' }

     processing.run("qgis:serviceareafrompoint", params2)


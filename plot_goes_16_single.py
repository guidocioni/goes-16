# -*- coding: utf-8 -*-
# Required libraries
import matplotlib.pyplot as plt
from netCDF4 import Dataset
from mpl_toolkits.basemap import Basemap # Import the Basemap toolkit
import numpy as np # Import the Numpy package
from matplotlib.colors import LinearSegmentedColormap # Linear interpolation for color maps
from datetime import datetime, date
from pyproj import Proj
from glob import glob
import os
from multiprocessing import Pool


first=True
folder = '/Users/guidocioni/Downloads/'

fnames = glob(folder+"OR_ABI-L2-CMIPC-M3C02_G16_*.nc")

for fname in fnames:
	# Search for the Scan Start in the file name
	Start = (fname[fname.find("_s")+2:fname.find("_e")-1])
	# Format the "Observation Start" string
	datetime_start = datetime.strptime(Start,'%Y%j%H%M%S')

	# Check if we already created the image
	image_string='./images/'+datetime.strftime(datetime_start,'%Y%m%d%H%M%S')+'.png'
	print('Using '+fname)
	nc = Dataset(fname)

	# Subset immediately to get rid of the points with missing values
	# since Python cannot handle them at this huge dimension
	data_subset = nc.variables['CMI'][:][1500:-1,2000:-1]

	if first:
		bmap = Basemap(projection='cyl', llcrnrlon=-84, llcrnrlat=21, urcrnrlon=-82, urcrnrlat=23,  resolution='h')
		# Create the projection variables
		ori_proj = nc.variables['goes_imager_projection']
		sat_h = ori_proj.perspective_point_height
		sat_lon = ori_proj.longitude_of_projection_origin
		sat_sweep = ori_proj.sweep_angle_axis
		# The projection x and y coordinates equals
		# the scanning angle (in radians) multiplied by the satellite height (http://proj4.org/projections/geos.html)
		X = nc.variables['x'][:] * sat_h
		Y = nc.variables['y'][:] * sat_h
		p = Proj(proj='geos', h=sat_h, lon_0=sat_lon, sweep=sat_sweep)
		# Convert map points to latitude and longitude with the magic provided by Pyproj
		XX, YY = np.meshgrid(X, Y)
		lons, lats = p(XX, YY, inverse=True)
		lons_subset=lons[1500:-1,2000:-1]
		lats_subset=lats[1500:-1,2000:-1]
		levels=np.linspace(-0.1, 1.1, 200)
		first = False

	bmap.contourf(lons_subset,lats_subset,data_subset, levels=levels, cmap="gist_gray", extend='both')
	bmap.drawcoastlines(linewidth=0.5, linestyle='solid', color='white')
	bmap.drawcountries(linewidth=0.5, linestyle='solid', color='white')
	bmap.drawparallels(np.arange(-90.0, 90.0, 10.0), linewidth=0.1, color='white', labels=[True, False, False, True])
	bmap.drawmeridians(np.arange(0.0, 360.0, 10.0), linewidth=0.1, color='white', labels=[True, False, False, True])
	date_formatted = datetime.strftime(datetime_start,'%H:%MZ %a %d %b %Y')

	plt.title("GOES-16 ABI Radiance \n Scan from " +date_formatted)
	plt.savefig(image_string, bbox_inches='tight', dpi=200)
	plt.clf()


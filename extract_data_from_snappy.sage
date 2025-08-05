import snappy
import pandas as pd
import re
import numpy as np

#initialize link table
link_iterator = snappy.HTLinkExteriors(knots_vs_links='links')

link_dct = {}
keys = ['name_unoriented', 'determinant', 'num_crossings', 'matrix_zero', 'components', 'jones_factorable']

for link in link_iterator:
	linkname = link.name()
	L = link.link()
	num_crossings = int(re.findall('L(\d+)[an]\d+', linkname)[0])

	if 12 <= num_crossings:
		print(linkname)
		linking_matrix = L.linking_matrix()
		matrix_zero = all(x == 0 for row in linking_matrix for x in row)
		link_dct[linkname] = {key: None for key in keys}
		link_dct[linkname]['num_crossings'] = num_crossings
		link_dct[linkname]['determinant'] = 0
		link_dct[linkname]['matrix_zero'] = matrix_zero
		link_dct[linkname]['name_unoriented'] = linkname
		link_dct[linkname]['components'] = link.num_cusps()


snappy_links_12_to_14_crossings = pd.DataFrame.from_dict(link_dct, orient='index')
snappy_links_12_to_14_crossings.to_csv('results/snappy_links_12_to_14_crossings', index=False)

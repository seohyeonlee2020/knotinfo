# %%
from snappy import *
import pandas as pd
import re
import numpy as np

# %%
#preliminary filtering based on determinant and linking matrix

#initialize link table
link_iterator = HTLinkExteriors(knots_vs_links='links')

link_dct = {}
keys = ['name_unoriented', 'determinant', 'num_crossings', 'matrix_zero', 'components', 'jones_factorable', 'jones_determinant', 'smooth_four_genus']

for link in link_iterator:
	linkname = link.name()
	L = link.link()

	num_crossings = int(re.findall('L(\d+)[an]\d+', linkname)[0])

	if L.determinant() == 0 and 12 <= num_crossings:
		#print(linkname)
		linking_matrix = L.linking_matrix()
		matrix_zero = all(x == 0 for row in linking_matrix for x in row)
		if matrix_zero:
			#append empty dct with relevant information
			link_dct[linkname] = {key: None for key in keys}

			num_crossings = int(re.findall('L(\d+)[an]\d+', linkname)[0])

			link_dct[linkname]['num_crossings'] = num_crossings
			link_dct[linkname]['determinant'] = 0
			link_dct[linkname]['matrix_zero'] = True
			link_dct[linkname]['name_unoriented'] = linkname
			link_dct[linkname]['components'] = link.num_cusps()


link_df = pd.DataFrame.from_dict(link_dct, orient='index')

# %%
def factor_jones(row):
	name = row['name_unoriented']
	num_components = row['components']
	R.<q> = QQ[]
	l = Link(name)
	numerator = l.jones_polynomial()
	denominator = (q + q^(-1))^(num_components - 1)
	try:
		factored = numerator.quo_rem(denominator)
		row['jones_factorable'] = True
		#calculate jones determinant by evaluating the factored polynomial at the imaginary number i
		row['jones_determinant'] = factored[0](q=I)
	except:
		row['jones_factorable'] = False
		row['jones_determinant'] = np.nan
	return row

link_df = link_df.apply(factor_jones, axis=1)

# %%
#deconnect link into components. test if the product of the determinants of each component equals the jones determinant modulo 32

shortlist = pd.read_csv('/Users/seohyeonlee/knotinfo/results/potential_ribbons_12_to_14.csv')

#modEight = IntegerModRing(8)

def check_mod(row):
	#modulo eight
	det = row['jones_determinant']
	return mod(det, 8) == 1

manual_check_needed = []
def check_products(row):
	jones_det = row['jones_determinant']
	num_components = row['components']
	linkname = row['name_unoriented']
	link = Link(linkname)
	det_product = 1
	for i in range(num_components):
		sub = link.sublink([i])
		#if not unknot
		try:
			subdet = sub.determinant()
			det_product *= subdet

		except (IndexError, ValueError) as e:
			#print(f"Failed determinant for component {i}: {e}")
			#if unknot, not an issue, pass
			if sub.exterior().identify() == []:
				print(f'component {i} of link {linkname} is an unknot')
				row['has_unknot'] = True
			else:
				print(f'check for component {i} of link {linkname} failed for some other reason')
				manual_check_needed.append((linkname, i))
	row['has_unknot'] = False

	print(linkname, mod(det_product, 32) == mod(jones_det, 32))
	#row['mod32_equivalent'] = (mod(det_product, 32) == mod(jones_det, 32))
	return mod(det_product, 32) == mod(jones_det, 32)


shortlist.apply(check_products, axis=1)


shortlist['mod32_equivalent'] = shortlist.apply(check_products, axis=1)


mod32_applied = shortlist[shortlist['mod32_equivalent']]
mod32_applied.shape
mod32_applied.to_csv('results/mod32_applied.csv')





# %%
for linkname, component_id in manual_check_needed:
	try:
		iden = Link(linkname).sublink(component_id).exterior().identify()
		print(iden)
		#Link(link).view()
		sublink_det = Manifold(iden[0]).link().determinant()
		mod32 = mod(sublink_det, 32) == mod(jones_det, 32)
		shortlist.loc[shortlist['name_unoriented'] == linkname]['mod32_equivalent'] = mod32
	except:
		print(f"unable to identify { Link(linkname).sublink(component_id)}")







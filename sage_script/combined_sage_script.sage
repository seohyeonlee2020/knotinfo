import snappy


import pandas as pd
import numpy as np
import re

#load extracted data
df = pd.read_csv('/Users/seohyeonlee/knotinfo/results/preliminary_screening_all.csv')
print(f'filtered knots based on first 2 obstructions, {df.shape[0]} potential ribbon links')

#check against snappy ribbon census

def check_ribbon_census(linkname):
	M=snappy.Manifold(linkname)
	try:
		iden = M.identify()
		print(iden)

		if len(iden) > 0:
			ribbon = iden[-1]
			return ('ribbon' in str(ribbon))
		else:
			return False

	except:
		#print("something went wrong")
		return None
df['known_ribbon'] = df.apply(lambda row: check_ribbon_census(row['name_unoriented']), axis=1)

num_known_ribbons = df[df['known_ribbon']].shape[0]
print(f'{num_known_ribbons} known ribbon links in snappy database')

#check if each link has a defined jones determinant
def factor_jones(row):
	name = row['name_unoriented']
	num_components = row['components']
	R.<q> = QQ[]
	l = snappy.Link(name)
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

df = df.apply(factor_jones, axis=1)

df = df[df['jones_factorable']]
print(f'checked for jones determinants, {df.shape[0]} potential ribbon links')

#check the mod 32 condition
manual_check_needed = []
def check_products(row):
	jones_det = row['jones_determinant']
	num_components = row['components']
	linkname = row['name_unoriented']
	link = snappy.Link(linkname)
	det_product = 1

	row['has_unknot'] = False
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
				#print(f'component {i} of link {linkname} is an unknot')
				row['has_unknot'] = True
			else:
				#print(f'check for component {i} of link {linkname} failed for some other reason')
				manual_check_needed.append((linkname, i))

	print(linkname, mod(det_product, 32) == mod(jones_det, 32))
	row['mod32_condition'] = (mod(det_product, 32) == mod(jones_det, 32))
	return row

df = df.apply(check_products, axis = 1)

manually_checked_ribbons = []
for linkname, sublink_id in manual_check_needed:
	print(linkname, sublink_id)
	sublnk = snappy.Link(linkname).sublink(sublink_id).exterior().identify()

	sublink_det = 1
	for item in sublnk:
		try:
			#print(item)
			sublink_det = snappy.Manifold(item).determinant()
			print('try caluse worked')
			print(sublink_det)
		except:
			pass

	print(sublnk, sublink_det)
	link_jones_det = int(df.loc[df['name_unoriented'] == linkname]['jones_determinant'])

	if (mod(sublink_det, 32) == mod(link_jones_det, 32)):
		manually_checked_ribbons.append(linkname)
		df.loc[df['name_unoriented'] == linkname]['mod32_condition'] = True

df = df[df['mod32_condition']]
num_known_ribbons = df[df['known_ribbon']].shape[0]
print(f'df columns after check_products {df.columns}')
print(f'checked for mod 32, {df.shape[0]} potential ribbon links, {num_known_ribbons} known ribbons among them')


#check the mod 8 condition
def check_mod(row):
	#modulo eight
	det = row['jones_determinant']
	return mod(det, 8) == 1

df['mod8_condition'] = df.apply(check_mod, axis = 1)
df = df[df['mod8_condition']]
print(f'checked for mod 8 {df.shape[0]} potential ribbon links')


#fox-milnor test
from snappy.snap.fox_milnor import *
def apply_fox_milnor_test(row):
	try:
		linkname = row['name_unoriented']
		M = snappy.Manifold(linkname)
		row['fox_milnor_test'] = M.fox_milnor_test()
		print(M.fox_milnor_test() )
	except:
		print(f'unable to apply fox milnor test to {linkname}')
		row['fox_milnor_test'] = np.nan
		fox_milnor_failed.append(linkname)
	return row['fox_milnor_test']

df['fox_milnor_test'] = df.apply(apply_fox_milnor_test, axis=1)
df = df[df['fox_milnor_test']]
print(f'applied fox milnor condition, {df.shape[0]} potential ribbon links')


df.to_csv('/Users/seohyeonlee/knotinfo/results/script_applied.csv', index=False)


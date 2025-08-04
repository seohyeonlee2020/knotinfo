import pandas as pd
import numpy as np
from snappy import *
df = pd.read_csv('results/mod32_applied.csv')

fox_milnor_failed = []

def apply_fox_milnor_test(row):
	try:
		linkname = row['name_unoriented']
		M = Manifold(linkname)
		row['fox_milnor_test'] = M.fox_milnor_test()
		print(M.fox_milnor_test() )
	except:
		print(f'unable to apply fox milnor test to {linkname}')
		row['fox_milnor_test'] = np.nan
		fox_milnor_failed.append(linkname)


df[df['fox_milnor_test']].to_csv('results/fox_milnor_applied.csv')

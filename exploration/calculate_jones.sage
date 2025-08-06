from snappy import *
import pandas as pd
import numpy as np

#import the file exported at previous step
cleaned_linkinfo = pd.read_csv('/Users/seohyeonlee/knotinfo/results/cleaned_linkinfo.csv')
print('sage script running')

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

cleaned_linkinfo = cleaned_linkinfo.apply(factor_jones, axis=1)
cleaned_linkinfo.to_csv('/Users/seohyeonlee/knotinfo/results/sage_output.csv')
#cleaned_linkinfo.to_excel('/Users/seohyeonlee/knotinfo/results/sage_output.xlsx')

import snappy
import pandas as pd

df = pd.read_csv('/Users/seohyeonlee/knotinfo/results/fox_milnor_applied.csv')

def check_ribbon_census(linkname):
	M=snappy.Manifold(linkname)
	try:
		iden = M.identify()
		print(iden)
		if len(iden) > 0:
			ribbon = iden[-1]
			return 'ribbon' in str(ribbon)
		else:
			return False
	except:
		print("something went wrong")
		return None


df['known_ribbon'] = df.apply(lambda row: check_ribbon_census(row['name_unoriented']), axis=1)
df.to_csv('/Users/seohyeonlee/knotinfo/results/census_checked.csv')


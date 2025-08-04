import sqlite3
import snappy

conn = sqlite3.connect('my_link_census.sqlite')
cur = conn.cursor()

cur.execute('''
CREATE TABLE IF NOT EXISTS link_table (
    name TEXT PRIMARY KEY,
    crossings INTEGER,
    alternating BOOLEAN,
    components INTEGER
)
''')

for M in snappy.HTLinkExteriors:
    name = M.name()
    components = M.num_cusps()

    cur.execute('''
        INSERT OR REPLACE INTO link_table
        (name, components)
        VALUES (?, ?)
    ''', (name, components))

conn.commit()
conn.close()


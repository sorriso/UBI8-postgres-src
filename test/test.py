import psycopg2     # pip3 install psycopg2-binary
import os

file_path = os.getcwd()

print("")
print(file_path)
print("")

print("Connecting without SSL mode...")
conn = psycopg2.connect(host="localhost", port = 5432, database="test", user="postgres", password="postgres1")
cur = conn.cursor()

print(conn.isolation_level)

print("Creating table...")
cur.execute("CREATE TABLE IF NOT EXISTS books(id bigint, title varchar(128));")
conn.commit()

print("Inserting data...")
cur.execute("INSERT INTO books(title) VALUES('StarWars');")
conn.commit()

print("Reading data...")
cur.execute("SELECT * FROM books")
query_results = cur.fetchall()
print(query_results)
print(len(query_results))

print("Asserting result...")
assert len(query_results) == 1, "Should be 1"

print("Dropping table...")
cur.execute("DROP TABLE books;")
conn.commit()


cur.close()
conn.close()

print("")

print("Connecting with SSL mode...")
conn = psycopg2.connect(host="localhost", port = 5432, database="test", user="postgres", password="postgres1", sslmode='require')
cur = conn.cursor()

print(conn.isolation_level)

print("Creating table...")
cur.execute("CREATE TABLE IF NOT EXISTS books(id bigint, title varchar(128));")
conn.commit()

print("Inserting data...")
cur.execute("INSERT INTO books(title) VALUES('StarWars');")
conn.commit()

print("Reading data...")
cur.execute("SELECT * FROM books")
query_results = cur.fetchall()
print(query_results)
print(len(query_results))

print("Asserting result...")
assert len(query_results) == 1, "Should be 1"

print("Dropping table...")
cur.execute("DROP TABLE books;")
conn.commit()


cur.close()
conn.close()

print("Connecting with SSL mode + client certificat...")
conn = psycopg2.connect(host='localhost', port = 5432, database='test', user='postgres', password='postgres1', sslmode='verify-ca', sslcert=file_path + '/ssl/client.pem', sslkey=file_path + '/ssl/client.key', sslrootcert=file_path + '/ssl/rootCA.pem')
cur = conn.cursor()

print(conn.isolation_level)

print("Creating table...")
cur.execute("CREATE TABLE IF NOT EXISTS books(id bigint, title varchar(128));")
conn.commit()

print("Inserting data...")
cur.execute("INSERT INTO books(title) VALUES('StarWars');")
conn.commit()

print("Reading data...")
cur.execute("SELECT * FROM books")
query_results = cur.fetchall()
print(query_results)
print(len(query_results))

print("Asserting result...")
assert len(query_results) == 1, "Should be 1"

print("Dropping table...")
cur.execute("DROP TABLE books;")
conn.commit()


cur.close()
conn.close()

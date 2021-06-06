import psycopg2
from psycopg2.extras import execute_batch


def query(cnf, q, vals=(), as_dict=False, batch=False):
    with psycopg2.connect(
        dbname=cnf["db"],
        user=cnf["user"],
        host=cnf["host"],
        port=cnf["port"],
        password=cnf["password"],
    ) as conn:

        with conn.cursor() as cur:
            if batch:
                execute_batch(cur, q, vals)
                return

            cur.execute(q, vals)
            column_names = [desc[0] for desc in cur.description]
            for record in cur:
                if as_dict:
                    yield dict(zip(column_names, record))
                else:
                    yield record

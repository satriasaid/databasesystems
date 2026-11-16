"""
tourism_app.py
Name       : Satria Pamungkas
Student ID : 21522611

Part 5 - connect to the tourism database with Python (mysql.connector)
and run some of the Part 3 queries, plus INSERT, UPDATE and DELETE.

Run: python3 tourism_app.py
     (run tourism_create.sql, tourism_data.sql and tourism_advanced.sql first)
"""

import getpass
import mysql.connector
from mysql.connector import Error

DATABASE = "Pamungkas_21522611"


def connect():
    """Step 1-2: ask for the login details and connect to the database."""
    user = input("MySQL username: ")
    password = getpass.getpass("MySQL password: ")   # password is not shown on screen
    conn = mysql.connector.connect(host="localhost", database=DATABASE,
                                   user=user, password=password)
    return conn


def print_rows(title, headers, rows):
    """Print a title, the column names and the rows in simple columns."""
    print("\n" + title)
    print("-" * len(title))
    print(" | ".join(headers))
    for row in rows:
        print(" | ".join(str(value) for value in row))
    print("(" + str(len(rows)) + " rows)")


def query_top_countries(cur):
    """Part 3 Q1: countries with more than 50 million arrivals in 2019."""
    sql = ("SELECT countryCode, statYear, ROUND(arrivals / 1000000, 2) "
           "FROM YearlyStat WHERE statYear = 2019 AND arrivals > 50000000 "
           "ORDER BY arrivals DESC")
    cur.execute(sql)
    print_rows("Q1: Countries with > 50 million arrivals in 2019",
               ["country", "year", "arrivals (millions)"], cur.fetchall())


def query_sites_per_country(cur):
    """Part 3 Q7: number of heritage sites per category for each country."""
    sql = ("SELECT c.countryName, COUNT(*), "
           "SUM(h.category = 'Cultural'), SUM(h.category = 'Natural'), SUM(h.category = 'Mixed') "
           "FROM Country c "
           "INNER JOIN SiteCountry sc ON c.countryCode = sc.countryCode "
           "INNER JOIN HeritageSite h ON sc.siteId = h.siteId "
           "GROUP BY c.countryName HAVING COUNT(*) >= 20 "
           "ORDER BY COUNT(*) DESC")
    cur.execute(sql)
    print_rows("Q7: Heritage sites per country (at least 20 sites)",
               ["country", "total", "cultural", "natural", "mixed"], cur.fetchall())


def query_country_receipts(cur, country_code, year):
    """Part 3 Q6 with parameters: region, income group and receipts of one country.
    The values are passed as parameters (%s), not joined into the SQL string,
    which protects against SQL injection."""
    sql = ("SELECT c.countryName, r.regionName, i.incomeName, "
           "ROUND(y.receiptsUSD / 1000000000, 2) "
           "FROM Country c "
           "INNER JOIN Region r ON c.regionCode = r.regionCode "
           "INNER JOIN IncomeGroup i ON c.incomeCode = i.incomeCode "
           "INNER JOIN YearlyStat y ON c.countryCode = y.countryCode "
           "WHERE c.countryCode = %s AND y.statYear = %s")
    cur.execute(sql, (country_code, year))
    row = cur.fetchone()
    if row is None:
        print("\nNo data for", country_code, year)
    else:
        print_rows("Q6: Receipts of " + country_code + " in " + str(year),
                   ["country", "region", "income group", "receipts (billion US$)"], [row])


def show_stat(cur, country_code, year):
    """Show one YearlyStat row (used to check the insert/update/delete)."""
    cur.execute("SELECT countryCode, statYear, arrivals FROM YearlyStat "
                "WHERE countryCode = %s AND statYear = %s", (country_code, year))
    print_rows("YearlyStat row " + country_code + " " + str(year),
               ["country", "year", "arrivals"], cur.fetchall())


def insert_update_delete(conn, cur):
    """Insert, update and then delete one YearlyStat row.
    Each change is saved with commit(); if it fails, rollback() undoes it."""
    country_code, year = "AUS", 2025
    try:
        # INSERT
        cur.execute("INSERT INTO YearlyStat (countryCode, statYear, arrivals) "
                    "VALUES (%s, %s, %s)", (country_code, year, 8000000))
        conn.commit()
        print("\nINSERT done:", cur.rowcount, "row")
        show_stat(cur, country_code, year)

        # UPDATE (the after_stat_update trigger writes a row to StatChangeLog)
        cur.execute("UPDATE YearlyStat SET arrivals = %s "
                    "WHERE countryCode = %s AND statYear = %s", (8250000, country_code, year))
        conn.commit()
        print("\nUPDATE done:", cur.rowcount, "row")
        show_stat(cur, country_code, year)

        # DELETE (remove the test row again so only real data is kept)
        cur.execute("DELETE FROM YearlyStat WHERE countryCode = %s AND statYear = %s",
                    (country_code, year))
        conn.commit()
        print("\nDELETE done:", cur.rowcount, "row")
        show_stat(cur, country_code, year)
    except Error as e:
        conn.rollback()
        print("Change failed and was rolled back:", e)

    # A bad insert: the before_stat_insert trigger rejects negative arrivals
    try:
        cur.execute("INSERT INTO YearlyStat (countryCode, statYear, arrivals) "
                    "VALUES (%s, %s, %s)", ("JPN", 2025, -10))
        conn.commit()
    except Error as e:
        conn.rollback()
        print("\nBad INSERT rejected by the database:", e.msg)


def main():
    conn = None
    try:
        conn = connect()
        if conn.is_connected():
            cur = conn.cursor()
            cur.execute("SELECT DATABASE(), VERSION()")
            db_name, version = cur.fetchone()
            print("Connected to database", db_name, "on MySQL", version)

            # Steps 3-5: run queries and show the results
            query_top_countries(cur)
            query_sites_per_country(cur)
            query_country_receipts(cur, "THA", 2019)
            insert_update_delete(conn, cur)
            cur.close()
    except Error as e:
        print("Database error:", e)
    finally:
        # Step 6: disconnect
        if conn is not None and conn.is_connected():
            conn.close()
            print("\nConnection closed.")


if __name__ == "__main__":
    main()

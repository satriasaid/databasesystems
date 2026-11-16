# Base code is from https://pynative.com/python-mysql-database-connection/ and 
#                      https://realpython.com/python-mysql/

# MySQL connctivity with pytho3 
# Sample code for Practical 09

import mysql.connector
from getpass import getpass

try:
    # define the connection 
    conn = mysql.connector.connect(
                host = "localhost",
                user = input("Enter username: "),
                password = getpass("Enter password: "), 
                database = "company"
                )
    if conn.is_connected():
        # Create a Cursor object to execute queries
        cur = conn.cursor()
        # show the database you are conencted to 
        cur.execute("SELECT DATABASE();")
        record = cur.fetchone()
        print("You're connected to database: ", record)
        
        # create a query to select data

        select_query1 = "SELECT * FROM Emp"
        cur.execute(select_query1)
        # get all rows
        rows = cur.fetchall()
        #print tthe first four columns of all rows
        for row in rows:
            print(row[0], row[1], " ", row[3], ". ", row[4])

        select_query2 = "SELECT * FROM Dept"
        cur.execute(select_query2)
        row = cur.fetchone()
        while row is not None:
            print(row)
            row = cur.fetchone()

        select_query3 = "SELECT * FROM Emp WHERE empno = %(empno)s"
        emp_no = "000020"
        cur.execute(select_query3, {'empno':emp_no})
        rows = cur.fetchall()
        #print tthe first four columns of all rows
        for row in rows:
            print(row[0], row[1], " ", row[3], ". ", row[4])

        select_query4 = "SELECT * FROM Emp WHERE workdept = %(workdept)s AND salary > %(salary)f"
        work_dept = "A00"
        sal = 100000
        cur.execute(select_query4, {'workdept':work_dept, 'salary':sal})
        rows = cur.fetchall()
        #print tthe first four columns of all rows
        for row in rows:
            print(row[0], row[1], " ", row[3], ". ", row[4])
	
except mysql.connector.Error as err:
    print("Error while connecting to MySQL", err)   

finally:
    if conn.is_connected():
        cur.close()
        conn.close()
        print("MySQL connection is closed now")
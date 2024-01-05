/* Welcome to the SQL mini project. You will carry out this project partly in
the PHPMyAdmin interface, and partly in Jupyter via a Python connection.

This is Tier 2 of the case study, which means that there'll be less guidance for you about how to setup
your local SQLite connection in PART 2 of the case study. This will make the case study more challenging for you: 
you might need to do some digging, aand revise the Working with Relational Databases in Python chapter in the previous resource.

Otherwise, the questions in the case study are exactly the same as with Tier 1. 

PART 1: PHPMyAdmin
You will complete questions 1-9 below in the PHPMyAdmin interface. 
Log in by pasting the following URL into your browser, and
using the following Username and Password:

URL: https://sql.springboard.com/
Username: student
Password: learn_sql@springboard

The data you need is in the "country_club" database. This database
contains 3 tables:
    i) the "Bookings" table,
    ii) the "Facilities" table, and
    iii) the "Members" table.

In this case study, you'll be asked a series of questions. You can
solve them using the platform, but for the final deliverable,
paste the code for each solution into this script, and upload it
to your GitHub.

Before starting with the questions, feel free to take your time,
exploring the data, and getting acquainted with the 3 tables. */


/* QUESTIONS 
/* Q1: Some of the facilities charge a fee to members, but some do not.
Write a SQL query to produce a list of the names of the facilities that do. */

SELECT name 
FROM Facilities 
WHERE membercost > 0;

/* Q2: How many facilities do not charge a fee to members? */

SELECT name 
FROM Facilities 
WHERE membercost = 0;
/* 
4 facilities charge a fee to members.
*/

/* Q3: Write an SQL query to show a list of facilities that charge a fee to members,
where the fee is less than 20% of the facility's monthly maintenance cost.
Return the facid, facility name, member cost, and monthly maintenance of the
facilities in question. */

SELECT facid, name, membercost, monthlymaintenance
FROM Facilities
WHERE membercost> 0 AND membercost < .2*monthlymaintenance;

/*

There are 5 facilities. Tennis COurt 1, Tennis Court 2, Massage Room 1, Massage Room 2, Squash Court
*/

/* Q4: Write an SQL query to retrieve the details of facilities with ID 1 and 5.
Try writing the query without using the OR operator. */

SELECT *
FROM Facilities
WHERE facid IN (1,5);

/*
Two facilities - Tennis Court 2 and Massage Room 2
*/

/* Q5: Produce a list of facilities, with each labelled as
'cheap' or 'expensive', depending on if their monthly maintenance cost is
more than $100. Return the name and monthly maintenance of the facilities
in question. */

SELECT 
	name,
    monthlymaintenance,
    CASE	
    	WHEN monthlymaintenance > 100 THEN 'expensive'
    	ELSE 'cheap'
    END AS expense_label
FROM Facilities;

/* Q6: You'd like to get the first and last name of the last member(s)
who signed up. Try not to use the LIMIT clause for your solution. */

SELECT firstname, surname
FROM Members
WHERE joindate = (SELECT MAX(joindate) FROM Members);
/*
Darren Smith
*/

/* Q7: Produce a list of all members who have used a tennis court.
Include in your output the name of the court, and the name of the member
formatted as a single column. Ensure no duplicate data, and order by
the member name. */

SELECT DISTINCT
    CONCAT(m.firstname, ' ', m.surname) AS member_name,
    f.name AS court_name
FROM
    Bookings AS b
JOIN
    Facilities AS f ON b.facid = f.facid
JOIN
    Members AS m ON b.memid = m.memid
WHERE
    f.name LIKE 'Tennis%'
ORDER BY
    member_name;

/* Q8: Produce a list of bookings on the day of 2012-09-14 which
will cost the member (or guest) more than $30. Remember that guests have
different costs to members (the listed costs are per half-hour 'slot'), and
the guest user's ID is always 0. Include in your output the name of the
facility, the name of the member formatted as a single column, and the cost.
Order by descending cost, and do not use any subqueries. */

SELECT
    f.name AS facility_name,
    CONCAT(m.firstname, ' ', m.surname) AS member_name,
    CASE
        WHEN b.memid = 0 THEN f.guestcost * b.slots
        ELSE f.membercost * b.slots
    END AS cost
FROM
    Bookings AS b
JOIN
    Facilities AS f ON b.facid = f.facid
JOIN
    Members AS m ON b.memid = m.memid
WHERE
    b.starttime >= '2012-09-14' AND b.starttime < '2012-09-15'
    AND (
        (b.memid = 0 AND f.guestcost * b.slots > 30)
        OR (b.memid <> 0 AND f.membercost * b.slots > 30)
    )
ORDER BY
    cost DESC;

/* Q9: This time, produce the same result as in Q8, but using a subquery. */

SELECT
    facility_name,
    member_name,
    cost
FROM (
    SELECT
        f.name AS facility_name,
        CONCAT(m.firstname, ' ', m.surname) AS member_name,
        CASE
            WHEN b.memid = 0 THEN f.guestcost * b.slots
            ELSE f.membercost * b.slots
        END AS cost,
        ROW_NUMBER() OVER (ORDER BY CASE WHEN b.memid = 0 THEN f.guestcost * b.slots ELSE f.membercost * b.slots END DESC) AS row_num
    FROM
        Bookings AS b
    JOIN
        Facilities AS f ON b.facid = f.facid
    JOIN
        Members AS m ON b.memid = m.memid
    WHERE
        b.starttime >= '2012-09-14' AND b.starttime < '2012-09-15'
    ) AS subquery
WHERE
    cost > 30
ORDER BY
    cost DESC;

/* PART 2: SQLite

Export the country club data from PHPMyAdmin, and connect to a local SQLite instance from Jupyter notebook 
for the following questions.  

QUESTIONS:
/* Q10: Produce a list of facilities with a total revenue less than 1000.
The output of facility name and total revenue, sorted by revenue. Remember
that there's a different cost for guests and members! */

cursor.execute("""
    SELECT
        facility_name,
        total_revenue
    FROM (
        SELECT
            f.name AS facility_name,
            SUM(CASE WHEN b.memid = 0 THEN f.guestcost * b.slots ELSE f.membercost * b.slots END) AS total_revenue
        FROM
            Bookings AS b
        JOIN
            Facilities AS f ON b.facid = f.facid
        GROUP BY
            facility_name
    ) AS subquery
    WHERE
        total_revenue < 1000
    ORDER BY
        total_revenue;
""")
result = cursor.fetchall()
print(result)

/*
[('Table Tennis', 180), ('Snooker Table', 240), ('Pool Table', 270)]
*/

/* Q11: Produce a report of members and who recommended them in alphabetic surname,firstname order */

cursor.execute("""
    SELECT
        m.surname AS member_surname,
        m.firstname AS member_firstname,
        r.surname AS recommended_by_surname,
        r.firstname AS recommended_by_firstname
    FROM
        Members AS m
    LEFT JOIN
        Members AS r ON m.recommendedby = r.memid
    ORDER BY
        m.surname, m.firstname;
""")
result = cursor.fetchall()
print(result)

/*
[('Bader', 'Florence', 'Stibbons', 'Ponder'), ('Baker', 'Anne', 'Stibbons', 'Ponder'), ('Baker', 'Timothy', 'Farrell', 'Jemima'), ('Boothe', 'Tim', 'Rownam', 'Tim'), ('Butters', 'Gerald', 'Smith', 'Darren'), ('Coplin', 'Joan', 'Baker', 'Timothy'), ('Crumpet', 'Erica', 'Smith', 'Tracy'), ('Dare', 'Nancy', 'Joplette', 'Janice'), ('Farrell', 'David', None, None), ('Farrell', 'Jemima', None, None), ('GUEST', 'GUEST', None, None), ('Genting', 'Matthew', 'Butters', 'Gerald'), ('Hunt', 'John', 'Purview', 'Millicent'), ('Jones', 'David', 'Joplette', 'Janice'), ('Jones', 'Douglas', 'Jones', 'David'), ('Joplette', 'Janice', 'Smith', 'Darren'), ('Mackenzie', 'Anna', 'Smith', 'Darren'), ('Owen', 'Charles', 'Smith', 'Darren'), ('Pinker', 'David', 'Farrell', 'Jemima'), ('Purview', 'Millicent', 'Smith', 'Tracy'), ('Rownam', 'Tim', None, None), ('Rumney', 'Henrietta', 'Genting', 'Matthew'), ('Sarwin', 'Ramnaresh', 'Bader', 'Florence'), ('Smith', 'Darren', None, None), ('Smith', 'Darren', None, None), ('Smith', 'Jack', 'Smith', 'Darren'), ('Smith', 'Tracy', None, None), ('Stibbons', 'Ponder', 'Tracy', 'Burton'), ('Tracy', 'Burton', None, None), ('Tupperware', 'Hyacinth', None, None), ('Worthington-Smyth', 'Henry', 'Smith', 'Tracy')]
*/

/* Q12: Find the facilities with their usage by member, but not guests */

cursor.execute("""
    SELECT
        f.name AS facility_name,
        COUNT(b.memid) AS usage_by_members
    FROM
        Bookings AS b
    JOIN
        Facilities AS f ON b.facid = f.facid
    WHERE
        b.memid <> 0
    GROUP BY
        facility_name;
""")
result = cursor.fetchall()

/*

('Badminton Court', 344)
('Massage Room 1', 421)
('Massage Room 2', 27)
('Pool Table', 783)
('Snooker Table', 421)
('Squash Court', 195)
('Table Tennis', 385)
('Tennis Court 1', 308)
('Tennis Court 2', 276)

*/

/* Q13: Find the facilities usage by month, but not guests */

cursor.execute("""
    SELECT
        strftime('%Y-%m', b.starttime) AS month,
        f.name AS facility_name,
        COUNT(b.memid) AS usage_by_members
    FROM
        Bookings AS b
    JOIN
        Facilities AS f ON b.facid = f.facid
    WHERE
        b.memid <> 0
    GROUP BY
        month, facility_name
    ORDER BY
        month, facility_name;
""")
result = cursor.fetchall()

/*
('2012-07', 'Badminton Court', 51)
('2012-07', 'Massage Room 1', 77)
('2012-07', 'Massage Room 2', 4)
('2012-07', 'Pool Table', 103)
('2012-07', 'Snooker Table', 68)
('2012-07', 'Squash Court', 23)
('2012-07', 'Table Tennis', 48)
('2012-07', 'Tennis Court 1', 65)
('2012-07', 'Tennis Court 2', 41)
('2012-08', 'Badminton Court', 132)
('2012-08', 'Massage Room 1', 153)
('2012-08', 'Massage Room 2', 9)
('2012-08', 'Pool Table', 272)
('2012-08', 'Snooker Table', 154)
('2012-08', 'Squash Court', 85)
('2012-08', 'Table Tennis', 143)
('2012-08', 'Tennis Court 1', 111)
('2012-08', 'Tennis Court 2', 109)
('2012-09', 'Badminton Court', 161)
('2012-09', 'Massage Room 1', 191)
('2012-09', 'Massage Room 2', 14)
('2012-09', 'Pool Table', 408)
('2012-09', 'Snooker Table', 199)
('2012-09', 'Squash Court', 87)
('2012-09', 'Table Tennis', 194)
('2012-09', 'Tennis Court 1', 132)
('2012-09', 'Tennis Court 2', 126)
*/
--1.Create a table named ‘matches’ with appropriate data types for columns
CREATE TABLE matches(
    id INT PRIMARY KEY,
    city VARCHAR(40),
    date DATE,
    player_of_match VARCHAR(40),
    venue VARCHAR(80),
    neutral_venue INT,
    team1 VARCHAR(80),
    team2 VARCHAR(80),
    toss_winner VARCHAR(80),
    toss_decision VARCHAR(20),
    winner VARCHAR(80),
    result VARCHAR(40),
    result_margin INT,
    eliminator VARCHAR(10),
    method VARCHAR(10),
    umpire1 VARCHAR(40),
    umpire2 VARCHAR(40)
);

--2.Create a table named ‘deliveries’ with appropriate data types for columns
CREATE TABLE deliveries (
    id INT,
    inning INT,
    over INT,
    ball INT,
    batsman VARCHAR(40),
    non_striker VARCHAR(40),
    bowler VARCHAR(40),
    batsman_runs INT,
    extra_runs INT,
    total_runs INT,
    is_wicket INT,
    dismissal_kind VARCHAR(40),
    player_dismissed VARCHAR(40),
    fielder VARCHAR,
    extras_type VARCHAR(40),
    batting_team VARCHAR(40),
    bowling_team VARCHAR(40),
     FOREIGN KEY(id) REFERENCES matches(id)
);

--3.Import data from csv file ’IPL_matches.csv’ attached in resources to the table ‘matches’ which was created in Q1
COPY matches FROM 'C:\Program Files\PostgreSQL\16\data\Data_Copy\IPL_matches.csv' DELIMITER ',' CSV HEADER;

--4.Import data from csv file ’IPL_Ball.csv’ attached in resources to the table ‘deliveries’ which was created in Q2
COPY deliveries FROM 'C:\Program Files\PostgreSQL\16\data\Data_Copy\IPL_Ball.csv' DELIMITER ',' CSV HEADER;

--5.Select the top 20 rows of the deliveries table after ordering them by id, inning, over, ball in ascending order.
SELECT *
FROM deliveries
ORDER BY id, inning, over, ball
LIMIT 20;

--6.Select the top 20 rows of the matches table.
SELECT * FROM matches
LIMIT 20;

--7.Fetch data of all the matches played on 2nd May 2013 from the matches table.
SELECT * FROM matches WHERE date = '2013-05-02';

--8.Fetch data of all the matches where the result mode is ‘runs’ and margin of victory is more than 100 runs.
SELECT * FROM matches WHERE result = 'runs' AND result_margin > 100;

--9.Fetch data of all the matches where the final scores of both teams tied and order it in descending order of the date.
SELECT * FROM matches WHERE result = 'tie' ORDER BY date DESC;

--10.Get the count of cities that have hosted an IPL match.
SELECT COUNT(DISTINCT city) FROM matches;

/*11.	Create table deliveries_v02 with all the columns of the table ‘deliveries’ and 
an additional column ball_result containing values boundary, dot or other depending on the total_run (boundary for >= 4, dot for 0 and other for any other number)
(Hint 1 : CASE WHEN statement is used to get condition based results)
(Hint 2: To convert the output data of select statement into a table, you can use a subquery. 
Create table table_name as [entire select statement].)*/

CREATE TABLE deliveries_v02
AS SELECT *,
  CASE
     WHEN total_runs >=4 THEN 'boundary'
	 WHEN total_runs =0 THEN 'dot'
	 ELSE 'other'
  END AS ball_result
FROM deliveries;

--12.Write a query to fetch the total number of boundaries and dot balls from the deliveries_v02 table.
SELECT ball_result,
COUNT(*) FROM deliveries_v02
GROUP BY ball_result;

--13.Write a query to fetch the total number of boundaries scored by each team from the deliveries_v02 table and order it in descending order of the number of boundaries scored.
SELECT batting_team, COUNT(*)
FROM deliveries_v02
WHERE ball_result='boundary'
GROUP BY batting_team
ORDER BY COUNT DESC;

--14.Write a query to fetch the total number of dot balls bowled by each team and order it in descending order of the total number of dot balls bowled.
SELECT batting_team, COUNT(*)
FROM deliveries_v02
WHERE ball_result='dot'
GROUP BY batting_team
ORDER BY COUNT DESC;

--15.Write a query to fetch the total number of dismissals by dismissal kinds where dismissal kind is not NA
SELECT dismissal_kind, COUNT(is_wicket)
FROM deliveries
WHERE is_wicket=1
GROUP BY dismissal_kind
ORDER BY COUNT DESC;

--16.Write a query to get the top 5 bowlers who conceded maximum extra runs from the deliveries table
SELECT bowler, SUM(extra_runs) AS maximum_extra_runs
FROM deliveries
GROUP BY bowler
ORDER BY maximum_extra_runs DESC
LIMIT 5;

--17.Write a query to create a table named deliveries_v03 with all the columns of deliveries_v02 table and two additional column (named venue and match_date) of venue and date from table matches
CREATE TABLE deliveries_v03 AS SELECT a.* , b.venue , b.match_date
FROM deliveries_v02 AS a
LEFT JOIN(SELECT MAX(venue) AS venue ,MAX(date) AS match_date, id FROM matches GROUP BY id) AS b
ON a.id=b.id;

--18.Write a query to fetch the total runs scored for each venue and order it in the descending order of total runs scored.
SELECT venue , SUM(total_runs) AS runs
FROM deliveries_v03
GROUP BY venue
ORDER BY runs DESC;

--19.Write a query to fetch the year-wise total runs scored at Eden Gardens and order it in the descending order of total runs scored.
SELECT EXTRACT(YEAR FROM match_date) AS years,
SUM(total_runs) AS runs
FROM deliveries_v03
WHERE venue='Eden Gardens'
GROUP BY years
ORDER BY runs DESC;

/*20.Get unique team1 names from the matches table, 
you will notice that there are two entries for Rising Pune Supergiant one with Rising Pune Supergiant and another one with Rising Pune Supergiants.  
Your task is to create a matches_corrected table with two additional columns team1_corr and team2_corr containing team names with replacing Rising Pune Supergiants with Rising Pune Supergiant. 
Now analyse these newly created columns.*/
SELECT DISTINCT team1 FROM matches;

CREATE TABLE matches_corrected AS SELECT *,
REPLACE(team1,'Rising Pune Supergaints','Rising Pune Supergaint') AS team1_corr,
REPLACE(team2,'Rising Pune Supergaints','Rising Pune Supergaint') AS team2_corr
FROM matches;

/*21.	Create a new table deliveries_v04 with the first column as ball_id containing information of match_id, inning, over and ball separated by ‘-’ 
--(For ex. 335982-1-0-1 match_id-inning-over-ball) and rest of the columns same as deliveries_v03)*/
CREATE TABLE deliveries_v04
AS SELECT concat(id,'-',inning,'-',over,'-',ball)
AS ball_id , * FROM deliveries_v03;

SELECT * FROM deliveries_v04;
--22.Compare the total count of rows and total count of distinct ball_id in deliveries_v04;
--select count(distinct ball_id) from deliveries_v04;

--select count(*) from deliveries_v04;

SELECT COUNT(id) - COUNT(DISTINCT ball_id) FROM deliveries_v04; 

/*23.SQL Row_Number() function is used to sort and assign row numbers to data rows in the presence of multiple groups. 
For example, to identify the top 10 rows which have the highest order amount in each region, we can use row_number to assign row numbers in each group (region) with any particular order (decreasing order of order amount) and then we can use this new column to apply filters. 
Using this knowledge, solve the following exercise. 
You can use hints to create an additional column of row number.
Create table deliveries_v05 with all columns of deliveries_v04 and an additional column for row number partition over ball_id. (HINT : Syntax to add along with other columns,  row_number() over (partition by ball_id) as r_num)*/

CREATE TABLE deliveries_v05 AS SELECT * ,
row_number() OVER (PARTITION BY ball_id) AS r_num
FROM deliveries_v04;

--24.Use the r_num created in deliveries_v05 to identify instances where ball_id is repeating. (HINT : select * from deliveries_v05 WHERE r_num=2;)
SELECT * FROM deliveries_v05 WHERE r_num=2;

--25.Use subqueries to fetch data of all the ball_id which are repeating. (HINT: SELECT * FROM deliveries_v05 WHERE ball_id in (select BALL_ID from deliveries_v05 WHERE r_num=2);
SELECT * FROM deliveries_v05 WHERE ball_id IN (SELECT BALL_ID FROM deliveries_v05 WHERE r_num=2);
/*

Question 1

Show only the top 5 rows from the trading.members table.

*/

SELECT
  members.member_id,
  members.first_name,
  members.region
FROM trading.members
LIMIT 5;

/*

Question 2

Sort all the rows in the table by first_name in alphabetical order and show the top 3 rows.

*/

SELECT
  members.member_id,
  members.first_name,
  members.region
FROM trading.members
ORDER BY members.first_name
LIMIT 3;

/*

Question 3

Which records from trading.members are from the United States region?

*/

SELECT
  members.member_id,
  members.first_name,
  members.region
FROM trading.members
WHERE members.region = 'United States';

/*

Question 4

Select only the member_id and first_name columns for members who are not from Australia.

*/

SELECT
  members.member_id,
  members.first_name
FROM trading.members
WHERE members.region <> 'Australia';

/*

Question 5

Return the unique region values from the trading.members table and sort the output by reverse alphabetical order.

*/

SELECT DISTINCT members.region
FROM trading.members
ORDER BY region DESC;

/*

Question 6

How many mentors are there from Australia or the United States?

*/

SELECT
  COUNT(members.member_id) as mentor_count
FROM trading.members
WHERE region IN ('United States', 'Australia');

/*

Question 7

How many mentors are there not from Australia or the United States?

*/

SELECT
  COUNT(members.member_id) as mentor_count
FROM trading.members
WHERE region NOT IN ('United States', 'Australia');

/*

Question 8

How many mentors are there per region? Sort the output by regions with the most mentors to the least.

*/

SELECT
  members.region,
  COUNT(members.member_id) as mentor_count
FROM trading.members
GROUP BY members.region
ORDER BY mentor_count DESC;

/*

Question 9

How many US mentors and non US mentors are there?

*/

SELECT
  CASE WHEN members.region <> 'United States' THEN 'Non US' ELSE members.region END AS mentor_region,
  COUNT(members.member_id) as mentor_count
FROM trading.members
GROUP BY mentor_region
ORDER BY mentor_count DESC;

/*

Question 10

How many mentors have a first name starting with a letter before 'E'?

*/

SELECT
  COUNT(members.member_id) as mentor_count
FROM trading.members
WHERE LEFT(members.first_name, 1) < 'E';

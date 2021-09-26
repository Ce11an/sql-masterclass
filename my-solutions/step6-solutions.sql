/*

Step 1

Create a base table that has each mentor's name, region and end of year total quantity for each ticker.

*/

DROP TABLE IF EXISTS temp_portfolio_base;
CREATE TEMP TABLE temp_portfolio_base AS
WITH cte_joined_data AS (
  SELECT
    members.first_name,
    members.region,
    transactions.txn_date,
    transactions.ticker,
    CASE WHEN transactions.txn_type = 'BUY' THEN transactions.quantity ELSE -transactions.quantity END AS adjusted_quantity
  FROM trading.transactions
  INNER JOIN trading.members
    ON transactions.member_id = members.member_id
  WHERE transactions.txn_date <= '2020-12-31'
)
SELECT
  cte_joined_data.first_name,
  cte_joined_data.region,
  (DATE_TRUNC('YEAR', cte_joined_data.txn_date) + INTERVAL '12 MONTHS' - INTERVAL '1 DAY')::DATE AS year_end,
  cte_joined_data.ticker,
  SUM(cte_joined_data.adjusted_quantity) AS yearly_quantity
FROM cte_joined_data
GROUP BY cte_joined_data.first_name, cte_joined_data.region, year_end, cte_joined_data.ticker;

/*

Step 2

Inspect the year_end, ticker and yearly_quantity values from our new temp table temp_portfolio_base for Mentor Abe only.
Sort the output with ordered BTC values followed by ETH values.

*/

SELECT
  temp_portfolio_base.year_end,
  temp_portfolio_base.ticker,
  temp_portfolio_base.yearly_quantity
FROM temp_portfolio_base
WHERE temp_portfolio_base.first_name = 'Abe'
ORDER BY temp_portfolio_base.ticker, temp_portfolio_base.year_end;

/*

Step 3

Create a cumulative sum for Abe which has an independent value for each ticker.

*/

SELECT
  temp_portfolio_base.year_end,
  temp_portfolio_base.ticker,
  temp_portfolio_base.yearly_quantity,
  SUM(temp_portfolio_base.yearly_quantity) OVER (
    PARTITION BY temp_portfolio_base.first_name, temp_portfolio_base.ticker
    ORDER BY temp_portfolio_base.year_end
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS cumulative_quantity
FROM temp_portfolio_base
WHERE temp_portfolio_base.first_name = 'Abe'
ORDER BY temp_portfolio_base.ticker, temp_portfolio_base.year_end;

/*

Step 4

Generate an additional cumulative_quantity column for the temp_portfolio_base temp table.

*/

-- add a column called cumulative_quantity
ALTER TABLE temp_portfolio_base
ADD cumulative_quantity NUMERIC;

-- update new column with data
UPDATE temp_portfolio_base
SET (cumulative_quantity) = (
  SELECT
      SUM(temp_portfolio_base.yearly_quantity) OVER (
    PARTITION BY temp_portfolio_base.first_name, temp_portfolio_base.ticker
    ORDER BY temp_portfolio_base.year_end
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  )
);

/*

NOTES:

it didn't work - the cumulative and the yearly quantity is exactly the same!

This is because our UPDATE step only takes into account a single row at a time, which is exactly what we must not do with our window functions!

We will need to create an additional temp table with our cumulative sum instead!

Run the following for all future queries!

*/

DROP TABLE IF EXISTS temp_cumulative_portfolio_base;
CREATE TEMP TABLE temp_cumulative_portfolio_base AS
SELECT
  temp_portfolio_base.first_name,
  temp_portfolio_base.region,
  temp_portfolio_base.year_end,
  temp_portfolio_base.ticker,
  temp_portfolio_base.yearly_quantity,
  SUM(temp_portfolio_base.yearly_quantity) OVER (
    PARTITION BY temp_portfolio_base.first_name, temp_portfolio_base.ticker
    ORDER BY temp_portfolio_base.year_end
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS cumulative_quantity
FROM temp_portfolio_base;

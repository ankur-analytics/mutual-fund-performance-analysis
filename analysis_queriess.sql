-- ============================================================
-- PROJECT  : Mutual Fund Performance Analysis
-- AUTHOR   : Ankur Kumar Singh
-- TOOL     : MySQL
-- DATASET  : Mutual Funds India - Detailed (Kaggle)
-- GITHUB   : github.com/ankur-analytics
-- ============================================================
-- OBJECTIVE: Analyze 1000+ Indian mutual fund schemes to identify
--            performance patterns, risk-return tradeoffs, and
--            AMC-wise comparisons using SQL
-- ============================================================


-- ============================================================
-- BLOCK 1 : BASIC EXPLORATION & DATA QUALITY CHECK
-- ============================================================

-- Total number of funds in dataset
SELECT COUNT(*) as total_funds 
FROM mutual_funds;

-- Fund count by category
SELECT category, COUNT(*) as fund_count
FROM mutual_funds
GROUP BY category
ORDER BY fund_count DESC;

-- Null check on return columns
SELECT 
  SUM(CASE WHEN returns_1yr IS NULL THEN 1 ELSE 0 END) as null_1yr,
  SUM(CASE WHEN returns_3yr IS NULL THEN 1 ELSE 0 END) as null_3yr,
  SUM(CASE WHEN returns_5yr IS NULL THEN 1 ELSE 0 END) as null_5yr
FROM mutual_funds;


-- ============================================================
-- BLOCK 2 : PERFORMANCE ANALYSIS
-- ============================================================

-- Average returns by category (1yr, 3yr, 5yr)
SELECT category, 
       ROUND(AVG(returns_1yr),2) as avg_1yr,
       ROUND(AVG(returns_3yr),2) as avg_3yr,
       ROUND(AVG(returns_5yr),2) as avg_5yr
FROM mutual_funds
GROUP BY category
ORDER BY avg_5yr DESC;

-- Top 10 funds by 5yr returns
SELECT scheme_name, category, returns_5yr
FROM mutual_funds
WHERE returns_5yr IS NOT NULL
ORDER BY returns_5yr DESC
LIMIT 10;

-- Bottom 10 funds by 5yr returns (worst performers)
SELECT scheme_name, category, returns_5yr
FROM mutual_funds
WHERE returns_5yr IS NOT NULL
ORDER BY returns_5yr ASC
LIMIT 10;


-- ============================================================
-- BLOCK 3 : RISK ANALYSIS
-- ============================================================

-- Average risk metrics by category
SELECT category,
       ROUND(AVG(sharpe),2)  as avg_sharpe,
       ROUND(AVG(sortino),2) as avg_sortino,
       ROUND(AVG(alpha),2)   as avg_alpha
FROM mutual_funds
GROUP BY category
ORDER BY avg_sharpe DESC;

-- Funds with excellent Sharpe ratio (above 1 = great risk-adjusted return)
SELECT scheme_name, category, sharpe, returns_5yr
FROM mutual_funds
WHERE sharpe > 1
ORDER BY sharpe DESC;

-- Worst funds — high risk level but low returns (avoid these)
SELECT scheme_name, risk_level, returns_3yr, expense_ratio
FROM mutual_funds
WHERE risk_level = 5 AND returns_3yr < 10
ORDER BY returns_3yr ASC;


-- ============================================================
-- BLOCK 4 : EXPENSE RATIO IMPACT
-- ============================================================

-- Does higher expense ratio hurt returns?
SELECT 
  CASE 
    WHEN expense_ratio < 0.5 THEN 'Low (below 0.5)'
    WHEN expense_ratio BETWEEN 0.5 AND 1.5 THEN 'Medium (0.5 to 1.5)'
    ELSE 'High (above 1.5)'
  END as expense_bucket,
  ROUND(AVG(returns_5yr),2) as avg_5yr_return,
  COUNT(*) as fund_count
FROM mutual_funds
WHERE returns_5yr IS NOT NULL
GROUP BY expense_bucket
ORDER BY avg_5yr_return DESC;


-- ============================================================
-- BLOCK 5 : AMC ANALYSIS
-- ============================================================

-- Top 10 AMCs by number of funds managed
SELECT amc_name, COUNT(*) as fund_count
FROM mutual_funds
GROUP BY amc_name
ORDER BY fund_count DESC
LIMIT 10;

-- Top 10 AMCs by average 5yr returns
SELECT amc_name,
       ROUND(AVG(returns_5yr),2)   as avg_5yr,
       ROUND(AVG(rating),2)        as avg_rating,
       ROUND(AVG(expense_ratio),2) as avg_expense
FROM mutual_funds
WHERE returns_5yr IS NOT NULL
GROUP BY amc_name
ORDER BY avg_5yr DESC
LIMIT 10;


-- ============================================================
-- BLOCK 6 : ADVANCED QUERIES (WINDOW FUNCTIONS)
-- ============================================================

-- Rank funds within each category by 5yr returns
SELECT scheme_name, category, returns_5yr,
       RANK() OVER (PARTITION BY category ORDER BY returns_5yr DESC) as rank_in_category
FROM mutual_funds
WHERE returns_5yr IS NOT NULL;

-- Funds that beat their category average (outperformers)
SELECT scheme_name, category, returns_5yr,
       ROUND(AVG(returns_5yr) OVER (PARTITION BY category), 2) as category_avg,
       ROUND(returns_5yr - AVG(returns_5yr) OVER (PARTITION BY category), 2) as outperformance
FROM mutual_funds
WHERE returns_5yr IS NOT NULL
ORDER BY outperformance DESC
LIMIT 20;
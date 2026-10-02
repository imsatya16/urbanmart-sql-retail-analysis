-- ============================================================
-- UrbanMart Retail Operations Analysis
-- Stage 3: INSIGHTS  -  "What should we do about it?"  (Q16-Q20)
-- Author: Satyabrata Sahoo | MySQL 8
--
-- Each question has the main query, plus a supporting query (b)
-- that backs up the recommendation written in the README.
-- ============================================================

USE urbanmart;

-- Q16. Which store needs urgent replenishment, and what is the business risk?
--      Stores ranked by number of products below 10 units (incl. stock-outs).
SELECT
    s.store_name,
    COUNT(*) AS critical_stock_items
FROM inventory i
JOIN stores s
    ON i.store_id = s.store_id
WHERE i.stock_quantity < 10
GROUP BY s.store_name
ORDER BY critical_stock_items DESC;

-- Q16b. Tie-breaker: three stores have 3 critical items each.
--       How much of each store's revenue came from the items that are now
--       out of stock or low? That is the revenue at risk if nothing is restocked.
SELECT
    s.store_name,
    SUM(i.stock_quantity = 0)              AS out_of_stock,
    SUM(i.stock_quantity BETWEEN 1 AND 9)  AS low_stock,
    COALESCE(SUM(ir.item_revenue), 0)      AS revenue_from_critical_items,
    sr.store_revenue,
    ROUND(100 * COALESCE(SUM(ir.item_revenue), 0) / sr.store_revenue, 1) AS pct_revenue_at_risk
FROM inventory i
JOIN stores s
    ON i.store_id = s.store_id
JOIN (SELECT store_id, SUM(total_amount) AS store_revenue      -- total revenue per store
      FROM transactions
      GROUP BY store_id) sr
    ON i.store_id = sr.store_id
LEFT JOIN (SELECT store_id, product_id,                          -- revenue per product per store
                  SUM(total_amount) AS item_revenue
           FROM transactions
           GROUP BY store_id, product_id) ir
    ON i.store_id = ir.store_id
   AND i.product_id = ir.product_id
WHERE i.stock_quantity < 10
GROUP BY s.store_name, sr.store_revenue
ORDER BY pct_revenue_at_risk DESC;

-- Q17. Which region is the best performer and which is the weakest?
SELECT
    s.region,
    SUM(t.total_amount) AS revenue
FROM stores s
JOIN transactions t
    ON s.store_id = t.store_id
GROUP BY s.region
ORDER BY revenue DESC;

-- Q17b. Why? Compare transaction count, average ticket size and
--       the share of revenue coming from low-priced Groceries.
SELECT
    s.region,
    COUNT(*)                         AS transactions,
    SUM(t.total_amount)              AS revenue,
    ROUND(AVG(t.total_amount), 2)    AS avg_ticket,
    ROUND(100 * SUM(CASE WHEN p.category = 'Groceries' THEN t.total_amount ELSE 0 END)
              / SUM(t.total_amount), 1) AS grocery_share_pct
FROM transactions t
JOIN stores s
    ON t.store_id = s.store_id
JOIN products p
    ON t.product_id = p.product_id
GROUP BY s.region
ORDER BY revenue DESC;

-- Q18. Identify the top-performing employee by sales.
SELECT
    e.employee_name,
    SUM(t.total_amount) AS total_sales
FROM transactions t
JOIN employees e
    ON t.employee_id = e.employee_id
GROUP BY e.employee_name
ORDER BY total_sales DESC
LIMIT 1;

-- Q18b. How close is the race? Top 3 sellers with transactions and average ticket.
SELECT
    e.employee_name,
    s.store_name,
    COUNT(*)                      AS transactions,
    SUM(t.total_amount)           AS total_sales,
    ROUND(AVG(t.total_amount), 2) AS avg_ticket
FROM transactions t
JOIN employees e
    ON t.employee_id = e.employee_id
JOIN stores s
    ON e.store_id = s.store_id
GROUP BY e.employee_name, s.store_name
ORDER BY total_sales DESC
LIMIT 3;

-- Q19. Which supplier is the most valuable business partner?
SELECT
    sp.supplier_name,
    SUM(t.total_amount) AS revenue_generated
FROM transactions t
JOIN products p
    ON t.product_id = p.product_id
JOIN suppliers sp
    ON p.supplier_id = sp.supplier_id
GROUP BY sp.supplier_name
ORDER BY revenue_generated DESC
LIMIT 1;

-- Q19b. Each supplier's share of total chain revenue.
SELECT
    sp.supplier_name,
    SUM(t.total_amount) AS revenue_generated,
    ROUND(100 * SUM(t.total_amount)
              / (SELECT SUM(total_amount) FROM transactions), 1) AS share_pct
FROM transactions t
JOIN products p
    ON t.product_id = p.product_id
JOIN suppliers sp
    ON p.supplier_id = sp.supplier_id
GROUP BY sp.supplier_name
ORDER BY revenue_generated DESC;

-- Q20. ONE key recommendation for the QBR.
--      Supporting query: how widespread is the stock problem across the chain?
SELECT
    COUNT(DISTINCT CASE WHEN stock_quantity = 0 THEN store_id END) AS stores_with_a_stockout,
    COUNT(DISTINCT store_id)                                       AS total_stores,
    SUM(stock_quantity < 10)                                       AS product_store_lines_below_10,
    COUNT(*)                                                       AS total_product_store_lines,
    ROUND(100 * SUM(stock_quantity < 10) / COUNT(*), 1)            AS pct_lines_below_10
FROM inventory;

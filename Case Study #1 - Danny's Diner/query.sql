-- 1 What is the total amount each customer spent at the restaurant?
select s.customer_id,sum(m.price) as Total_Spent
from sales s
join menu m
on s.product_id=m.product_id
group by s.customer_id;

-- 2 How many days has each customer visited the restaurant?
select customer_id, count(distinct(order_date)) as visit_days
from sales
group by customer_id;

-- 3 What was the first item from the menu purchased by each customer?
select s.customer_id, min(s.order_date) as first_order_date,
(select m.product_name from sales s2 
join menu m 
on s2.product_id=m.product_id
where s.customer_id=s2.customer_id
order by s2.order_date asc, s2.product_id limit 1 ) as first_item
from sales s
GROUP BY s.customer_id
ORDER BY s.customer_id;
-- another method
SELECT 
    s.customer_id,
    s.order_date,
    m.product_name
FROM sales s
JOIN menu m 
    ON s.product_id = m.product_id
WHERE s.order_date = (
    SELECT MIN(order_date)
    FROM sales
    WHERE customer_id = s.customer_id
)
ORDER BY s.customer_id, s.order_date;

-- 4 What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT m.product_name, COUNT(s.product_id) AS total_purchases
FROM sales s
JOIN menu m
  ON s.product_id = m.product_id
GROUP BY m.product_name
ORDER BY total_purchases DESC
LIMIT 1;
-- 5 Which item was the most popular for each customer?
  WITH customer_orders AS (
    SELECT 
        s.customer_id,
        m.product_name,
        COUNT(s.product_id) AS order_count
    FROM sales s
    JOIN menu m 
        ON s.product_id = m.product_id
    GROUP BY s.customer_id, m.product_name
),
ranked_orders AS (
    SELECT 
        customer_id,
        product_name,
        order_count,
        RANK() OVER(PARTITION BY customer_id ORDER BY order_count DESC) AS rnk
    FROM customer_orders
)
SELECT customer_id, product_name, order_count
FROM ranked_orders
WHERE rnk = 1;

-- 6 Which item was purchased first by the customer after they became a member?
SELECT s.customer_id,
       m.product_name,
       s.order_date
FROM sales s
JOIN menu m
  ON s.product_id = m.product_id
JOIN members mem
  ON s.customer_id = mem.customer_id
WHERE s.order_date >= mem.join_date
  AND s.order_date = (
      SELECT MIN(s2.order_date)
      FROM sales s2
      WHERE s2.customer_id = s.customer_id
        AND s2.order_date >= mem.join_date
  );

-- 7 Which item was purchased just before the customer became a member?
SELECT s.customer_id,
       m.product_name,
       s.order_date
FROM sales s
JOIN menu m
  ON s.product_id = m.product_id
JOIN members mem
  ON s.customer_id = mem.customer_id
WHERE s.order_date < mem.join_date
  AND s.order_date = (
      SELECT MAX(s2.order_date)
      FROM sales s2
      WHERE s2.customer_id = s.customer_id
        AND s2.order_date < mem.join_date
  );


-- 8 What is the total items and amount spent for each member before they became a member?
SELECT 
    s.customer_id,
    COUNT(s.product_id) AS total_items,
    SUM(m.price) AS total_amount
FROM sales s
JOIN menu m
  ON s.product_id = m.product_id
JOIN members mem
  ON s.customer_id = mem.customer_id
WHERE s.order_date < mem.join_date
GROUP BY s.customer_id;

-- 9 If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT 
  s.customer_id,
  SUM(CASE 
        WHEN m.product_name = 'sushi' THEN m.price * 20
        ELSE m.price * 10
      END) AS points
FROM sales s
JOIN menu m
  ON s.product_id = m.product_id
GROUP BY s.customer_id
ORDER BY s.customer_id;

-- 10 In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi how many points do customer A and B have at the end of January?
    SELECT 
    s.customer_id,
    SUM(
      CASE 
        WHEN s.order_date BETWEEN mem.join_date AND DATE_ADD(mem.join_date, INTERVAL 6 DAY) 
             THEN m.price * 20
        WHEN m.product_name = 'sushi' 
             THEN m.price * 20
        ELSE m.price * 10
      END
    ) AS total_points
FROM sales s
JOIN menu m
  ON s.product_id = m.product_id
JOIN members mem
  ON s.customer_id = mem.customer_id
WHERE s.order_date <= '2021-01-31'
GROUP BY s.customer_id
ORDER BY s.customer_id;

-- Bonus Questions
-- Join All The Things
-- The following questions are related creating basic data tables that Danny and his team can use to quickly derive insights without needing to join the underlying tables using SQL.

SELECT 
    s.customer_id,
    s.order_date,
    m.product_name,
    m.price,
    CASE 
        WHEN s.order_date >= mem.join_date THEN 'Y'
        ELSE 'N'
    END AS member
FROM sales s
JOIN menu m
  ON s.product_id = m.product_id
LEFT JOIN members mem
  ON s.customer_id = mem.customer_id
ORDER BY s.customer_id, s.order_date;

-- Danny also requires further information about the ranking of customer products, but he purposely does not need the ranking for non-member purchases so he expects null ranking values for the records when customers are not yet part of the loyalty program.
WITH joined AS (
    SELECT 
        s.customer_id,
        s.order_date,
        m.product_name,
        m.price,
        CASE 
            WHEN s.order_date >= mem.join_date THEN 'Y'
            ELSE 'N'
        END AS member
    FROM sales s
    JOIN menu m
      ON s.product_id = m.product_id
    LEFT JOIN members mem
      ON s.customer_id = mem.customer_id
)
SELECT 
    customer_id,
    order_date,
    product_name,
    price,
    member,
    CASE 
        WHEN member = 'Y' THEN 
            RANK() OVER (
                PARTITION BY customer_id, member
                ORDER BY order_date
            )
    END AS ranking
FROM joined
ORDER BY customer_id, order_date;


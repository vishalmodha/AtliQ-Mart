/*1.list of products with base_price > 500 and promo_type = 'BOGOF'*/
SELECT DISTINCT product_name, base_price, promo_type
FROM retail_events_db.dim_products 
JOIN fact_events ON dim_products.product_code = fact_events.product_code
WHERE base_price > 500 AND promo_type = 'BOGOF';

/*2.Report that provides overview of the number of stores in each city*/
SELECT city, COUNT(store_id) AS store_count
FROM dim_stores
GROUP BY city;

/*3.Report showing campaign and revenue generated before and after campaign.*/
SELECT
    campaign_name,
    SUM(`quantity_sold(before_promo)` * base_price) / 1000000 AS total_revenue_before_promo,
    SUM(`quantity_sold(after_promo)` * base_price) / 1000000 AS total_revenue_after_promo
FROM dim_campaigns
JOIN fact_events ON dim_campaigns.campaign_id = fact_events.campaign_id
GROUP BY dim_campaigns.campaign_name;

/*4.Report that calculates Incremental Sold Quantity (ISU%) for each category during Diwali.*/
WITH DiwaliSales AS (
    SELECT
        category,
        SUM(
            (`quantity_sold(after_promo)` - `quantity_sold(before_promo)`) /
            (`quantity_sold(before_promo)`)
        ) AS isu_percentage
    FROM dim_products
    JOIN fact_events ON dim_products.product_code = fact_events.product_code
    JOIN dim_campaigns ON fact_events.campaign_id = dim_campaigns.campaign_id
    WHERE dim_campaigns.campaign_name = 'Diwali'
    GROUP BY dim_products.category
)

SELECT
    category,
    isu_percentage,
    RANK() OVER (ORDER BY isu_percentage DESC) AS rank_order
FROM DiwaliSales;

/*5.Report featuring top 5 products ranked by IR% across all campaigns.*/
WITH IRPercentage AS (
    SELECT
        product_name,
        category,
        ((SUM(fact_events.`quantity_sold(after_promo)`)) - SUM(fact_events.`quantity_sold(before_promo)`)) / SUM(fact_events.`quantity_sold(before_promo)`) AS ir_percentage
    FROM dim_products
    JOIN fact_events ON dim_products.product_code = fact_events.product_code
    GROUP BY dim_products.product_name, dim_products.category
)

SELECT
    product_name,
    category,
    ir_percentage
FROM IRPercentage
ORDER BY ir_percentage DESC
LIMIT 5;
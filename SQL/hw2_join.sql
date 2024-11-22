-- Часть 1
-- 1.1
-- Объединяю таблицы "Customers"и "Orders" по customer_id.
-- Выбираю клиентов, у которого самое долгое время ожидания между заказом и доставкой. 
SELECT DISTINCT customers.name,
       shipment_date::TIMESTAMP - order_date::TIMESTAMP as delivery_time
FROM orders_new_3 orders
INNER JOIN customers_new_3 customers ON orders.customer_id = customers.customer_id
WHERE (shipment_date::TIMESTAMP - order_date::TIMESTAMP) = (
        SELECT MAX(shipment_date::TIMESTAMP - order_date::TIMESTAMP)
        FROM orders_new_3
	)
ORDER BY customers.name;
    
-- 1.2
-- Объединяю таблицы "Customers"и "Orders" по customer_id.
-- Выбираю клиентов (customer_id, name) с наибольшим количеством заказов (order_count), 
-- среднее время между заказом и доставкой (avg_delivery) и сумму всех их заказов (total_order_amount).
-- Вывожу клиентов в порядке убывания общей суммы заказов клиента.
 SELECT DISTINCT customers.customer_id as customer_id,
	customers.name as customer_name, 
        COUNT(orders.customer_id) AS order_count,
	AVG(shipment_date::TIMESTAMP - order_date::TIMESTAMP) as avg_delivery, 
        sum(order_ammount) AS total_order_amount
FROM orders_new_3 orders
INNER JOIN customers_new_3 customers ON orders.customer_id = customers.customer_id
GROUP BY customers.customer_id, customers.name
HAVING COUNT(orders.order_id) = (
    SELECT MAX(order_counts)
    FROM (
        SELECT COUNT(orders.order_id) AS order_counts
        FROM orders_new_3 orders
        GROUP BY orders.customer_id
    )
)
ORDER BY total_order_amount DESC;

-- 1.3
--Выбираю клиентов, у которых были заказы, доставленные с задержкой более чем на 5 дней, и клиентов, у которых были отмененные заказы. 
-- Для каждого клиента вывожу id (customer_id) и имя (customer_name), количество доставок с задержкой (delayed_orders), количество отмененных заказов (canceled_orders), 
-- общую сумму отмененных заказов (total_ammount_cancel) и общую сумму (total_orders_ammount). 
-- Результат сортирую по общей сумме заказов в убывающем порядке.
SELECT customers.customer_id, 
       customers.name as customer_name, 
COUNT(CASE WHEN shipment_date::TIMESTAMP - order_date::TIMESTAMP > '5 days' THEN 1 ELSE 0 END) delayed_orders,
COUNT(CASE WHEN orders.order_status = 'Cancel' THEN 1 ELSE 0 END) canceled_orders,
SUM(CASE WHEN orders.order_status = 'Cancel' THEN orders.order_ammount ELSE 0 END) canceled_ammount,
SUM(orders.order_ammount) AS orders_ammount
FROM orders_new_3 orders
INNER JOIN customers_new_3 customers ON orders.customer_id = customers.customer_id
GROUP BY customers.customer_id, customers.name
HAVING COUNT(CASE WHEN shipment_date::TIMESTAMP - order_date::TIMESTAMP > '5 days' THEN 1 ELSE 0 END) > 0
    OR COUNT(CASE WHEN orders.order_status = 'Cancel' THEN 1 ELSE 0 END) > 0
ORDER BY orders_ammount DESC;

-- Часть 2
--CTE product_categories: вычисляю общую сумму продаж для каждой категории.
WITH product_categories AS (
    SELECT 
        products_3.product_category, 
        SUM(orders_2.order_ammount) AS total_sales_amount
    FROM products_3 
    JOIN orders_2 ON products_3.product_id = orders_2.product_id
    GROUP BY products_3.product_category
),
-- CTE product_sales: вычисляю сумму продаж для каждого продукта в каждой категории.
product_sales AS (
    SELECT 
        products_3.product_name, 
        products_3.product_category, 
        SUM(orders_2.order_ammount) AS total_product_sales
    FROM products_3 
    JOIN orders_2 ON products_3.product_id = orders_2.product_id
    GROUP BY products_3.product_name, products_3.product_category
)
-- Из CTE product_categories выбираю категории (product_category) и общую сумму продаж внутри каждой категории (total_sales_amount).
SELECT 
    product_categories.product_category, 
    product_categories.total_sales_amount,
-- Выбираю категорию с наибольшей суммой продаж (best_selling_category).
    (
        SELECT product_categories.product_category
        FROM product_categories
        ORDER BY product_categories.total_sales_amount DESC
        LIMIT 1
    ) AS best_selling_category,
-- Из CTE product_sales выбираю самый продаваемый продукт для каждой категории
    (
        SELECT product_sales.product_name
        FROM product_sales
        WHERE product_sales.product_category = product_categories.product_category
        ORDER BY product_sales.total_product_sales DESC 
        LIMIT 1
    ) AS top_selling_product
FROM product_categories;

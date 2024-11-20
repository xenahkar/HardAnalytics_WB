-- Часть 1
-- 1.1
-- Для каждого города (city) вывожу число покупателей из таблицы users, сгруппированных по возрастным категориям (age_category) и отсортированных по убыванию количества покупателей (customer_count).
SELECT 
    city,
    CASE 
        WHEN age BETWEEN 0 AND 20 THEN 'young'
        WHEN age BETWEEN 21 AND 49 THEN 'adult'
        WHEN age >= 50 THEN 'old'
    END AS age_category,
    COUNT(*) AS customer_count
FROM 
    users
GROUP BY 
    city, age_category
ORDER BY 
    customer_count desc;

 -- 1.2
-- Из таблицы products выбираю категории продуктов (category) и среднюю цену (avg_price), округленную до двух знаков после запятой. 
-- Фильтрую записи, чтобы оставить только те, где название продукта содержит "hair" или "home" (независимо от регистра). Результаты группируются по категориям.
SELECT 
	category,
	ROUND(AVG(price), 2) avg_price
FROM products 
WHERE 
	LOWER(name) LIKE '%hair%' OR 
	LOWER(name) LIKE '%home%'
GROUP BY category;

-- Часть 2
-- 2.1
-- Выбираю столбцы seller_id, общее количество уникальных категорий (total_categ), средний рейтинг (avg_rating), общий доход (total_revenue) и тип продавца (seller_type).
-- Оставляю только тех продавцов, у которых больше одной уникальной категории category. Категорию “Bedding” не учитываю в расчетах.
SELECT 
    seller_id, 
    COUNT(DISTINCT category) AS total_categ, 
    ROUND(AVG(rating), 2) AS avg_rating, 
    SUM(revenue) AS total_revenue,
    CASE 
        WHEN SUM(revenue) > 50000 THEN 'rich'
        ELSE 'poor' 
    END AS seller_type
FROM sellers
WHERE category != 'Bedding'
GROUP BY seller_id
HAVING COUNT(DISTINCT category) > 1
ORDER BY seller_id;

-- 2.2
-- CTE sellers_info: собираем информацию о продавцах (seller_id, количество уникальных категорий, общую выручку, тип продавца), торгующих более чем в одной категории, исключая категорию 'Bedding'.
WITH sellers_info AS (
    SELECT 
        seller_id, 
        COUNT(DISTINCT category) AS total_categ, 
        SUM(revenue) AS total_revenue,
        CASE 
            WHEN SUM(revenue) > 50000 THEN 'rich'
            ELSE 'poor' 
        END AS seller_type
    FROM sellers
    WHERE category != 'Bedding'
    GROUP BY seller_id
    HAVING COUNT(DISTINCT category) > 1
    ORDER BY seller_id
-- CTE poor_sellers: выбираем всех продавцов, определенных как 'poor' на основе предыдущего CTE.
), poor_sellers AS (
    SELECT *
    FROM sellers
    WHERE seller_id IN (SELECT seller_id FROM sellers_info WHERE seller_type = 'poor')
)
-- выбираем seller_id,
-- month_from_registration (количество полных месяцев с момента первой регистрации каждого 'poor' продавца),
-- max_delivery_difference (разницу между максимальным и минимальным сроком доставки среди 'poor' продавцов).
SELECT 
    seller_id, 
    MAX(
        FLOOR(
            (CURRENT_DATE - to_date(date_reg, 'DD/MM/YYYY')) / 30
        )
    ) AS month_from_registration,
    (
        SELECT MAX(delivery_days) - MIN(delivery_days) FROM poor_sellers
    ) AS max_delivery_difference
FROM poor_sellers
GROUP BY seller_id
ORDER BY seller_id;

-- 2.3
-- CTE sellers_info: собираем информацию о продавцах, зарегистрированных в 2022 году,
-- которые продают ровно 2 категории товаров с суммарной выручкой, превышающей 75 000.
WITH sellers_info AS (
    SELECT 
        seller_id,
        COUNT(DISTINCT category) AS total_categ,
        SUM(revenue) AS total_revenue
    FROM sellers
    WHERE EXTRACT(YEAR FROM to_date(date_reg, 'DD/MM/YYYY')) = 2022 
    GROUP BY seller_id
    HAVING COUNT(DISTINCT category) = 2 AND SUM(revenue) > 75000
), 
-- CTE seller_and_categories: выбираем seller_id и соответствующие категории товаров category,
-- отсортированные в алфавитном порядке. Выбираем только тех продавцов, которые есть в sellers_info.
-- Дополнительно проверяем год регистрации, так как в таблице sellers могут быть продавцы с одинаковым seller_id,
-- но с разными датами регистрации.
seller_and_categories AS (
  SELECT seller_id, category
  FROM sellers 
  WHERE seller_id IN (SELECT seller_id FROM sellers_info) 
  AND EXTRACT(YEAR FROM to_date(date_reg, 'DD/MM/YYYY')) = 2022
  ORDER BY seller_id, category 
)

SELECT seller_id, STRING_AGG(category, ' - ') AS category_pair 
FROM seller_and_categories
GROUP BY seller_id;

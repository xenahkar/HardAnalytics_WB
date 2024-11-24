-- Часть 1
-- Вывожу список сотрудников с именами сотрудников, получающих самую высокую зарплату в отделе.
-- Так как в отделах есть сотрудники с одинаковыми именами, то в 'name_highest_sal' буду указывать имя с фамилией.
-- Расчет с использованием функции max (без оконных функций).
WITH highest_salary_industry AS (
    SELECT 
        (first_name || ' ' || last_name) AS name_highest_sal,
        salary, 
        industry
    FROM salary
    WHERE 
        (salary, industry) IN (
            SELECT max(salary), industry
            FROM salary
            GROUP BY industry
        )
)
SELECT 
    salary.first_name, 
    salary.last_name,
    salary.salary, 
    salary.industry, 
    highest_salary_industry.name_highest_sal
FROM salary
JOIN highest_salary_industry ON highest_salary_industry.industry = salary.industry
ORDER BY highest_salary_industry.industry, salary.salary DESC;

-- Расчет с использованием с использованием first value.
SELECT 
    first_name,
    last_name,
    salary,
    industry,
    FIRST_VALUE(first_name || ' ' || last_name) OVER (PARTITION BY industry ORDER BY salary DESC) AS name_highest_sal
FROM salary;

-- Вывожу список сотрудников с именами сотрудников, получающих минимальную зарплату в отделе.
-- Расчет с использованием функции min (без оконных функций).
WITH lowest_salary_industry AS (
    SELECT 
        (first_name || ' ' || last_name) AS name_lowest_sal,
        salary, 
        industry
    FROM salary
    WHERE 
        (salary, industry) IN (
            SELECT min(salary), industry
            FROM salary
            GROUP BY industry
        )
)
SELECT 
    salary.first_name, 
    salary.last_name,
    salary.salary, 
    salary.industry,
    lowest_salary_industry.name_lowest_sal
FROM salary
JOIN lowest_salary_industry ON lowest_salary_industry.industry = salary.industry
ORDER BY lowest_salary_industry.industry, salary.salary;

-- Вывожу список сотрудников с именами сотрудников, получающих минимальную зарплату в отделе.
-- Расчет с использованием с использованием first value.
SELECT 
    first_name,
    last_name,
    salary,
    industry,
    FIRST_VALUE(first_name || ' ' || last_name) OVER (PARTITION BY industry ORDER BY salary) AS name_lowest_sal
FROM salary;

-- Часть 2
-- 2.1
-- Отбираю данные по продажам за 2.01.2016. Указываю для каждого магазина его номер (SHOPNUMBER), адрес (CITY, ADDRESS), сумму проданных товаров в штуках (SUM_QTY) и сумму проданных товаров в рублях(SUM_QTY_PRICE).
SELECT 
	DISTINCT shops."SHOPNUMBER",
	"CITY",
	"ADDRESS", 
	sum("QTY")  OVER (PARTITION BY shops."SHOPNUMBER") as "SUM_QTY",
	sum("QTY" * "PRICE") OVER (PARTITION BY shops."SHOPNUMBER") as "SUM_QTY_PRICE"
FROM goods 
JOIN sales ON goods."ID_GOOD" = sales."ID_GOOD"
JOIN shops ON sales."SHOPNUMBER" = shops."SHOPNUMBER"
WHERE TO_DATE("DATE", 'DD.MM.YYYY') = TO_DATE('02.01.2016', 'DD.MM.YYYY');
	
-- 2.2
-- Отбираю за каждую дату долю от суммарных продаж по городам. Расчеты проводите только по товарам направления ЧИСТОТА. Столбцы в результирующей таблице DATE_, CITY, SUM_SALES_REL.
SELECT 
    "DATE" AS DATE_,
    "CITY",
    sum("QTY" * "PRICE") / (SUM(sum("QTY" * "PRICE")) OVER (PARTITION BY "DATE")) AS "SUM_SALES_REL"
FROM goods 
JOIN sales ON goods."ID_GOOD" = sales."ID_GOOD"
JOIN shops ON sales."SHOPNUMBER" = shops."SHOPNUMBER"
WHERE "CATEGORY" = 'ЧИСТОТА'
GROUP BY DATE_, "CITY"
ORDER BY DATE_;

-- 2.3
-- Выбираю информацию о топ-3 товарах по продажам в штуках в каждом магазине в каждую дату. Столбцы в результирующей таблице: DATE_ , SHOPNUMBER, ID_GOOD.
WITH SALES_INFO AS (
    SELECT 
        "DATE",
        sales."ID_GOOD",
        "SHOPNUMBER",
        ROW_NUMBER() OVER (PARTITION BY "SHOPNUMBER", "DATE" ORDER BY sales."ID_GOOD") AS rating
    FROM sales
    JOIN goods ON goods."ID_GOOD" = sales."ID_GOOD"
    ORDER BY "DATE", "SHOPNUMBER", sales."ID_GOOD"
)
SELECT 
    "DATE" as DATE_ ,
    "SHOPNUMBER",
    "ID_GOOD"
FROM SALES_INFO
WHERE rating <= 3;

-- Часть 3
-- Создаю таблицу query с данными о поисковых запросах на маркетплейсе с полями searchid, year, month, day, userid, ts, devicetype, deviceid, query. ts- время запроса в формате unix.

CREATE TABLE query (
    searchid INT PRIMARY KEY,
    year INT,
    month INT,
    day INT,
    userid INT,
    ts BIGINT,
    devicetype VARCHAR(50),
    deviceid VARCHAR(50),
    query VARCHAR(255)
);

INSERT INTO query (searchid, year, month, day, userid, ts, devicetype, deviceid, query)
VALUES 
(1, 2024, 11, 24, 1, 1732436000, 'iphone', '199908', 'купить'),
(2, 2024, 11, 24, 1, 1732436010, 'iphone', '199908', 'купить п'),
(3, 2024, 11, 24, 1, 1732436020, 'iphone', '199908', 'купить пу'),
(4, 2024, 11, 24, 1, 1732436030, 'iphone', '199908', 'купить пух'),
(5, 2024, 11, 24, 1, 1732436040, 'iphone', '199908', 'купить пуховик'),
(6, 2024, 11, 24, 1, 1732436050, 'iphone', '199908', 'купить пуховик ж'),
(7, 2024, 11, 24, 1, 1732436060, 'iphone', '199908', 'купить пуховик жен'),
(8, 2024, 11, 24, 1, 1732436070, 'iphone', '199908', 'купить пуховик женс'),
(9, 2024, 11, 24, 1, 1732436080, 'iphone', '199908', 'купить пуховик женский'),
(10, 2024, 11, 24, 1, 1732436090, 'iphone', '199908', 'купить пуховик женский р'),
(11, 2024, 11, 24, 1, 1732436100, 'iphone', '199908', 'купить пуховик женский ро'),
(12, 2024, 11, 24, 1, 1732436110, 'iphone', '199908', 'купить пуховик женский роз'),
(13, 2024, 11, 24, 1, 1732436120, 'iphone', '199908', 'купить пуховик женский розовый'),
(14, 2024, 11, 24, 2, 1732436720, 'android', '200003', 'за'),
(15, 2024, 11, 24, 2, 1732436730, 'android', '200003', 'защи'),
(16, 2024, 11, 24, 2, 1732436740, 'android', '200003', 'защитное'),
(17, 2024, 11, 24, 2, 1732436750, 'android', '200003', 'защитное сте'),
(18, 2024, 11, 24, 2, 1732436760, 'android', '200003', 'защитное стекло'),
(19, 2024, 11, 24, 2, 1732436770, 'android', '200003', 'защитное стекло для'),
(20, 2024, 11, 24, 2, 1732436780, 'android', '200003', 'защитное стекло для сам'),
(21, 2024, 11, 24, 2, 1732436790, 'android', '200003', 'защитное стекло для самсу'),
(22, 2024, 11, 24, 2, 1732436805, 'android', '200003', 'защитное стекло для самсунг ga'),
(23, 2024, 11, 24, 2, 1732436819, 'android', '200003', 'защитное стекло для самсунг gala'),
(24, 2024, 11, 24, 2, 1732436830, 'android', '200003', 'защитное стекло для самсунг galaxy'),
(25, 2024, 11, 24, 2, 1732436845, 'android', '200003', 'защитное стекло для самсунг galaxy s24'),
(26, 2024, 11, 25, 3, 1732560000, 'android', '121212', 'нос'),
(27, 2024, 11, 25, 3, 1732560010, 'android', '121212', 'носки'),
(28, 2024, 11, 25, 3, 1732560030, 'android', '121212', 'носки нов'),
(29, 2024, 11, 25, 3, 1732560035, 'android', '121212', 'носки нового'),
(30, 2024, 11, 25, 3, 1732560040, 'android', '121212', 'носки новогодние'),
(31, 2024, 11, 25, 3, 1732560150, 'android', '121212', 'вар'),
(32, 2024, 11, 25, 3, 1732560200, 'android', '121212', 'варежки');

WITH tempquery AS (
    SELECT 
        searchid, 
        "year", 
        "month", 
        "day", 
        userid, 
        ts, 
        devicetype, 
        deviceid, 
        query,
        LEAD(query) OVER w AS next_query,
        CASE
        	-- если следующий запрос пользователя отсутствует, значит текущий запрос был последним
            WHEN LEAD(query) OVER w is NULL THEN 1
            -- если до следующего запроса прошло более 3х минут
            WHEN (LEAD(ts) OVER w - ts) > 180 THEN 1
            -- если следующий запрос был короче И до следующего запроса прошло прошло более 1 минуты, то значение равно 2
            WHEN LENGTH(LEAD(query) OVER w) < LENGTH(query) AND (LEAD(ts) OVER w - ts) > 60  THEN 2
            ELSE 0
        END AS is_final
    FROM query
    WINDOW w AS (PARTITION BY userid, deviceid ORDER BY ts)
)
-- Выбираю данные о запросах пользователей устройства android за 25.11.2024, у которых is_final равен 1 или 2.
SELECT *
FROM tempquery
WHERE is_final IN (1,2)
AND DATE(TO_TIMESTAMP(ts)) = '2024-11-25'
AND devicetype = 'android'

-- Shift every date in the classicmodels database by one constant so the latest date in the data
-- (order, required, shipped or payment date) becomes @semester_start_text.
USE classicmodels;
SET @semester_start = CAST(@semester_start_text AS DATE);
SET @latest = (SELECT MAX(d) FROM (
    SELECT MAX(orderDate) d FROM orders
    UNION ALL SELECT MAX(requiredDate) FROM orders
    UNION ALL SELECT MAX(shippedDate)  FROM orders
    UNION ALL SELECT MAX(paymentDate)  FROM payments
) x);
SET @shift = DATEDIFF(@semester_start, @latest);
SELECT @latest AS latest_before, @semester_start AS latest_after, @shift AS shift_days;

-- A NULL shippedDate (not shipped yet) stays NULL.
UPDATE orders   SET orderDate    = DATE_ADD(orderDate,    INTERVAL @shift DAY),
                    requiredDate = DATE_ADD(requiredDate, INTERVAL @shift DAY),
                    shippedDate  = DATE_ADD(shippedDate,  INTERVAL @shift DAY);
UPDATE payments SET paymentDate  = DATE_ADD(paymentDate,  INTERVAL @shift DAY);

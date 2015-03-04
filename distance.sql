
-- Good afternoon! Do you have any idea, how can I query the points based on 5 km radius and compared to a given coordinate in SQL?

-- Yes, of course! The SQL way:

SELECT *, ( 6370986 * acos( sin(radians(start.lat)) * sin(radians(lat)) + cos(radians(start.lat)) * cos(radians(lat)) * cos(radians(lon) - radians(start.lon)) ) ) AS dist
FROM points dest
HAVING dist < 5000
ORDER BY dist

-- And the much simpler PostGIS way:

SELECT *, ST_Distance_Sphere(ST_Point(start.lon, start.lat), ST_Point(lon, lat)) AS dist
FROM points dest
HAVING dist < 5000
ORDER BY dist

-- Thank you, goodbye! :)

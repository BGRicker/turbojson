SELECT json_build_object('id', bars.id, 'name', bars.name, 'category', category_json.category, 'bar_photos', bar_photos_json.bar_photos) AS data
FROM bars
LEFT JOIN LATERAL (SELECT json_build_object('id', categories.id, 'name', categories.name) AS category
FROM categories
WHERE categories.category_id = bars.id
LIMIT 1) category_json ON TRUE
LEFT JOIN LATERAL (SELECT COALESCE(json_agg(child_rows.data), '[]'::json) AS bar_photos
FROM (SELECT json_build_object('id', bar_photos.id, 'url', bar_photos.url) AS data
FROM bar_photos
WHERE bar_photos.bar_id = bars.id) child_rows) bar_photos_json ON TRUE

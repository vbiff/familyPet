-- Check for duplicate pets by family_id
SELECT 
  family_id, 
  COUNT(*) as pet_count,
  array_agg(id) as pet_ids,
  array_agg(name) as pet_names
FROM pets 
GROUP BY family_id 
HAVING COUNT(*) > 1;

-- Check all pets to see the data
SELECT id, name, family_id, stage, created_at 
FROM pets 
ORDER BY family_id, created_at;

-- If you find duplicates, you can delete them with:
-- DELETE FROM pets WHERE id IN ('duplicate-pet-id-1', 'duplicate-pet-id-2'); 
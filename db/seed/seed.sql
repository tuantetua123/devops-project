INSERT INTO classes(code, name) VALUES
  ('DEVOPS01', 'DevOps - Nhóm 1'), ('NET02', 'Mạng máy tính')
ON CONFLICT DO NOTHING;

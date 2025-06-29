-- init.sql
-- Этот файл автоматически выполняется при первом запуске PostgreSQL контейнера
-- Он включает PostGIS расширения для работы с геолокационными данными

-- Включить PostGIS расширение для работы с геоданными
CREATE EXTENSION IF NOT EXISTS postgis;

-- Включить топологические функции PostGIS
CREATE EXTENSION IF NOT EXISTS postgis_topology;

-- Включить расширение для растровых данных (опционально)
CREATE EXTENSION IF NOT EXISTS postgis_raster;

-- Включить расширение для федеративных внешних данных (опционально)
CREATE EXTENSION IF NOT EXISTS postgis_fdw;

-- Проверить успешную установку расширений
SELECT name, default_version, installed_version 
FROM pg_available_extensions 
WHERE name LIKE 'postgis%';

-- Вывести информацию о версии PostGIS
SELECT PostGIS_version();
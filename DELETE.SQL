-- ============================================================
--  DELETE.SQL  —  SalesPro: Видалення всіх об'єктів БД
--  Порядок: спочатку залежні таблиці, потім батьківські
--  Лабораторна робота №7  |  Група ЗКС-21  |  Вионг
-- ============================================================

USE SalesPro;
GO

-- ============================================================
-- КРОК 1: Вимкнути всі FK-обмеження (безпечне видалення)
-- ============================================================
EXEC sp_MSforeachtable 'ALTER TABLE ? NOCHECK CONSTRAINT ALL';
GO

-- ============================================================
-- КРОК 2: Видалення в порядку залежностей (листові → кореневі)
-- ============================================================

-- Рівень 5: найглибші залежності
IF OBJECT_ID('dbo.deliveries',    'U') IS NOT NULL DROP TABLE dbo.deliveries;
IF OBJECT_ID('dbo.payments',      'U') IS NOT NULL DROP TABLE dbo.payments;

-- Рівень 4
IF OBJECT_ID('dbo.shipments',     'U') IS NOT NULL DROP TABLE dbo.shipments;
IF OBJECT_ID('dbo.invoices',      'U') IS NOT NULL DROP TABLE dbo.invoices;
IF OBJECT_ID('dbo.order_lines',   'U') IS NOT NULL DROP TABLE dbo.order_lines;

-- Рівень 3
IF OBJECT_ID('dbo.orders',        'U') IS NOT NULL DROP TABLE dbo.orders;
IF OBJECT_ID('dbo.stock',         'U') IS NOT NULL DROP TABLE dbo.stock;
IF OBJECT_ID('dbo.addresses',     'U') IS NOT NULL DROP TABLE dbo.addresses;
IF OBJECT_ID('dbo.client_phones', 'U') IS NOT NULL DROP TABLE dbo.client_phones;

-- Рівень 2
IF OBJECT_ID('dbo.warehouses',    'U') IS NOT NULL DROP TABLE dbo.warehouses;
IF OBJECT_ID('dbo.products',      'U') IS NOT NULL DROP TABLE dbo.products;
IF OBJECT_ID('dbo.clients',       'U') IS NOT NULL DROP TABLE dbo.clients;

-- Рівень 1: незалежні таблиці (кореневі)
IF OBJECT_ID('dbo.managers',      'U') IS NOT NULL DROP TABLE dbo.managers;
IF OBJECT_ID('dbo.suppliers',     'U') IS NOT NULL DROP TABLE dbo.suppliers;
IF OBJECT_ID('dbo.zip_codes',     'U') IS NOT NULL DROP TABLE dbo.zip_codes;

GO

PRINT 'DELETE.SQL виконано успішно. Всі 15 таблиць видалено.';
GO

-- ============================================================
--  SETUP.SQL  —  SalesPro Physical Model (MS SQL Server)
--  Предметна область: Система управління продажами ТОВ «SalesPro»
--  Лабораторна робота №7  |  Група ЗКС-21  |  Вионг
--  Нотація: T-SQL (MS SQL Server 2019+)
-- ============================================================

USE master;
GO

IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'SalesPro')
BEGIN
    CREATE DATABASE SalesPro;
END
GO

USE SalesPro;
GO

-- ============================================================
-- РОЗДІЛ 1: ДОВІДНИКИ (незалежні таблиці — без FK)
-- ============================================================

-- 1. zip_codes — Поштові індекси (довідник міст)
CREATE TABLE zip_codes (
    zip_id      INT            IDENTITY(1,1) NOT NULL,
    zip_code    VARCHAR(10)    NOT NULL,
    city        NVARCHAR(100)  NOT NULL,
    region      NVARCHAR(100)  NOT NULL,
    -- PK
    CONSTRAINT PK_zip_codes     PRIMARY KEY (zip_id),
    -- UNIQUE: один поштовий індекс → одне місто
    CONSTRAINT UQ_zip_codes_zip UNIQUE (zip_code),
    -- CHECK: індекс не порожній
    CONSTRAINT CK_zip_codes_zip CHECK (LEN(RTRIM(zip_code)) > 0)
);
GO

-- 2. suppliers — Постачальники
CREATE TABLE suppliers (
    supplier_id INT            IDENTITY(1,1) NOT NULL,
    name        NVARCHAR(200)  NOT NULL,
    phone       VARCHAR(20)    NOT NULL,
    email       VARCHAR(150)   NOT NULL,
    -- PK
    CONSTRAINT PK_suppliers         PRIMARY KEY (supplier_id),
    -- UNIQUE: email постачальника унікальний
    CONSTRAINT UQ_suppliers_email   UNIQUE (email),
    -- CHECK: email містить @
    CONSTRAINT CK_suppliers_email   CHECK (email LIKE '%@%.%'),
    -- CHECK: phone не порожній
    CONSTRAINT CK_suppliers_phone   CHECK (LEN(RTRIM(phone)) > 0)
);
GO

-- 3. managers — Менеджери (рекурсивний зв'язок: supervisor_id → manager_id)
CREATE TABLE managers (
    manager_id    INT            IDENTITY(1,1) NOT NULL,
    name          NVARCHAR(200)  NOT NULL,
    email         VARCHAR(150)   NOT NULL,
    dept          NVARCHAR(100)  NOT NULL,
    supervisor_id INT            NULL,          -- NULL для топ-менеджерів
    -- PK
    CONSTRAINT PK_managers          PRIMARY KEY (manager_id),
    -- UNIQUE: email менеджера унікальний
    CONSTRAINT UQ_managers_email    UNIQUE (email),
    -- FK рекурсивний
    CONSTRAINT FK_managers_super    FOREIGN KEY (supervisor_id)
        REFERENCES managers(manager_id)
        ON DELETE SET NULL
        ON UPDATE CASCADE,
    -- CHECK: ім'я не порожнє
    CONSTRAINT CK_managers_name     CHECK (LEN(RTRIM(name)) > 0),
    -- CHECK: email містить @
    CONSTRAINT CK_managers_email    CHECK (email LIKE '%@%.%')
);
GO

-- ============================================================
-- РОЗДІЛ 2: КЛІЄНТИ
-- ============================================================

-- 4. clients — Клієнти
CREATE TABLE clients (
    client_id     INT            IDENTITY(1,1) NOT NULL,
    name          NVARCHAR(200)  NOT NULL,
    email         VARCHAR(150)   NOT NULL,
    credit_limit  MONEY          NOT NULL DEFAULT 0,
    -- PK
    CONSTRAINT PK_clients           PRIMARY KEY (client_id),
    -- UNIQUE: один email — один клієнт
    CONSTRAINT UQ_clients_email     UNIQUE (email),
    -- CHECK: кредитний ліміт не від'ємний
    CONSTRAINT CK_clients_credit    CHECK (credit_limit >= 0),
    -- CHECK: email містить @
    CONSTRAINT CK_clients_email     CHECK (email LIKE '%@%.%')
);
GO

-- 5. client_phones — Телефони клієнтів (1NF: багато телефонів → окрема таблиця)
CREATE TABLE client_phones (
    phone_id    INT            IDENTITY(1,1) NOT NULL,
    client_id   INT            NOT NULL,
    phone       VARCHAR(20)    NOT NULL,
    type        VARCHAR(20)    NOT NULL DEFAULT 'mobile',
    -- PK
    CONSTRAINT PK_client_phones     PRIMARY KEY (phone_id),
    -- FK
    CONSTRAINT FK_cphones_client    FOREIGN KEY (client_id)
        REFERENCES clients(client_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    -- UNIQUE: один номер для одного клієнта
    CONSTRAINT UQ_cphones_phone     UNIQUE (client_id, phone),
    -- CHECK: тип телефону з допустимих значень
    CONSTRAINT CK_cphones_type      CHECK (type IN ('mobile','home','work','fax')),
    -- CHECK: телефон не порожній
    CONSTRAINT CK_cphones_phone     CHECK (LEN(RTRIM(phone)) > 0)
);
GO

-- 6. addresses — Адреси клієнтів
CREATE TABLE addresses (
    addr_id     INT            IDENTITY(1,1) NOT NULL,
    client_id   INT            NOT NULL,
    street      NVARCHAR(300)  NOT NULL,
    zip_id      INT            NOT NULL,
    -- PK
    CONSTRAINT PK_addresses         PRIMARY KEY (addr_id),
    -- FK до clients
    CONSTRAINT FK_addresses_client  FOREIGN KEY (client_id)
        REFERENCES clients(client_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    -- FK до zip_codes
    CONSTRAINT FK_addresses_zip     FOREIGN KEY (zip_id)
        REFERENCES zip_codes(zip_id)
        ON DELETE NO ACTION
        ON UPDATE CASCADE,
    -- CHECK: вулиця не порожня
    CONSTRAINT CK_addresses_street  CHECK (LEN(RTRIM(street)) > 0)
);
GO

-- ============================================================
-- РОЗДІЛ 3: ТОВАРИ ТА СКЛАДИ
-- ============================================================

-- 7. products — Товари (рекурсивний зв'язок: parent_cat → product_id)
CREATE TABLE products (
    product_id  INT            IDENTITY(1,1) NOT NULL,
    name        NVARCHAR(300)  NOT NULL,
    price       MONEY          NOT NULL,
    category    NVARCHAR(100)  NOT NULL,
    supplier_id INT            NOT NULL,
    parent_cat  INT            NULL,             -- NULL для кореневих категорій
    -- PK
    CONSTRAINT PK_products          PRIMARY KEY (product_id),
    -- FK до suppliers
    CONSTRAINT FK_products_supplier FOREIGN KEY (supplier_id)
        REFERENCES suppliers(supplier_id)
        ON DELETE NO ACTION
        ON UPDATE CASCADE,
    -- FK рекурсивний (ієрархія категорій)
    CONSTRAINT FK_products_parent   FOREIGN KEY (parent_cat)
        REFERENCES products(product_id)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
    -- CHECK: ціна строго позитивна
    CONSTRAINT CK_products_price    CHECK (price > 0),
    -- CHECK: назва не порожня
    CONSTRAINT CK_products_name     CHECK (LEN(RTRIM(name)) > 0)
);
GO

-- 8. warehouses — Склади
CREATE TABLE warehouses (
    warehouse_id INT            IDENTITY(1,1) NOT NULL,
    location     NVARCHAR(300)  NOT NULL,
    capacity     INT            NOT NULL,
    manager_id   INT            NOT NULL,
    -- PK
    CONSTRAINT PK_warehouses        PRIMARY KEY (warehouse_id),
    -- FK до managers
    CONSTRAINT FK_wh_manager        FOREIGN KEY (manager_id)
        REFERENCES managers(manager_id)
        ON DELETE NO ACTION
        ON UPDATE CASCADE,
    -- CHECK: місткість > 0
    CONSTRAINT CK_wh_capacity       CHECK (capacity > 0)
);
GO

-- 9. stock — Залишки товарів на складах (асоціативна таблиця N:M)
CREATE TABLE stock (
    stock_id      INT  IDENTITY(1,1) NOT NULL,
    product_id    INT  NOT NULL,
    warehouse_id  INT  NOT NULL,
    quantity      INT  NOT NULL DEFAULT 0,
    reserved_qty  INT  NOT NULL DEFAULT 0,
    -- PK
    CONSTRAINT PK_stock             PRIMARY KEY (stock_id),
    -- UNIQUE: один товар — один склад (унікальна пара)
    CONSTRAINT UQ_stock_pair        UNIQUE (product_id, warehouse_id),
    -- FK до products
    CONSTRAINT FK_stock_product     FOREIGN KEY (product_id)
        REFERENCES products(product_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    -- FK до warehouses
    CONSTRAINT FK_stock_warehouse   FOREIGN KEY (warehouse_id)
        REFERENCES warehouses(warehouse_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    -- CHECK: залишок не від'ємний
    CONSTRAINT CK_stock_qty         CHECK (quantity >= 0),
    -- CHECK: зарезервована кількість ≤ загальна кількість
    CONSTRAINT CK_stock_reserved    CHECK (reserved_qty >= 0 AND reserved_qty <= quantity)
);
GO

-- ============================================================
-- РОЗДІЛ 4: ЗАМОВЛЕННЯ ТА ФІНАНСИ
-- ============================================================

-- 10. orders — Замовлення клієнтів
CREATE TABLE orders (
    order_id    INT            IDENTITY(1,1) NOT NULL,
    order_date  DATETIME2      NOT NULL DEFAULT SYSDATETIME(),
    status      VARCHAR(20)    NOT NULL DEFAULT 'new',
    client_id   INT            NOT NULL,
    manager_id  INT            NOT NULL,
    -- PK
    CONSTRAINT PK_orders            PRIMARY KEY (order_id),
    -- FK до clients
    CONSTRAINT FK_orders_client     FOREIGN KEY (client_id)
        REFERENCES clients(client_id)
        ON DELETE NO ACTION
        ON UPDATE CASCADE,
    -- FK до managers
    CONSTRAINT FK_orders_manager    FOREIGN KEY (manager_id)
        REFERENCES managers(manager_id)
        ON DELETE NO ACTION
        ON UPDATE CASCADE,
    -- CHECK: статус із допустимих значень
    CONSTRAINT CK_orders_status     CHECK (status IN ('new','processing','completed','cancelled','returned')),
    -- CHECK: дата замовлення не в майбутньому
    CONSTRAINT CK_orders_date       CHECK (order_date <= SYSDATETIME())
);
GO

-- 11. order_lines — Рядки замовлень (асоціативна таблиця N:M)
CREATE TABLE order_lines (
    line_id        INT    IDENTITY(1,1) NOT NULL,
    order_id       INT    NOT NULL,
    product_id     INT    NOT NULL,
    quantity       INT    NOT NULL,
    price_snapshot MONEY  NOT NULL,
    -- PK
    CONSTRAINT PK_order_lines       PRIMARY KEY (line_id),
    -- UNIQUE: один товар — один рядок у замовленні
    CONSTRAINT UQ_olines_pair       UNIQUE (order_id, product_id),
    -- FK до orders
    CONSTRAINT FK_olines_order      FOREIGN KEY (order_id)
        REFERENCES orders(order_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    -- FK до products
    CONSTRAINT FK_olines_product    FOREIGN KEY (product_id)
        REFERENCES products(product_id)
        ON DELETE NO ACTION
        ON UPDATE CASCADE,
    -- CHECK: кількість ≥ 1
    CONSTRAINT CK_olines_qty        CHECK (quantity >= 1),
    -- CHECK: ціна на момент продажу > 0
    CONSTRAINT CK_olines_price      CHECK (price_snapshot > 0)
);
GO

-- 12. invoices — Рахунки-фактури
CREATE TABLE invoices (
    invoice_id  INT        IDENTITY(1,1) NOT NULL,
    issue_date  DATETIME2  NOT NULL DEFAULT SYSDATETIME(),
    due_date    DATETIME2  NOT NULL,
    amount      MONEY      NOT NULL,
    order_id    INT        NOT NULL,
    -- PK
    CONSTRAINT PK_invoices          PRIMARY KEY (invoice_id),
    -- FK до orders
    CONSTRAINT FK_invoices_order    FOREIGN KEY (order_id)
        REFERENCES orders(order_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    -- CHECK: сума > 0
    CONSTRAINT CK_invoices_amount   CHECK (amount > 0),
    -- CHECK: дата оплати після дати виставлення
    CONSTRAINT CK_invoices_dates    CHECK (due_date > issue_date)
);
GO

-- 13. payments — Оплати
CREATE TABLE payments (
    payment_id  INT        IDENTITY(1,1) NOT NULL,
    pay_date    DATETIME2  NOT NULL DEFAULT SYSDATETIME(),
    amount      MONEY      NOT NULL,
    method      VARCHAR(20) NOT NULL DEFAULT 'bank',
    invoice_id  INT        NOT NULL,
    -- PK
    CONSTRAINT PK_payments          PRIMARY KEY (payment_id),
    -- FK до invoices
    CONSTRAINT FK_payments_invoice  FOREIGN KEY (invoice_id)
        REFERENCES invoices(invoice_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    -- CHECK: сума оплати > 0
    CONSTRAINT CK_payments_amount   CHECK (amount > 0),
    -- CHECK: метод оплати з допустимих значень
    CONSTRAINT CK_payments_method   CHECK (method IN ('cash','bank','card','crypto'))
);
GO

-- ============================================================
-- РОЗДІЛ 5: ЛОГІСТИКА
-- ============================================================

-- 14. shipments — Відвантаження
CREATE TABLE shipments (
    shipment_id  INT        IDENTITY(1,1) NOT NULL,
    ship_date    DATETIME2  NOT NULL DEFAULT SYSDATETIME(),
    status       VARCHAR(20) NOT NULL DEFAULT 'pending',
    order_id     INT        NOT NULL,
    warehouse_id INT        NOT NULL,
    -- PK
    CONSTRAINT PK_shipments         PRIMARY KEY (shipment_id),
    -- FK до orders
    CONSTRAINT FK_shipments_order   FOREIGN KEY (order_id)
        REFERENCES orders(order_id)
        ON DELETE NO ACTION
        ON UPDATE CASCADE,
    -- FK до warehouses
    CONSTRAINT FK_shipments_wh      FOREIGN KEY (warehouse_id)
        REFERENCES warehouses(warehouse_id)
        ON DELETE NO ACTION
        ON UPDATE CASCADE,
    -- CHECK: статус із допустимих значень
    CONSTRAINT CK_shipments_status  CHECK (status IN ('pending','in_transit','delivered','returned'))
);
GO

-- 15. deliveries — Доставки
CREATE TABLE deliveries (
    delivery_id  INT            IDENTITY(1,1) NOT NULL,
    del_date     DATETIME2      NOT NULL,
    carrier      NVARCHAR(100)  NOT NULL,
    tracking_no  VARCHAR(50)    NOT NULL,
    shipment_id  INT            NOT NULL,
    -- PK
    CONSTRAINT PK_deliveries        PRIMARY KEY (delivery_id),
    -- UNIQUE: унікальний номер відстеження
    CONSTRAINT UQ_deliveries_track  UNIQUE (tracking_no),
    -- FK до shipments
    CONSTRAINT FK_deliveries_ship   FOREIGN KEY (shipment_id)
        REFERENCES shipments(shipment_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    -- CHECK: перевізник не порожній
    CONSTRAINT CK_deliveries_carrier CHECK (LEN(RTRIM(carrier)) > 0)
);
GO

PRINT 'SETUP.SQL виконано успішно. Створено 15 таблиць.';
GO

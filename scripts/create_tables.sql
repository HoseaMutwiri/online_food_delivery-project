-- Create the tables for the online food delivery schema
SELECT current_database();

CREATE SCHEMA online_p;

SET search_path TO online_p;

CREATE TABLE online_p.customers(
    customer_id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    city VARCHAR(100) NOT NULL,
    signup_date DATE NOT NULL,
    gender CHAR(1)
);

CREATE TABLE online_p.delivery_agents(
    agent_id INT PRIMARY KEY,
    agent_name VARCHAR(100) NOT NULL,
    city VARCHAR(100) NOT NULL,
    joining_date DATE NOT NULL,
    rating DECIMAL(3,2)
);

CREATE TABLE online_p.restaurant(
    restaurant_id INT PRIMARY KEY,
    restaurant_name TEXT,
    city VARCHAR(100) NOT NULL,
    cuisine VARCHAR(100) NOT NULL,
    rating DECIMAL(3,2)
);

CREATE TABLE online_p.orders(
    order_id INT PRIMARY KEY,
    customer_id INT NOT NULL,
    restaurant_id INT NOT NULL,
    order_date DATE NOT NULL,
    order_amount DECIMAL(10,2) NOT NULL,
    discount DECIMAL(10,2) DEFAULT 0,
    payment_method VARCHAR(50) NOT NULL,
    delivery_time TIME
);

CREATE TABLE online_p.order_items(
    order_item_id INT,
    order_id INT,
    item_name VARCHAR(150) NOT NULL,
    quantity INT NOT NULL,
    price DECIMAL(10,2) NOT NULL);

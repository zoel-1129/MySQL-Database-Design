CREATE DATABASE IF NOT EXISTS db_proapp;
USE db_proapp;

# CREATE TABLES
-- Table 1: Customer
CREATE TABLE Customer (
    customer_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone_number VARCHAR(20) NOT NULL,
    country VARCHAR(50) NOT NULL,
    city VARCHAR(50) NOT NULL,
    description TEXT,
    customer_since_date DATETIME NOT NULL
);

-- Table 2: Tasker 
CREATE TABLE Tasker (
    tasker_id INT PRIMARY KEY AUTO_INCREMENT,
	name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone_number VARCHAR(20) NOT NULL,
    country VARCHAR(30) NOT NULL,
    city VARCHAR(30) NOT NULL,
    description TEXT,
    tasker_since_date DATETIME NOT NULL,
    tasker_type ENUM('Supplier', 'Tradesperson') NOT NULL
);

-- Table 3: Membership
CREATE TABLE Membership (
    membership_id INT PRIMARY KEY AUTO_INCREMENT,
    tasker_id INT NOT NULL,
    membership_type ENUM('Monthly', 'Yearly') NOT NULL,
    registration_date DATETIME NOT NULL,
    expiry_date DATETIME NOT NULL,
    membership_fee DECIMAL(10, 2),
    FOREIGN KEY (tasker_id) REFERENCES Tasker(tasker_id)
);

-- Table 4: Certification
CREATE TABLE Certification (
    certification_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    estimated_completion_time INT, -- in hours
    expire_after_years INT, -- in years
    training_field VARCHAR(100) NOT NULL
);

-- Table 5: Certification_Tasker (Training and Assessment)
CREATE TABLE Training_And_Assessment (
    tasker_id INT NOT NULL,
    certification_id INT NOT NULL,
    background_check_status BOOLEAN,
    police_check_status BOOLEAN,
    code_of_practice_check_status BOOLEAN,
    training_result ENUM('Pass', 'Fail'),
    date_recorded DATETIME NOT NULL,
    PRIMARY KEY (tasker_id, certification_id, date_recorded),
    FOREIGN KEY (tasker_id) REFERENCES Tasker(tasker_id),
    FOREIGN KEY (certification_id) REFERENCES Certification(certification_id)
);

-- Table 6: Task
CREATE TABLE Task (
    task_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT NOT NULL,
    task_title VARCHAR(255),
    budget DECIMAL(10, 2),
    task_desc TEXT,
    due_date DATETIME,
    creation_date DATETIME,
    certification_required BOOLEAN,
    expertise_area VARCHAR(255),
    FOREIGN KEY (customer_id) REFERENCES Customer(customer_id)
);

-- Table 7: Tasker_Task (Task Assignment)
CREATE TABLE Task_Assignment (
    task_id INT NOT NULL,
    tasker_id INT NOT NULL,
    bid_price DECIMAL(10, 2) NOT NULL,
    date_recorded DATETIME,
    customer_rating INT CHECK (customer_rating BETWEEN 1 AND 5),
    tasker_rating INT CHECK (tasker_rating BETWEEN 1 AND 5),
    task_status ENUM('Not assigned', 'Assigned', 'Completed', 'Cancelled') NOT NULL,
    bid_status ENUM('Successful', 'Failed', 'Pending') NOT NULL,
    cancel_reason VARCHAR(255),
    cancelled_by ENUM('Customer', 'Tasker'),
    PRIMARY KEY (task_id, tasker_id, date_recorded),
    FOREIGN KEY (task_id) REFERENCES Task(task_id),
    FOREIGN KEY (tasker_id) REFERENCES Tasker(tasker_id)
);

-- Table 8: (Customer_Tasker) Payment
CREATE TABLE Payment (
    tasker_id INT NOT NULL,
    customer_id INT NOT NULL,
    pmt_status ENUM('Successful', 'Failed'),
    pmt_amount DECIMAL(10, 2),
    pmt_type ENUM('Credit Card', 'PayPal', 'E-money'),
    date_recorded DATETIME,
    PRIMARY KEY (customer_id, tasker_id, date_recorded),
    FOREIGN KEY (customer_id) REFERENCES Customer(customer_id),
    FOREIGN KEY (tasker_id) REFERENCES Tasker(tasker_id)
);

# INSERT VALUES
-- Set up environment
-- SET GLOBAL local_infile=1;
-- show global variables like 'local_infile';
-- SHOW VARIABLES LIKE 'secure_file_priv'; 
-- Note: for the bulk insert to work, should put the files in following folder "C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\file_name.csv"
-- All of the data files are put in "Dummy Data" folder

-- Input customer values
LOAD DATA INFILE "C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\Customer.csv"
INTO TABLE Customer
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(name,email,phone_number,country,city,description,customer_since_date);
-- check if inserting is valid
-- select * from customer;

-- Import tasker values through MYSQL Import Tool
-- check if inserting is valid
-- select * from tasker;

-- Input membership values
LOAD DATA INFILE "C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\Membership.csv"
INTO TABLE Membership
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(tasker_id,membership_type,registration_date,expiry_date,membership_fee);
-- check if inserting is valid
-- select * from membership;

-- Import certification values through MYSQL Import Tool
-- check if inserting is valid
-- select * from certification;

-- Insert training_and_assessment values
LOAD DATA INFILE "C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\Training_And_Assessment.csv"
INTO TABLE training_and_assessment
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(tasker_id,certification_id,background_check_status,police_check_status,code_of_practice_check_status,training_result,date_recorded);
-- check if inserting is valid
-- select * from training_and_assessment;

-- Insert task values
LOAD DATA INFILE "C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\Task.csv"
INTO TABLE task
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(customer_id,task_title,budget,task_desc,due_date,creation_date,certification_required,expertise_area);
-- check if inserting is valid
-- select * from task;

-- Import task_assignment values through MYSQL Import Tool
-- check if inserting is valid
-- select * from task_assignment;

-- Import payment values through MYSQL Import Tool
-- check if inserting is valid
-- select * from payment;


## ANALYSIS
# Problem 1: Balancing demand and supply across regions
-- Total taskers and customers on the platform
SELECT tasker_stats.total_taskers, customer_stats.total_customers
FROM (
    SELECT COUNT(tasker_id) AS total_taskers
    FROM tasker
) AS tasker_stats
JOIN (
    SELECT COUNT(customer_id) AS total_customers
    FROM customer
) AS customer_stats;

-- Top 5 countries by tasker count
SELECT country as top_5_country, COUNT(tasker_id) AS total_taskers
FROM tasker
GROUP BY country
ORDER BY total_taskers DESC
LIMIT 5;

-- Top 5 countries by customer count
SELECT country as top_5_country, COUNT(customer_id) AS total_customers
FROM customer
GROUP BY country
ORDER BY total_customers DESC
LIMIT 5;


# Problem 2: Tracking platform engagement rate (Taskers posting tasks vs. customers bidding task)
SELECT COUNT(DISTINCT t.tasker_id) AS active_taskers,
       t_stat.total_taskers,
       COUNT(DISTINCT c.customer_id) AS active_customers,
       c_stat.total_customers
FROM customer c
JOIN task tsk ON c.customer_id = tsk.customer_id
JOIN task_assignment ta ON tsk.task_id = ta.task_id
JOIN tasker t ON ta.tasker_id = t.tasker_id
JOIN (SELECT COUNT(*) AS total_taskers FROM tasker) AS t_stat
JOIN (SELECT COUNT(*) AS total_customers FROM customer) AS c_stat;


# Problem 3: Customer spending behavior
SELECT customer_id, expertise_area, AVG(budget) AS avg_spending, COUNT(tsk.task_id) AS task_count
FROM task tsk
JOIN task_assignment ta ON tsk.task_id = ta.task_id
WHERE task_status = 'Completed'
GROUP BY customer_id, expertise_area
ORDER BY avg_spending DESC;


# Problem 4: Revenue sources and the need for adjusting fee rate
SELECT 'Transaction Fee' AS source, SUM(p.pmt_amount) * 0.1 AS total_revenue -- every transaction costs 10% to the app
FROM Payment p
WHERE p.pmt_status = 'Successful'
UNION ALL
SELECT 'Membership Fee', SUM(m.membership_fee) AS total_revenue
FROM Membership m
UNION ALL
SELECT 'Quote Fee', SUM(ta.bid_price) * 0.01 -- assuming that every successful bid is charged 1% of bid price, and this is split between 2 parties
FROM Task_Assignment ta
WHERE bid_status = 'Successful'
ORDER BY total_revenue DESC;


# Problem 5: Rating and cancellation trends
-- Overall ratings and factors impacting them
SELECT AVG(ta.customer_rating) AS avg_customer_rating, 
       AVG(ta.tasker_rating) AS avg_tasker_rating, 
       tsk.expertise_area,
       AVG(ta.bid_price) AS avg_bid_price,
       AVG(task_status = 'Cancelled')*100 AS avg_cancellation_rate
FROM task_assignment ta
JOIN task tsk ON ta.task_id = tsk.task_id
GROUP BY tsk.expertise_area
ORDER BY avg_customer_rating ASC, avg_tasker_rating ASC;

-- Deep dive into cancellations
SELECT COUNT(DISTINCT ta.task_id) AS cancelled_tasks, ta.cancel_reason, ta.cancelled_by
FROM Task_Assignment ta
WHERE task_status = 'Cancelled'
GROUP BY ta.cancel_reason, ta.cancelled_by;

-- Specify which tasker and customer cancel the task
SELECT COUNT(distinct ta.task_id) AS cancelled_tasks, ta.cancel_reason, ta.cancelled_by, c.customer_id, t.tasker_id
FROM customer c
JOIN task tsk on c.customer_id = tsk.customer_id
JOIN task_assignment ta on tsk.task_id = ta.task_id
JOIN tasker t on ta.tasker_id = t.tasker_id
WHERE task_status = 'Cancelled'
GROUP BY ta.cancel_reason, ta.cancelled_by, c.customer_id, t.tasker_id
ORDER BY cancelled_tasks DESC;


# Problem 6: Payment method trends and failures
-- Payment trends by type
SELECT p.pmt_type, 
       COUNT(*) AS total_payments, 
       SUM(p.pmt_amount) AS total_amount
FROM Payment p
GROUP BY p.pmt_type
ORDER BY total_payments DESC;

-- Failed payments analysis
SELECT pmt_status, COUNT(*) AS failed_payments, pmt_type
FROM Payment
WHERE pmt_status = 'Failed'
GROUP BY pmt_type;


# Problem 7: Membership trends and certification effectiveness
-- Tasks requiring certification vs. taskers with membership
SELECT task_stats.total_task_require_certification, membership_stats.total_taskers_have_membership
FROM (
    SELECT COUNT(*) AS total_task_require_certification
    FROM task
    WHERE certification_required = TRUE
) AS task_stats
JOIN (
    SELECT COUNT(distinct tasker_id) AS total_taskers_have_membership
    FROM membership
) AS membership_stats;

-- Membership type distribution
SELECT m.membership_type, COUNT(m.tasker_id) as total_memberships
FROM Membership m
GROUP BY m.membership_type
ORDER BY total_memberships DESC;

-- Break down by year
SELECT extract(year from registration_date) as year, membership_type, COUNT(tasker_id) as total_memberships
FROM Membership 
GROUP BY year, membership_type
ORDER BY membership_type, year;


# Problem 8: Certification demand vs. participation
-- Tasks requiring certification vs. taskers taking certification
SELECT task_stats.total_task_require_certification, certification_stats.total_taskers_take_certification
FROM (
    SELECT COUNT(*) AS total_task_require_certification
    FROM task
    WHERE certification_required = TRUE
) AS task_stats
JOIN (
    SELECT COUNT(DISTINCT tasker_id) AS total_taskers_take_certification
    FROM training_and_assessment
) AS certification_stats;

-- Top 5 expertise area requiring certification
SELECT COUNT(*) AS total_task_require_certification, expertise_area
FROM task
WHERE certification_required = TRUE
GROUP BY expertise_area
ORDER BY total_task_require_certification DESC
LIMIT 5;

-- Top 5 training fields that taskers take the certification
SELECT COUNT(distinct tasker_id) AS total_certifications_taken, training_field
FROM training_and_assessment train_assess
JOIN certification c ON train_assess.certification_id = c.certification_id
GROUP BY training_field
ORDER BY total_certifications_taken DESC;


# Problem 9: Tracking training quality
-- Certification pass rates by training field
SELECT c.training_field, 
       COUNT(train_assess.certification_id) AS total_certifications, 
       SUM(CASE WHEN train_assess.training_result = 'Pass' THEN 1 ELSE 0 END) AS passed_certifications,
       ROUND((SUM(CASE WHEN train_assess.training_result = 'Pass' THEN 1 ELSE 0 END) / COUNT(train_assess.certification_id)),2) * 100 AS pass_rate
FROM certification c
JOIN Training_And_Assessment train_assess ON c.certification_id = train_assess.certification_id
GROUP BY c.training_field
ORDER BY pass_rate ASC;





















# Extracting-User-Journey-Data-Using-SQL-Project

This project involves extracting and analyzing user journey data from a subscription-based platform. The goal is to gather detailed sequences of pages visited by users who made their first subscription purchase within the first quarter of 2023. By analyzing the user journey before the purchase, the aim is to understand how users interact with the platform and navigate through the product pages before committing to a subscription.

# Project Overview
This project consists of a series of SQL queries that aggregate the data on user interactions with the platform and track the steps they take before subscribing. 
The steps followed in this project are:

Filtering Users: We start by selecting users who made their first purchase between January 1st and March 31st, 2023, and exclude test users who paid $0.
Extracting User Interactions: Next, we retrieve all interactions with the front pages of the platform for the selected users, making sure to include only those actions that occurred before the purchase.
Creating Aliases for URLs: Since URLs can be long and cumbersome, we use aliases (nicknames) for the URLs to make the user journey more readable.
Combining User Journey: The pages visited during each session are concatenated into a single string for each session, forming a comprehensive journey for the user before their subscription purchase.
Exporting Data: The final result, which includes the user ID, session ID, subscription type, and the complete user journey string, is exported as a CSV file.

# Project Structure
The project consists of several SQL queries that use:
CTEs (Common Table Expressions) to break down complex queries into manageable parts.
GROUP_CONCAT to combine visited pages into a single string per session.
CASE statements to categorize subscription types and other logical conditions.
Aliases to map URLs to human-readable names.
Requirements
MySQL Workbench 8.0 or later is required to run the SQL code.
The provided User_Journey_Database.sql script to set up the database.
An additional file URL_Aliases.xlsx which contains the mapping of URLs to human-readable aliases.
Steps Taken
Data Filtering: Selected users based on their purchase date and price.
Extracting Interactions: Queried the interaction logs, keeping only relevant sessions.
Alias Mapping: Replaced URLs with readable aliases.
Journey Aggregation: Concatenated the sequence of pages into a single string per session.
Export: Exported the final data as a CSV file for further analysis.
CSV Output


# The exported CSV contains four columns:
user_id – The ID of the user.
session_id – The ID of the session.
subscription_type – The type of subscription purchased (Monthly, Quarterly, or Annual).
user_journey – A string representing the sequence of pages visited by the user before their first purchase, separated by dashes.
# How to Run the Project
Set up MySQL Workbench: Install MySQL Workbench 8.0 or later.
Run the SQL script: Import and run the User_Journey_Database.sql script to create the necessary tables and data.
Execute Queries: Run the provided queries in order to extract, process, and export the user journey data.
Export CSV: The final query will export the data to a CSV file named user_journey_data.csv.

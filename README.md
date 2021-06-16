# Profiling database queries
This project can be used to profile database queries, which can be useful when optimizing database queries.
The core functionality lies in the file `profiler.sh`, written in Bash.
The script performs the following tasks:

1. Runs the SQL queries in `setup_database.csv`. This can be used to prepare database and setup environmental variables before running queries for profiling. The first four lines in `setup_database.csv` contains SQL queries for enabling data collection for performance schema profiling and clearing a couple of tables.
2. Runs queries specified in `queries.csv` for profiling. Queries can be run numerous times (configurable via `n_repetitions` variable in script). The script collects average execution time as well as a breakdown of atomic steps in executing a query. Average execution times of queries are stored in `summary.csv`, which is created when the script is run for the first time. Entries in this CSV file are tab-separated and each row includes a time stamp, query, and average execution time. Times for atomic steps are stored as `*.log` files in `performance_logs` folder.
3. Runs SQL queries in `revert_changes.csv`. This can be used to teardown any changes done to the database as a part of setup.
4. Shows a progress bar that indicates the overall status of profiling.

## Running the script

1. Configure your MariaDB user name and password in lines 23-24 in `profiler.sh`:
```
mariadb_username=root
mariadb_password=password
```
2. Set the number of repetitions (i.e., the number of times each query will be executed) by modifying the `n_repetitions` variable in `profiler.sh`. The default value is 10.
3. Run the script by typing the following command in Shell when in the project folder:
```
bash profiler.sh
```

## Specifying queries for profiling

Queries that need to be profiled are specified in `queries.csv` file. Each line contains a database name (if applicable) and the query, separated by a `$` delimiter. You may leave the database name empty for queries that do not require a specific database to be loaded.

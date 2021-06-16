#!/bin/bash
spin() {
    sp='/-\|'
    printf ' '
    while true; do
        printf '\b%.1s' "$sp"
        sp=${sp#?}${sp%???}
        sleep 0.05
    done
}

progressbar()
{
    bar="##################################################"
    barlength=${#bar}
    n=$(($1*barlength/100))
    printf "\r[%-${barlength}s (%d%%)] " "${bar:0:n}" "$1"
}

spin &
pid=$!

mariadb_username=root
mariadb_password=password

declare -i n_repetitions=10

while IFS="$", read -r database_name query
do
    if [[ -z "${database_name}" ]]; then
        mysql -u $mariadb_username -p$mariadb_password -e "$query"
    else
        mysql -u $mariadb_username -p$mariadb_password -e "USE $database_name; $query"
    fi
done < setup_database.csv

no_of_lines=`cat queries.csv | wc -l`
line_index=0
timestamp=`date "+%Y%m%d-%H%M%S"`
> query_output.log

while IFS="$", read -r database_name query
do
    i=1
    total_event_time=0
    while [ "$i" -le "$n_repetitions" ]; do
        query_without_semicolon=`echo ${query%?}`

        search_query="SELECT EVENT_ID, TRUNCATE(TIMER_WAIT/1000000000000,6) as Duration, SQL_TEXT FROM performance_schema.events_statements_history_long WHERE SQL_TEXT LIKE '%$query_without_semicolon%' AND SQL_TEXT NOT LIKE '%performance_schema%' ORDER BY TIMER_END DESC;"

        echo -e "$query\n" >> query_output.log
        mysql -u $mariadb_username -p$mariadb_password -e "USE $database_name; $query" >> query_output.log
        echo -e "\n\n" >> query_output.log

        event_id_string=$(mysql -u $mariadb_username -p$mariadb_password -e "$search_query")

        event_id=`echo $event_id_string | cut -d' ' -f4`
        event_time=`echo $event_id_string | cut -d' ' -f5`

        total_event_time=`expr "$total_event_time+$event_time" | bc`

        profile_query="SELECT event_name AS Stage, TRUNCATE(TIMER_WAIT/1000000000000,6) AS Duration FROM performance_schema.events_stages_history_long WHERE NESTING_EVENT_ID=$event_id;"

        echo -e "\n\n$query" >> performance_logs/$timestamp-performance_log.log
        echo -e "Execution time: $event_time\n" >> performance_logs/$timestamp-performance_log.log

        mysql -u $mariadb_username -p$mariadb_password -e "$profile_query" >> performance_logs/$timestamp-performance_log.log

        if [ "$i" -eq "$n_repetitions" ]
        then
            avg_event_time=`expr "scale=10;$total_event_time/$n_repetitions" | bc`
            echo -e "$timestamp\t$query\t$avg_event_time\n" >> summary.csv
        fi
        progress=`echo "scale=2;100 / $no_of_lines * ($i / $n_repetitions + $line_index)" | bc`
        progressbar `echo ${progress%%.*}`
        i=$(($i + 1))
    done
    line_index=$(($line_index + 1))
done < queries.csv

while IFS="$", read -r database_name query
do
    if [[ -z "$database_name" ]]; then
        mysql -u $mariadb_username -p$mariadb_password -e "$query"
    else
        mysql -u $mariadb_username -p$mariadb_password -e "USE $database_name; $query"
    fi
done < revert_changes.csv

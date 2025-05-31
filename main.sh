#!/bin/bash

DB_DIR="./databases_test"
mkdir -p "$DB_DIR"

# Function to create database
create_database() {
    dbname=$(zenity --entry --title="Create Database" --text="Enter database name:") || return
    mkdir -p "$DB_DIR/$dbname"
    zenity --info --text="Database '$dbname' created."
}

# Function to list databases
list_databases() {
    dblist=$(ls "$DB_DIR")
    zenity --info --title="Databases" --text="Available Databases:\n$dblist"
}

# Function to drop database
drop_database() {
    dbname=$(zenity --entry --title="Drop Database" --text="Enter database name to delete:") || return
    rm -r "$DB_DIR/$dbname" 2>/dev/null && \
    zenity --info --text="Database '$dbname' deleted." || \
    zenity --error --text="Database '$dbname' not found."
}

# Function to connect to a database
connect_database() {
    dbname=$(zenity --entry --title="Connect To Database" --text="Enter database name to connect:") || return
    if [ ! -d "$DB_DIR/$dbname" ]; then
        zenity --error --text="Database '$dbname' not found."
        return
    fi

    while true; do
        action=$(zenity --list --title="Connected to '$dbname'" --column="Action" \
            "Create Table" "List Tables" "Drop Table" "Insert into Table" \
            "Select From Table" "Update Table" "Delete From Table" "Back to Main Menu") || break

        case "$action" in
            "Create Table")
                tablename=$(zenity --entry --title="Create Table" --text="Enter table name:") || continue
                table_file="$DB_DIR/$dbname/$tablename"
                meta_file="$table_file.meta"
                if [ -f "$table_file" ]; then
                    zenity --error --text="Table already exists."
                    continue
                fi
                
                col_count=$(zenity --entry --title="Columns Count" --text="How many columns?") || continue
                columns=()
                pk_set=false

                for (( i=1; i<=col_count; i++ )); do
                    col_name=$(zenity --entry --text="Enter name of column $i:") || return
                    col_type=$(zenity --list --title="Column Type" --text="Select datatype for '$col_name'" \
                        --radiolist --column "Pick" --column "Type" TRUE "string" FALSE "number") || return
                    is_pk=$(zenity --list --title="Primary Key" --text="Is '$col_name' primary key?" \
                        --radiolist --column "Pick" --column "Answer" TRUE "no" FALSE "yes") || return

                    if [[ "$is_pk" == "yes" && "$pk_set" == false ]]; then
                        columns+=("$col_name:$col_type:pk")
                        pk_set=true
                    else
                        columns+=("$col_name:$col_type")
                    fi
                done

                touch "$table_file"
                for col in "${columns[@]}"; do echo "$col" >> "$meta_file"; done
                zenity --info --text="Table '$tablename' created successfully."
                ;;

            "List Tables")
                tablelist=$(ls "$DB_DIR/$dbname")
                zenity --info --title="Tables in $dbname" --text="$tablelist"
                ;;

            "Drop Table")
                tablename=$(zenity --entry --title="Drop Table" --text="Enter table name to delete:") || continue
                rm "$DB_DIR/$dbname/$tablename" "$DB_DIR/$dbname/$tablename.meta" 2>/dev/null && \
                zenity --info --text="Table '$tablename' deleted." || \
                zenity --error --text="Table not found."
                ;;

            "Insert into Table")
                tablename=$(zenity --entry --text="Enter Table Name:") || continue
                table_file="$DB_DIR/$dbname/$tablename"
                meta_file="$table_file.meta"
                [ ! -f "$table_file" ] && zenity --error --text="Table does not exist." && continue
                
                mapfile -t columns < "$meta_file"
                row=()
                pk_index=-1

                for (( i=0; i<${#columns[@]}; i++ )); do
                    IFS=":" read col_name col_type pk_flag <<< "${columns[$i]}"
                    value=$(zenity --entry --text="Enter value for $col_name (type: $col_type):") || return
                    if [ "$col_type" == "number" ] && ! [[ "$value" =~ ^[0-9]+$ ]]; then
                        zenity --error --text="Invalid number." && continue 2
                    fi

                    if [ "$pk_flag" == "pk" ]; then
                        pk_index=$i
                        if cut -d: -f$((pk_index+1)) "$table_file" | grep -qx "$value"; then
                            zenity --error --text="Primary key already exists." && continue 2
                        fi
                    fi
                    row+=("$value")
                done

                (IFS=":"; echo "${row[*]}") >> "$table_file"
                zenity --info --text="Row inserted."
                ;;

            "Select From Table")
                tablename=$(zenity --entry --text="Enter Table Name:") || continue
                table_file="$DB_DIR/$dbname/$tablename"
                meta_file="$table_file.meta"
                [ ! -f "$table_file" ] && zenity --error --text="Table does not exist." && continue
                
                result=$(cat "$table_file" | sed 's/:/ | /g')
                zenity --text-info --title="Data in $tablename" --filename=<(echo "$result")
                ;;

            "Update Table")
                tablename=$(zenity --entry --text="Enter Table Name:") || continue
                table_file="$DB_DIR/$dbname/$tablename"
                meta_file="$table_file.meta"
                [ ! -f "$table_file" ] && zenity --error --text="Table does not exist." && continue

                mapfile -t columns < "$meta_file"
                pk_index=-1
                for (( i=0; i<${#columns[@]}; i++ )); do
                    IFS=":" read col_name col_type pk_flag <<< "${columns[$i]}"
                    if [ "$pk_flag" == "pk" ]; then pk_index=$i; break; fi
                done
                [ $pk_index -eq -1 ] && zenity --error --text="No primary key found." && continue
                
                pk_value=$(zenity --entry --text="Enter Primary Key value of row to update:") || continue
                row_number=0
                found=false
                while IFS= read -r line; do
                    IFS=":" read -ra row_values <<< "$line"
                    if [ "${row_values[$pk_index]}" == "$pk_value" ]; then found=true; break; fi
                    ((row_number++))
                done < "$table_file"
                [ "$found" = false ] && zenity --error --text="Row not found." && continue

                new_row=()
                for (( i=0; i<${#columns[@]}; i++ )); do
                    IFS=":" read col_name col_type pk_flag <<< "${columns[$i]}"
                    if [ $i -eq $pk_index ]; then
                        new_row+=("${row_values[$i]}")
                    else
                        value=$(zenity --entry --text="New value for $col_name (current: ${row_values[$i]}):") || return
                        [ "$col_type" == "number" ] && ! [[ "$value" =~ ^[0-9]+$ ]] && zenity --error --text="Invalid number." && continue 2
                        new_row+=("$value")
                    fi
                done

                temp_file=$(mktemp)
                awk -v row_num="$row_number" -v new_row="$(IFS=":"; echo "${new_row[*]}")" 'NR==row_num+1{print new_row; next} {print}' "$table_file" > "$temp_file"
                mv "$temp_file" "$table_file"
                zenity --info --text="Row updated."
                ;;

            "Delete From Table")
                tablename=$(zenity --entry --text="Enter Table Name:") || continue
                table_file="$DB_DIR/$dbname/$tablename"
                meta_file="$table_file.meta"
                [ ! -f "$table_file" ] && zenity --error --text="Table does not exist." && continue

                mapfile -t columns < "$meta_file"
                pk_index=-1
                for (( i=0; i<${#columns[@]}; i++ )); do
                    IFS=":" read col_name col_type pk_flag <<< "${columns[$i]}"
                    if [ "$pk_flag" == "pk" ]; then pk_index=$i; break; fi
                done
                [ $pk_index -eq -1 ] && zenity --error --text="No primary key defined." && continue
                
                pk_value=$(zenity --entry --text="Enter Primary Key value to delete:") || continue
                temp_file=$(mktemp)
                found=false
                while IFS= read -r line; do
                    IFS=":" read -ra row_values <<< "$line"
                    if [ "${row_values[$pk_index]}" == "$pk_value" ]; then found=true; continue; fi
                    echo "$line" >> "$temp_file"
                done < "$table_file"
                [ "$found" = true ] && mv "$temp_file" "$table_file" && zenity --info --text="Row deleted." || \
                zenity --error --text="Row not found." && rm "$temp_file"
                ;;

            "Back to Main Menu")
                break
                ;;
        esac
    done
}

# Main menu
while true; do
    main_choice=$(zenity --list --title="Main Menu" --column="Choose an action" \
        "Create Database" "List Databases" "Connect To Database" "Drop Database" "Exit") || break

    case "$main_choice" in
        "Create Database") create_database ;;
        "List Databases") list_databases ;;
        "Connect To Database") connect_database ;;
        "Drop Database") drop_database ;;
        "Exit") 
         zenity --info --text="Bye Bye 👋"
        break ;;
    esac
done

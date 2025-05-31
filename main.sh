#!/bin/bash

DB_DIR="./databases_test"

if [ ! -d "$DB_DIR" ] ; then
 mkdir "$DB_DIR"
 fi

while true; do
    echo "===== Main Menu ====="
        select choice in "Create Database" "List Databases" "Connect To Database" "Drop Database" "Exit"
        do

        case $choice in
            "Create Database")
                read -p "Enter database name:" dbname
                mkdir "$DB_DIR/$dbname"
                echo "Database '$dbname' created."
                break
                ;;
            "List Databases")
                echo "Available Databases:"
                ls "$DB_DIR"
                break
                ;;
            "Connect To Database")
                read -p "Enter database name to connect:" dbname
                if [ -d "$DB_DIR/$dbname" ]; then
                    echo "Connected to '$dbname'"
                    #--------
                    while true; do
                    echo "===== Tables Menu for '$dbname' ====="
                    select table_action in "Create Table" "List Tables" "Drop Table" "Insert into Table" "Update Table" "Delete From Table" "Select From Table" "Back to Main Menu"
                    do
                    case $table_action in
                    "Create Table")
                     read -p "Enter Table Name:" tablename
                    table_file="$DB_DIR/$dbname/$tablename"
                    meta_file="$table_file.meta"

                    if [ -f "$table_file" ]; then
                      echo "Table already exists."
                    else
                     echo "How many columns?"
                      read col_count

                      columns=() # array store column names
                      datatypes=() # array store column datatypes
                      pk_set=false 

                    for (( i=1; i<=col_count; i++ ))
                    do
                    read -p "Enter name of column $i:" col_name
                    echo "Enter datatype of $col_name (string/number):"
                    read col_type
                    col_type=$(echo "$col_type" | tr '[:upper:]' '[:lower:]')

                    # check if datatype is valid or not
                    while [[ "$col_type" != "string" && "$col_type" != "number" ]]; do 
                     read  -p "Invalid datatype.$\n Enter string or number:" col_type
                    done
                    read -p "Is this column the Primary Key? (yes/no):" is_pk
                    is_pk=$(echo "$is_pk" | tr '[:upper:]' '[:lower:]')

                   if [[ "$is_pk" == "yes" && "$pk_set" == false ]]; then
                      columns+=("$col_name:$col_type:pk")
                      pk_set=true
                   else
                   columns+=("$col_name:$col_type")
                   fi
                   done

                    # Create file for data to insert into it 
                    touch "$table_file"

                    # Write meta file 
                    for col in "${columns[@]}"; do
                        echo "$col" >> "$meta_file"
                    done

                        echo "Table '$tablename' created with metadata."
                    fi
                    break
                    ;;
                    "List Tables")
                    echo "Tables in '$dbname':"
                    ls "$DB_DIR/$dbname"
                    break
                    ;;
                    "Drop Table")
                    read  -p "Enter table name to delete:" tablename
                    rm "$DB_DIR/$dbname/$tablename"
                    echo "Table '$tablename' deleted."
                    break
                    ;;
                    "Back to Main Menu")
                    break 2
                    ;;
                    # /////////
                    "Insert into Table")
                    read -p "Enter Table Name:" tablename
                    table_file="$DB_DIR/$dbname/$tablename"
                    meta_file="$table_file.meta"

                    if [ ! -f "$table_file" ]; then
                        echo "Table does not exist."
                    else
                        mapfile -t columns < "$meta_file"
                        row=()
                        pk_index=-1

                        for (( i=0; i<${#columns[@]}; i++ )); do
                            IFS=":" read col_name col_type pk_flag <<< "${columns[$i]}"
                            echo "Enter value for $col_name (type: $col_type):"
                            read value
                                # check data type
                            if [ "$col_type" == "number" ]; then
                                while ! [[ "$value" =~ ^[0-9]+$ ]]; do
                                    echo "Invalid. Enter a number:"
                                    read value
                                done
                            fi

                            # check pk
                            if [ "$pk_flag" == "pk" ]; then
                                pk_index=$i
                                pk_value="$value"

                                # check no repeat for pk
                                if cut -d: -f$((pk_index+1)) "$table_file" | grep -qx "$pk_value"; then
                                    echo "Error: Primary key already exists!"
                                    break 2
                                fi
                            fi

                            row+=("$value")
                            done
                            # insert row into table
                            (IFS=:; echo "${row[*]}") >> "$table_file"
                            echo "Row inserted successfully."
                            fi
                            break
                            ;;
                        "Select From Table")
                            read -p "Enter Table Name: " tablename
                            table_file="$DB_DIR/$dbname/$tablename"
                            meta_file="$table_file.meta"

                            if [ ! -f "$table_file" ]; then
                                echo "Table does not exist."
                            else
                                mapfile -t columns < "$meta_file"
                                header=""
                                for col in "${columns[@]}"; do
                                    IFS=":" read col_name _ <<< "$col"
                                    header+="$col_name\t| "
                                done
                                echo -e "$header"
                                echo "----------------------------------------"
                                while IFS= read -r line; do
                                    echo -e "$(echo "$line" | tr ':' '\t| ')"
                                done < "$table_file"
                            fi
                            break
                            ;;
                            "Update Table")
                            read -p "Enter Table Name: " tablename
                            table_file="$DB_DIR/$dbname/$tablename"
                            meta_file="$table_file.meta"

                            if [ ! -f "$table_file" ]; then
                                echo "Table does not exist."
                            else
                                # Display table content first
                                echo "Current table content:"
                                mapfile -t columns < "$meta_file"
                                header=""
                                for col in "${columns[@]}"; do
                                    IFS=":" read col_name _ <<< "$col"
                                    header+="$col_name\t| "
                                done
                                echo -e "$header"
                                echo "----------------------------------------"
                                while IFS= read -r line; do
                                    echo -e "$(echo "$line" | tr ':' '\t| ')"
                                done < "$table_file"

                                # Get primary key info
                                pk_index=-1
                                for (( i=0; i<${#columns[@]}; i++ )); do
                                    IFS=":" read col_name col_type pk_flag <<< "${columns[$i]}"
                                    if [ "$pk_flag" == "pk" ]; then
                                        pk_index=$i
                                        break
                                    fi
                                done

                                if [ $pk_index -eq -1 ]; then
                                    echo "Error: No primary key defined for this table."
                                    break
                                fi

                                read -p "Enter primary key value of the row to update: " pk_value
                                
                                # Find the row to update
                                row_found=false
                                row_number=0
                                while IFS= read -r line; do
                                    IFS=':' read -ra row_values <<< "$line"
                                    if [ "${row_values[$pk_index]}" == "$pk_value" ]; then
                                        row_found=true
                                        break
                                    fi
                                    ((row_number++))
                                done < "$table_file"

                                if [ "$row_found" == false ]; then
                                    echo "Error: Row with primary key '$pk_value' not found."
                                    break
                                fi

                                # Get new values for each column
                                new_row=()
                                for (( i=0; i<${#columns[@]}; i++ )); do
                                    IFS=":" read col_name col_type pk_flag <<< "${columns[$i]}"
                                    if [ $i -eq $pk_index ]; then
                                        # Skip primary key column (can't update PK)
                                        new_row+=("${row_values[$i]}")
                                        echo "Primary key column '$col_name' cannot be updated (value remains: ${row_values[$i]})"
                                    else
                                        read -p "Enter new value for $col_name (type: $col_type, current: ${row_values[$i]}): " value
                                        
                                        # Validate data type
                                        if [ "$col_type" == "number" ]; then
                                            while ! [[ "$value" =~ ^[0-9]+$ ]]; do
                                                echo "Invalid. Enter a number:"
                                                read value
                                            done
                                        fi
                                        
                                        new_row+=("$value")
                                    fi
                                done

                                # Update the file
                                temp_file=$(mktemp)
                                awk -v row_num="$row_number" -v new_row="$(IFS=:; echo "${new_row[*]}")" '
                                    NR == row_num+1 { print new_row; next }
                                    { print }
                                ' "$table_file" > "$temp_file" && mv "$temp_file" "$table_file"
                                
                                echo "Row updated successfully."
                            fi
                            break
                            ;;
                        "Delete From Table")
                            read -p "Enter Table Name: " tablename
                            table_file="$DB_DIR/$dbname/$tablename"
                            meta_file="$table_file.meta"

                            if [ ! -f "$table_file" ]; then
                                echo "Table does not exist."
                            else
                                # Display table content first
                                echo "Current table content:"
                                mapfile -t columns < "$meta_file"
                                header=""
                                for col in "${columns[@]}"; do
                                    IFS=":" read col_name _ <<< "$col"
                                    header+="$col_name\t| "
                                done
                                echo -e "$header"
                                echo "----------------------------------------"
                                while IFS= read -r line; do
                                    echo -e "$(echo "$line" | tr ':' '\t| ')"
                                done < "$table_file"

                                # Get primary key info
                                pk_index=-1
                                for (( i=0; i<${#columns[@]}; i++ )); do
                                    IFS=":" read col_name col_type pk_flag <<< "${columns[$i]}"
                                    if [ "$pk_flag" == "pk" ]; then
                                        pk_index=$i
                                        break
                                    fi
                                done

                                if [ $pk_index -eq -1 ]; then
                                    echo "Error: No primary key defined for this table."
                                    break
                                fi

                                read -p "Enter primary key value of the row to delete: " pk_value
                                
                                # Find and delete the row
                                temp_file=$(mktemp)
                                found=false
                                while IFS= read -r line; do
                                    IFS=':' read -ra row_values <<< "$line"
                                    if [ "${row_values[$pk_index]}" == "$pk_value" ]; then
                                        found=true
                                        continue  # skip this line (delete it)
                                    fi
                                    echo "$line" >> "$temp_file"
                                done < "$table_file"

                                if [ "$found" == true ]; then
                                    mv "$temp_file" "$table_file"
                                    echo "Row deleted successfully."
                                else
                                    rm "$temp_file"
                                    echo "Error: Row with primary key '$pk_value' not found."
                                fi
                            fi
                            break
                            ;;
                        "Back to Main Menu")
                            break 2
                            ;;
                        *)
                            echo "Invalid choice. Try again."
                            break
                            ;;
                            esac
                        done
                    done
                else
                echo "Database not found."
            fi
            break
            ;;
        "Drop Database")
            read -p "Enter database name to delete:" dbname
            rm -r "$DB_DIR/$dbname"
            echo "Database '$dbname' deleted."
            break
            ;;
        "Exit")
            echo "Bye!"
            exit
            ;;
            *) echo "Invalid choice, try again."; break ;;
        esac
    done
done


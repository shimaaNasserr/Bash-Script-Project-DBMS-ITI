#!/bin/bash

DB_DIR="./databases_test"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
PURPLE='\033[0;35m'
NC='\033[0m' 

if [ ! -d "$DB_DIR" ] ; then
 mkdir "$DB_DIR"
 fi

while true; do
    PS3="Enter Your Value# "
    echo -e "${CYAN}===== Main Menu =====${NC}"
        select choice in "Create Database" "List Databases" "Connect To Database" "Drop Database" "Exit"
        do

        case $choice in
            "Create Database")
                echo -ne "${CYAN}Enter database name:${NC}"
                read dbname
                mkdir "$DB_DIR/$dbname"
                echo -e "${GREEN}Database '$dbname' created.${NC}"
               break
                ;;
            "List Databases")
                echo -e "${YELLOW}Available Databases:${NC}"
                ls "$DB_DIR"
                break
                ;;
            "Connect To Database")
                read -p "$(echo -e "${CYAN}Enter database name to connect:${NC}") " dbname
                if [ -d "$DB_DIR/$dbname" ]; then
                    echo -e "${GREEN}Connected to '$dbname'${NC}"
                    #--------
                    while true; do
                    echo -e "${CYAN}===== Tables Menu for '$dbname' =====${NC}"
                    PS3="Enter Your Value# "
                    select table_action in "Create Table" "List Tables" "Drop Table" "Select From Table" "Insert into Table" "Update Table" "Delete From Table" "Back to Main Menu"
                    do
                    case $table_action in
                    "Create Table")
                    read -p "$(echo -e "${CYAN}Enter Table Name:${NC}") " tablename
                    table_file="$DB_DIR/$dbname/$tablename"
                    meta_file="$table_file.meta"

                    if [ -f "$table_file" ]; then
                            echo -e "${RED}Table already exists.${NC}"
                        else
                            echo -e "${CYAN}How many columns?${NC}"
                            read col_count

                      columns=() # array store column names
                      datatypes=() # array store column datatypes
                      pk_set=false 

                    for (( i=1; i<=col_count; i++ ))
                    do
                        read -p "$(echo -e "${CYAN}Enter name of column $i:${NC}") " col_name
                        echo -e "${CYAN}Enter datatype of $col_name (string/number):${NC}"
                        read col_type
                        col_type=$(echo "$col_type" | tr '[:upper:]' '[:lower:]')

                    # check if datatype is valid or not
                    while [[ "$col_type" != "string" && "$col_type" != "number" ]]; do 
                     read -p "$(echo -e "${RED}Invalid datatype. Enter string or number:${NC}") " col_type
                    done
                    read -p "$(echo -e "${CYAN}Is this column the Primary Key? (yes/no):${NC}") " is_pk
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

                        echo -e "${GREEN}Table '$tablename' created with metadata.${NC}"
                    fi
                    break
                    ;;
                    "List Tables")
                    echo -e "${YELLOW}Tables in '$dbname':${NC}:"
                    ls "$DB_DIR/$dbname"
                    break
                    ;;
                    "Drop Table")
                    read -p "$(echo -e "${CYAN}Enter table name to delete:${NC}") " tablename
                    rm "$DB_DIR/$dbname/$tablename"
                    echo -e "${RED}Table '$tablename' deleted.${NC}"
                    break
                    ;;
                    "Select From Table")
                            read -p "$(echo -e "${CYAN}Enter Table Name:${NC}") " tablename
                            table_file="$DB_DIR/$dbname/$tablename"
                            meta_file="$table_file.meta"

                            if [ ! -f "$table_file" ]; then
                                echo -e "${RED}Table does not exist.${NC}"
                            else
                                mapfile -t columns < "$meta_file"
                            headSer=""
                            for col in "${columns[@]}"; do
                                IFS=":" read col_name _ <<< "$col"
                                header+="$col_name | "
                            done
                            echo -e "${BLUE}$header${NC}" | column -t -s '|'
                            echo -e "${BLUE}----------------------------------------${NC}"
                            cat "$table_file" | tr ':' '|' | column -t -s '|' | while IFS= read -r line; do
                                echo -e "$line"
                            done
                            fi
                            break
                            ;;
                    "Back to Main Menu")
                    break 2
                    ;;
                    "Insert into Table")
                    read -p "$(echo -e "${CYAN}Enter Table Name:${NC}") " tablename
                    table_file="$DB_DIR/$dbname/$tablename"
                    meta_file="$table_file.meta"

                    if [ ! -f "$table_file" ]; then
                        echo -e "${RED}Table does not exist.${NC}"
                    else
                    echo -e "${YELLOW}Current table content:${NC}"
                        mapfile -t columns < "$meta_file"
                        row=()
                        pk_index=-1

                        for (( i=0; i<${#columns[@]}; i++ )); do
                            IFS=":" read col_name col_type pk_flag <<< "${columns[$i]}"
                            echo -e "${CYAN}Enter value for $col_name (type: $col_type):${NC}"
                            read value
                                # check data type
                            if [ "$col_type" == "number" ]; then
                                while ! [[ "$value" =~ ^[0-9]+$ ]]; do
                                    echo -e "${RED}Invalid. Enter a number:${NC}"
                                    read value
                                done
                            fi

                            # check pk
                            if [ "$pk_flag" == "pk" ]; then
                                pk_index=$i
                                pk_value="$value"

                                # check no repeat for pk
                                if cut -d: -f$((pk_index+1)) "$table_file" | grep -qx "$pk_value"; then
                                    echo -e "${RED}Error: Primary key already exists!${NC}"
                                    break 2
                                fi
                            fi

                            row+=("$value")
                            done
                            # insert row into table
                            (IFS=:; echo "${row[*]}") >> "$table_file"
                            echo -e "${GREEN}Row inserted successfully.${NC}"
                            fi
                            break
                            ;;
                            "Update Table")
                            read -p "$(echo -e "${CYAN}Enter Table Name:${NC}") " tablename
                            table_file="$DB_DIR/$dbname/$tablename"
                            meta_file="$table_file.meta"

                            if [ ! -f "$table_file" ]; then
                                echo -e "${RED}Table does not exist.${NC}"
                            else
                                # Display table content first
                                mapfile -t columns < "$meta_file"
                                header=""
                                for col in "${columns[@]}"; do
                                    IFS=":" read col_name _ <<< "$col"
                                    header+="$col_name | "
                                done
                                echo -e "${BLUE}$header${NC}" | column -t -s '|'
                                echo -e "${BLUE}----------------------------------------${NC}"
                                cat "$table_file" | tr ':' '|' | column -t -s '|' | while IFS= read -r line; do
                                    echo -e "$line"
                                done

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
                                    echo -e "${RED}Error: No primary key defined for this table.${NC}"
                                    break
                                fi

                                read -p "$(echo -e "${CYAN}Enter primary key value of the row to update:${NC}") " pk_value
                                
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
                                    echo -e "${RED}Error: Row with primary key '$pk_value' not found.${NC}"
                                    break
                                fi

                                # Get new values for each column
                                new_row=()
                                for (( i=0; i<${#columns[@]}; i++ )); do
                                    IFS=":" read col_name col_type pk_flag <<< "${columns[$i]}"
                                    if [ $i -eq $pk_index ]; then
                                        # Skip primary key column (can't update PK)
                                        new_row+=("${row_values[$i]}")
                                        echo -e "${RED}Primary key column '$col_name' cannot be updated (value remains: ${row_values[$i]})${NC}"
                                    else
                                        read -p "$(echo -e "${CYAN}Enter new value for $col_name (type: $col_type, current: ${row_values[$i]}):${NC}") " value
                                        
                                        # Validate data type
                                        if [ "$col_type" == "number" ]; then
                                            while ! [[ "$value" =~ ^[0-9]+$ ]]; do
                                                echo -e "${RED}Invalid. Enter a number:${NC}"
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
                                
                                echo -e "${PURPLE}Row updated successfully.${NC}"
                            fi
                            break
                            ;;
                        "Delete From Table")
                            read -p "$(echo -e "${CYAN}Enter Table Name:${NC}") " tablename
                            table_file="$DB_DIR/$dbname/$tablename"
                            meta_file="$table_file.meta"

                            if [ ! -f "$table_file" ]; then
                                echo -e "${RED}Table does not exist.${NC}"
                            else
                                # Display table content first
                                echo -e "${YELLOW}Current table content:${NC}"
                                mapfile -t columns < "$meta_file"
                                header=""
                                for col in "${columns[@]}"; do
                                    IFS=":" read col_name _ <<< "$col"
                                    header+="$col_name\t| "
                                done
                                 echo -e "${BLUE}$header${NC}"
                                 echo -e "${BLUE}----------------------------------------${NC}"
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
                                    echo -e "${RED}Error: No primary key defined for this table.${NC}"
                                    break
                                fi

                                read -p "$(echo -e "${CYAN}Enter primary key value of the row to delete:${NC}") " pk_value
                                
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
                                    echo -e "${RED}Row deleted successfully.${NC}"
                                else
                                    rm "$temp_file"
                                    echo -e "${RED}Error: Row with primary key '$pk_value' not found.${NC}"
                                fi
                            fi
                            break
                            ;;
                        "Back to Main Menu")
                            break 2
                            ;;
                        *)
                            echo -e "${RED}Invalid choice. Try again.${NC}"
                            break
                            ;;
                            esac
                        done
                    done
                else
                echo -e "${RED}Database not found.${NC}"
            fi
            break
            ;;
        "Drop Database")
            read -p "$(echo -e "${CYAN}Enter database name to delete:${NC}") " dbname
            rm -r "$DB_DIR/$dbname"
            echo -e "${RED}Database '$dbname' deleted.${NC}"
            break
            ;;
        "Exit")
            echo -e "${YELLOW}ByeBye👋!!${NC}"
            exit
            ;;
            *) echo -e "${RED}Invalid choice, try again.${NC}"; break ;;
        esac
    done
done


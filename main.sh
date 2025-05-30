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
                echo "Enter database name:"
                read dbname
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
                echo "Enter database name to connect:"
                read dbname
                if [ -d "$DB_DIR/$dbname" ]; then
                    echo "Connected to '$dbname'"
                    #--------
                    while true; do
                    echo "===== Tables Menu for '$dbname' ====="
                    select table_action in "Create Table" "List Tables" "Insert into Table" "Select From Table" "Drop Table" "Back to Main Menu"
                    do
                    case $table_action in
                        "Create Table")
                        echo "Enter table name:"
                        read tablename
                        touch "$DB_DIR/$dbname/$tablename"
                        echo "Table '$tablename' created."
                        break
                        ;;
                        "List Tables")
                        echo "Tables in '$dbname':"
                        ls "$DB_DIR/$dbname"
                        break
                        ;;
                        "Drop Table")
                        echo "Enter table name to delete:"
                        read tablename
                        rm "$DB_DIR/$dbname/$tablename"
                        echo "Table '$tablename' deleted."
                        break
                        ;;
                        "Insert into Table")
                        echo "Enter table name:"
                        read tablename
                        table_path="$DB_DIR/$dbname/$tablename"
                        
                        if [ -f "$table_path" ]; then
                            echo "Enter data (format: name=value:type)"
                            echo "Types: str, int, or float"
                            read -p "Example: age=25:int " new_data
                            
                            if [[ "$new_data" == *":str"* || "$new_data" == *":int"* || "$new_data" == *":float"* ]]; then
                                echo "$new_data" >> "$table_path"
                                echo "Data inserted!"
                            else
                                echo "Error: Missing or invalid type (:str/:int/:float)"
                            fi
                        else
                            echo "Table doesn't exist"
                        fi
                        break
                        ;;
                        "Select From Table")
                        echo "Enter table name to view:"
                        read tablename
                        table_path="$DB_DIR/$dbname/$tablename"
                        
                        if [ -f "$table_path" ]; then
                            echo -e "\nContents of '$tablename':"
                            echo "==========="
                            cat "$table_path"
                            echo "==========="
                            
                            echo "Enter search term (or leave blank to skip):"
                            read search_term
                            if [ -n "$search_term" ]; then
                                echo -e "\nSearch results:"
                                echo "============="
                                if grep -q "$search_term" "$table_path"; then
                                    grep "$search_term" "$table_path"
                                else
                                    echo "No matches found for '$search_term'"
                                fi
                                echo "============="
                            fi
                        else
                            echo "Table '$tablename' does not exist."
                        fi
                        break
                        ;;
                        "Back to Main Menu")
                        break 2
                        ;;
                        *) echo "Invalid choice. Try again."; break ;;
                    esac
                    done
                done
            #----------
            else
                echo "Database not found."
            fi
            break
            ;;
        "Drop Database")
            echo "Enter database name to delete:"
            read dbname
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


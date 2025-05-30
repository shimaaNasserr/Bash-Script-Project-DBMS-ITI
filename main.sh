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
                    select table_action in "Create Table" "List Tables" "Drop Table" "Back to Main Menu"
                    do
                    case $table_action in
                    #----------
                    "Create Table")
                     echo "Enter Table Name:"
                     read tablename
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
                    echo "Enter name of column $i:"
                    read col_name

                    echo "Enter datatype of $col_name (string/number):"
                    read col_type

                    # check if datatype is valid or not
                    while [[ "$col_type" != "string" && "$col_type" != "number" ]]; do
                     echo "Invalid datatype. Enter string or number:"
                     read col_type
                    done

                    echo "Is this column the Primary Key? (yes/no):"
                    read is_pk

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
                        echo "Enter table name to delete:"
                        read tablename
                        rm "$DB_DIR/$dbname/$tablename"
                        echo "Table '$tablename' deleted."
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


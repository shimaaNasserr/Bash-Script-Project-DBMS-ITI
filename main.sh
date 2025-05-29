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
                    while true; do

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


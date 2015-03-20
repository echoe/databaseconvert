#!/bin/sh
#Database Convert, Version 0.04
#Converts MyISAM tables to InnoDB or vice versa.
converttable() {
database=$1
    table=$2
    tabletypeconvert=$3
    tabletype=$(mysql -e "SELECT ENGINE FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME='$table' AND TABLE_SCHEMA='$database';" | tail -n+2)
#check to see which table it is, and fix it with a preferred method for each as needed
    if [ $tabletype == "MyISAM" ]; then
      if [[ $tabletypeconvert == "InnoDB" ]]; then
        echo "$table in $database is MyISAM, converting to InnoDB." | tee -a /tmp/dblogfile
        mysql -e "use $database; ALTER TABLE $table ENGINE = InnoDB" | tee -a /tmp/dblogfile
      fi
    elif [ $tabletype == "InnoDB" ]; then
      if [[ $tabletypeconvert == "MyISAM" ]]; then
        echo "$table in $database is InnoDB, converting to MyISAM." | tee -a /tmp/dblogfile
        mysql -e "use $database; ALTER TABLE $table ENGINE = MyISAM" | tee -a /tmp/dblogfile
      fi
    fi
}
#here's the 'database blacklist'!
listofdatabases=$(mysql -e "SHOW DATABASES;"|tail -n+2|grep -v mysql | grep -v information_schema | grep -v roundcube | grep -v horde | grep -v logaholicDB | grep -v cphulkd|grep -v whmxfer|grep -v tmpdir|grep -v performance_schema|grep -v modsec|grep -v leechprotect|grep -v eximstats)

echo -e "Welcome to Database Changer."
echo -e "Would you like to change to InnoDB from MyISAM, or to MyISAM from InnoDB? Type \"InnoDB\" to convert TO InnoDB, and \"MyISAM\" to convert TO MyISAM."
read tabletypeconvert
while [[ $tabletypeconvert != "InnoDB" && $tabletypeconvert != "MyISAM" ]]; do
  echo "Please type a correct input to convert tables to. Either InnoDB, or MyISAM. If you would like to use a different functionality, please exit out of the script and restart it."
  read tabletypeconvert
done
echo -e "You are converting to $tabletypeconvert . If you would like to convert a specific database, please type it now, or: type i for a list of tables using InnoDB, or m for a list of tables using MyISAM."
read database
if [[ $database == "i" ]]; then
  for adatabase in $listofdatabases; do echo $adatabase; mysql -e "SELECT table_name FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = '$adatabase' AND engine = 'InnoDB';"; done
  echo -e "If you would like to convert a specific database, please type it now."
  read database
fi
if [[ $database == "m" ]]; then
  for adatabase in $listofdatabases; do echo $adatabase; mysql -e "SELECT table_name FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = '$adatabase' AND engine = 'MyISAM';"; done
  echo -e "If you would like to convert a specific database, please type it now."
  read database
fi
if [[ $database != "" ]]; then
  iscorrect="no"
  for adatabase in $listofdatabases; do if [[ $adatabase == $database ]]; then iscorrect="yes"; fi; done
  if [[ $iscorrect == "no" ]]; then echo "This is now exiting. In the future, please type a correct database. It has to be one of these: $listofdatabases ."; exit 0; fi
  echo -e "Please provide the table if you want to convert a specific table, or enter t for a list of tables sorted by InnoDB or MyISAM."
  read table
  if [[ $table == "t" ]]; then
    echo "These are MyISAM:"
    echo `mysql -e "SELECT table_name FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = '$database' AND engine = 'MyISAM';"`
    echo "These are InnoDB:"
    echo `mysql -e "SELECT table_name FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = '$database' AND engine = 'InnoDB';"`
    echo -e "Please provide the table if you want to fix a specific table."
    read table
  fi
  if [[ $table != "" ]]; then
    iscorrect="no"
    for atable in $(mysql -e "use $database; show tables;"); do if [[ $atable == $table ]]; then iscorrect="yes"; fi; done
    if [[ $iscorrect == "no" ]]; then echo "You misspelled the table, as it doesn't appear to be within the tables within this database! Please run the script again. For the database $database , you'll want to pick one of these tables:" $(mysql -e "use $database; show tables;"); exit 0; fi
    converttable $database $table $tabletypeconvert
  else for table in $(mysql -e "use $database; show tables;" | tail -n+2); do
      converttable $database $table $tabletypeconvert
    done
  fi
  echo "Thanks for using databaseconvert.sh . You converted tables to $tabletypeconvert . Have a good day. :D"
  exit
fi

if [[ $database == "" ]]; then
  echo "Are you sure you want to convert all tables to $tabletypeconvert ? Type 'yes' if so."
  read sure
  if [[ $sure == "yes" ]]; then
    for adatabase in $listofdatabases; do
      for table in $(mysql -e "use $adatabase; show tables;" | tail -n+2); do
        converttable $adatabase $table $tabletypeconvert
      done
    done
    echo "Thanks for using databaseconvert.sh . You converted tables to $tabletypeconvert . Have a good day. :D"
    exit
  fi
  echo "Be sure next time and this will be done then."
fi

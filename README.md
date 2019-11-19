# NAME

Mojo::mysql::Database::Role::LoadDataInfile - Easy load data infile support for Mojo::mysql

# STATUS

<div>
    <a href="https://travis-ci.org/srchulo/Mojo-mysql-Database-Role-LoadDataInfile"><img src="https://travis-ci.org/srchulo/Mojo-mysql-Database-Role-LoadDataInfile.svg?branch=master"></a>
</div>

# SYNOPSIS

    use Mojo::mysql;
    use Mojo::mysql::Database::Role::LoadDataInfile;

    my $mysql   = Mojo::mysql->new(...);
    my $results = $mysql->db->load_data_infile(
      table => 'people',
      rows => [
        {
          name => 'Bob',
          age  => 23,
        },
        {
          name => 'Alice',
          age  => 25,
        },
      ],
    );

    print $results->affected_rows . " affected rows\n";

    # use promises for non-blocking queries
    my $promise = $mysql->db->load_data_infile_p(
      table => 'people',
      rows => [
        {
          name => 'Bob',
          age  => 23,
        },
        {
          name => 'Alice',
          age  => 25,
        },
      ],
    );

    $promise->then(sub {
      my $results = shift;
      print $results->affected_rows . " affected rows\n";
    })->catch(sub {
      my $err = shift;
      warn "Something went wrong: $err";
    });


    # apply the LoadDataInfile role to your own database_class
    use Mojo::mysql::Database::Role::LoadDataInfile database_class => 'MyApp::Database';

    $mysql->database_class('MyApp::Database');
    my $results = $mysql->db->load_data_infile(...);


    # don't auto apply the role to Mojo::mysql::Database and do it yourself
    $mysql->db->with_roles('+LoadDataInfile')->load_data_infile(...);

    # or

    Role::Tiny->apply_roles_to_package('Mojo::mysql::Database', 'Mojo::mysql::Database::Role::LoadDataInfile');

# DESCRIPTION

[Mojo::mysql::Database::Role::LoadDataInfile](https://metacpan.org/pod/Mojo::mysql::Database::Role::LoadDataInfile) is a role that makes synchronous and asynchronous `LOAD DATA INFILE` queries easy
with your ["database\_class" in Mojo::mysql](https://metacpan.org/pod/Mojo::mysql#database_class).

This module currently only supports `LOAD DATA LOCAL INFILE`, meaning the file used for `LOAD DATA INFILE` is on
the same computer where your code is running, not the database server. [Mojo::mysql::Database::Role::LoadDataInfile](https://metacpan.org/pod/Mojo::mysql::Database::Role::LoadDataInfile)
generates a temporary file for you locally on the computer your code is running on.

# IMPORT OPTIONS

## database\_class

    # apply the LoadDataInfile role to your own database_class
    use Mojo::mysql::Database::Role::LoadDataInfile database_class => 'MyApp::Database';

    $mysql->database_class('MyApp::Database');
    my $results = $mysql->db->load_data_infile(...);

["database\_class"](#database_class) allows you to apply [Mojo::mysql::Database::Role::LoadDataInfile](https://metacpan.org/pod/Mojo::mysql::Database::Role::LoadDataInfile) to your own database class
instead of the default [Mojo::mysql::Database](https://metacpan.org/pod/Mojo::mysql::Database).

# METHODS

## load\_data\_infile

    my $results = $db->load_data_infile(table => 'people', rows => $rows);
    print $results->affected_rows . " affected rows\n";

Execute a blocking `LOAD DATA INFILE` query and return a [Mojo::mysql::Results](https://metacpan.org/pod/Mojo::mysql::Results) instance.
A temporary file is used to store the data in `$rows` and then is sent to MySQL. The file is
deleted once the query is complete.
You can also append a callback to perform a non-blocking operation.

    my $results = $db->load_data_infile(table => 'people', rows => $rows, sub {
      my ($db, $err, $results) = @_;

      if ($err) {
          print "LOAD DATA INFILE failed: $err\n";
      } else {
        print $results->affected_rows . " affected rows\n";
      }
    });

## load\_data\_infile\_p

    my $promise = $db->load_data_infile_p(table => 'people', rows => $rows);

Same as ["load\_data\_infile"](#load_data_infile), but performs all operations non-blocking and returns a [Mojo::Promise](https://metacpan.org/pod/Mojo::Promise) object instead of accepting a callback.

    $db->load_data_infile_p(table => 'people', rows => $rows)->then(sub {
      my $results = shift;
      print $results->affected_rows . " affected rows\n";
      ...
    })->catch(sub {
      my $err = shift;
      ...
    })->wait;

## options

These are the options that can be passed to both ["load\_data\_infile"](#load_data_infile) and ["load\_data\_infile\_p"](#load_data_infile_p). Unless
stated otherwise, options may be combined.

See [LOAD DATA SYNTAX](https://dev.mysql.com/doc/refman/5.7/en/load-data.html) for more information
on the below options, and possibly more up-to-date information.

### low\_priority

    $db->load_data_infile(table => 'people', rows => $rows, low_priority => 1);

Adds the `LOW_PRIORITY` modifier to the query, which means that the execution of the `LOAD DATA` statement is delayed until
no other clients are reading from the table. This affects only storage engines that use only table-level locking (such as MyISAM, MEMORY, and MERGE).

This cannot be `true` when ["concurrent"](#concurrent) is `true`.

### concurrent

    $db->load_data_infile(table => 'people', rows => $rows, concurrent => 1);

Adds the `CONCURRENT` modifier to the query, which means that for MyISAM tables that satisfy the condition for concurrent
inserts (that is, it contains no free blocks in the middle), other threads can retrieve data from the table while `LOAD DATA` is executing.

This cannot be `true` when ["low\_priority"](#low_priority) is `true`.

### replace

    $db->load_data_infile(table => 'people', rows => $rows, replace => 1);

Adds the `REPLACE` modifier to the query, which means that rows that have the same value for a
primary key or unique index as an existing row will replace the existing row.

This cannot be `true` when ["ignore"](#ignore) is `true`.

If neither ["replace"](#replace) nor ["ignore"](#ignore) is specified, the default is ["ignore"](#ignore) since this module
uses the `LOCAL` modifier.

### ignore

    $db->load_data_infile(table => 'people', rows => $rows, ignore => 1);

Adds the `REPLACE` modifier to the query, which means that rows that duplicate an existing row on a unique key value
are discarded.

This cannot be `true` when ["replace"](#replace) is `true`.

If neither ["ignore"](#ignore) nor ["replace"](#replace) is specified, the default is ["ignore"](#ignore) since this module
uses the `LOCAL` modifier.

### partition

    $db->load_data_infile(table => 'people', rows => $rows, partition => ['p0', 'p1', 'p2']);

Adds the `PARITION` clause along with the provided partitions to insert into.

See [Partitioned Table Support](https://dev.mysql.com/doc/refman/5.7/en/load-data.html#load-data-partitioning-support) for more information.

### character\_set

    $db->load_data_infile(table => 'people', rows => $rows, character_set => 'utf8', tempfile_open_mode => '>:encoding(UTF-8)');

Adds the `CHARACTER SET` clause, which specifies the encoding that MySQL will use to interpret the data.

The default is `utf8`, which matches with the default of ["tempfile\_open\_mode"](#tempfile_open_mode). If you provide ["character\_set"](#character_set),
you must also provide ["tempfile\_open\_mode"](#tempfile_open_mode). The encodings should match between these two.

### tempfile\_open\_mode

    $db->load_data_infile(table => 'people', rows => $rows, character_set => 'utf8', tempfile_open_mode => '>:encoding(UTF-8)');

Sets the mode when opening the temporary file.

The default is ">:encoding(UTF-8)", which matches with the default of ["character\_set"](#character_set). If you provide ["tempfile\_open\_mode"](#tempfile_open_mode),
you must also provide ["character\_set"](#character_set). The encodings should match between these two.

### set

    $db->load_data_infile(table => 'people', rows => $rows, set => [
        {insert_time => 'NOW()'},
        {update_time => 'NOW()'},
    ]);

The `SET` clause can be used in several different ways, such as to supply values not derived from the input file. It accepts
an arrayref of hashes, where the key of each hash is the column to set and the value is the expression to set it to.

See [Input Preprocessing](https://dev.mysql.com/doc/refman/5.7/en/load-data.html#load-data-input-preprocessing) for more examples
of how ["set"](#set) can be used.

### rows

["rows"](#rows) correspond to the rows to be inserted. ["rows"](#rows) can be passed either an arrayref of ["hashrefs"](#hashrefs), or an arrayref of ["arrayrefs"](#arrayrefs).

#### hashrefs

    my $rows = [
      { name => 'Bob', age => 23 },
      { name => 'Alice', age => 27 },
    ];
    $db->load_data_infile(table => 'people', rows => $rows);

If the items are ["hashrefs"](#hashrefs) and ["columns"](#columns) is not provided, the keys from the first hashref will be used for ["columns"](#columns) and will
be used as both the MySQL column names, and the key names to get values from the hashrefs.

#### arrayrefs

    my $rows = [
      ['Bob', 23],
      ['Alice', 27],
    ];

    # columns required when using arrayrefs
    my $columns = ['name', 'age'];
    $db->load_data_infile(table => 'people', rows => $rows, columns => $columns);

If the items are ["arrayrefs"](#arrayrefs), ["columns"](#columns) must be provided, and the order of the column names in columns must match with the order of the values in
each arrayref in ["rows"](#rows).

See ["columns"](#columns) for more advance columns options.

### columns

["columns"](#columns) specifies the names of the columns to set in the table. Different values may be provided
depending on whether ["rows"](#rows) contains ["hashrefs"](#hashrefs) or ["arrayrefs"](#arrayrefs).

#### rows contains hashrefs

    # will use keys of first hashref in $rows for columns if columns is not provided
    $db->load_data_infile(table => 'people', rows => $rows);

    # strings in $columns will be used as keys to access values of the hashrefs
    # and also as the column names in MySQL
    my $columns = ['name', 'age'];
    $db->load_data_infile(table => 'people', rows => $rows, columns => $columns);

    # you can map hash keys to their correpsonding names in the table
    my $columns = [
      'name',
      { hash_age => 'column_age' },
    ];
    $db->load_data_infile(table => 'people', rows => $rows, columns => $columns);

If ["columns"](#columns) is not provided, ["rows"](#rows) must contain hashrefs,
and the keys of the first hashref will be used as the columns.

You may pass two types of values in ["columns"](#columns) when ["hashrefs"](#hashrefs) are used in ["rows"](#rows):

- You may pass strings, which will be used as the keys to access the values of the hashrefs and the column names.
- Or, you may also pass hashes with a single key value pair, where the key is the name of the key in the hash,
and the value is the name of the corresponding column in the table:

        { key_name => 'column_name' }

#### rows contains arrayrefs

    # columns must be in the same order as their corresponding values in $rows
    my $columns = ['name', 'age'];
    $db->load_data_infile(table => 'people', rows => $rows, columns => $columns);

If ["rows"](#rows) contains ["arrayrefs"](#arrayrefs), ["columns"](#columns) is required and its values should be in the same order as
the corresponding values in the arrayrefs pasesed to ["rows"](#rows).

# AUTHOR

Adam Hopkins <srchulo@cpan.org>

# COPYRIGHT

Copyright 2019- Adam Hopkins

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# SEE ALSO

- [Mojolicious](https://metacpan.org/pod/Mojolicious)
- [Mojo::mysql](https://metacpan.org/pod/Mojo::mysql)
- [Mojo::mysql::Database](https://metacpan.org/pod/Mojo::mysql::Database)
- [Text::CSV\_XS](https://metacpan.org/pod/Text::CSV_XS)
- [Text::CSV\_PP](https://metacpan.org/pod/Text::CSV_PP)

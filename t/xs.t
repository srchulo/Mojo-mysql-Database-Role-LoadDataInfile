use Mojo::Base -strict;
use Test::More;
use Mojo::mysql;

plan skip_all => q{TEST_ONLINE="mysql://root@/test;mysql_local_infile=1"} unless $ENV{TEST_ONLINE};

eval 'use Text::CSV_XS';
plan skip_all => 'Text::CSV_XS required to test XS' if $@;

require Mojo::mysql::Database::Role::LoadDataInfile;
Mojo::mysql::Database::Role::LoadDataInfile->import;

note 'Use Text::CSV_XS';
ok exists $INC{'Text/CSV_XS.pm'}, 'Text::CSV_XS loaded';
ok !exists $INC{'Text/CSV_PP.pm'}, 'Text::CSV_PP not loaded';

my $mysql = Mojo::mysql->new($ENV{TEST_ONLINE});
my $db = $mysql->db;
ok $db->ping, 'connected';

$db->query('DROP TABLE IF EXISTS people');
$db->query(q{
    CREATE TABLE `people` (
        `id` INT(11) NOT NULL AUTO_INCREMENT,
        `name` VARCHAR(255) NOT NULL,
        `age` INT(11) NOT NULL,
        `insert_time` DATETIME NULL DEFAULT NULL,
        PRIMARY KEY (`id`)
    )
    AUTO_INCREMENT=1
});

is $db->query('SELECT COUNT(id) FROM people')->array->[0], 0, 'people table is empty';

my $people = [
    {
        name => 'Bob',
        age => 23,
    },
    {
        name => 'Alice',
        age => 27,
    },
];

my $res = $db->load_data_infile(table => 'people', rows => $people);

is 2, $res->affected_rows, '2 affected rows';

# add values we expect to get back from DB but didn't use on insert
$people->[0]{id} = 1;
$people->[1]{id} = 2;
$_->{insert_time} = undef for @$people;

my $people_from_db = $db->query('SELECT * FROM people ORDER BY id ASC')->hashes;
is_deeply $people_from_db, $people, 'expected values in db';

done_testing;

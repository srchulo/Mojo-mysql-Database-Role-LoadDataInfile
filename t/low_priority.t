use Mojo::Base -strict;
use Test::More;
use Test::MockModule;
use Mojo::mysql;
use Mojo::mysql::Database::Role::LoadDataInfile;

plan skip_all => q{TEST_ONLINE="mysql://root@/test;mysql_local_infile=1"} unless $ENV{TEST_ONLINE};

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

note q{Hard to test LOW_PRIORITY. Just make sure it doesn't break anything and expected data is present};
my $res = $db->load_data_infile(table => 'people', rows => $people, low_priority => 1);

is 2, $res->affected_rows, '2 affected rows';

# add values we expect to get back from DB but didn't use on insert
$people->[0]{id} = 1;
$people->[1]{id} = 2;
$_->{insert_time} = undef for @$people;

my $people_from_db = $db->query('SELECT * FROM people ORDER BY id ASC')->hashes;
is_deeply $people_from_db, $people, 'expected values in db';

note 'Test LOW_PRIORITY is placed in query where expected';
my $module = Test::MockModule->new('Mojo::mysql::Database');

my $query;
$module->mock('query' => sub { $query = $_[1] });
$db->load_data_infile(table => 'people', rows => $people, low_priority => 1);

like $query, qr/\s*LOAD DATA\s+LOW_PRIORITY\s+LOCAL INFILE '(.*?)'/, 'query contains LOW_PRIORITY in the correct spot for load_data_infile';

undef $query;
is $query, undef, 'query is undef';

$db->load_data_infile_p(table => people => rows => $people, low_priority => 1);
like $query, qr/\s*LOAD DATA\s+LOW_PRIORITY\s+LOCAL INFILE '(.*?)'/, 'query contains LOW_PRIORITY in the correct spot for load_data_infile_p';

done_testing;

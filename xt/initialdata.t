use strict;
use warnings;

use RT::Extension::ConditionalCustomFields::Test tests => 10;

my $firstinitialdata = RT::Test::get_relocatable_file("firstcf" => "data");
my ($rv, $msg) = RT->DatabaseHandle->InsertData( $firstinitialdata, undef, disconnect_after => 0 );
ok($rv, "Inserted test data from $firstinitialdata: $msg");

my $initialdata = RT::Test::get_relocatable_file("initialdata" => "data");
($rv, $msg) = RT->DatabaseHandle->InsertData( $initialdata, undef, disconnect_after => 0 );
ok($rv, "Inserted test data from $initialdata: $msg");

my $attributes = RT::Attributes->new(RT->SystemUser);
$attributes->Limit(FIELD => 'Name', VALUE => 'ConditionedBy');
is($attributes->Count, 2, 'All attributes created');
while (my $attribute = $attributes->Next) {
    if ($attribute->id == 7) {
        is($attribute->Content->{CF}, 3, 'First ConditionedBy CF');
        is($attribute->Content->{val}, 'Passed', 'First ConditionedBy val');
    } elsif ($attribute->id == 8) {
        is($attribute->Content->{CF}, 3, 'Second ConditionedBy CF');
        is($attribute->Content->{val}, 'Passed', 'Second ConditionedBy val');
    } else {
        is($attribute->id, '7 or 8', 'Unexpected attribute id');
    }
}

use strict;
use warnings;

use RT::Extension::ConditionalCustomFields::Test tests => 9;

my $cf_condition = RT::CustomField->new(RT->SystemUser);
$cf_condition->Create(Name => 'Condition', Type => 'SelectSingle', Queue => 'General');
$cf_condition->AddValue(Name => 'Passed', SortOder => 0);
$cf_condition->AddValue(Name => 'Failed', SortOrder => 1);
my $cf_values = $cf_condition->Values->ItemsArrayRef;

my $cf_conditioned_by = RT::CustomField->new(RT->SystemUser);
$cf_conditioned_by->Create(Name => 'ConditionedBy', Type => 'FreeformSingle', Queue => 'General');

my $cf_conditioned_by_child = RT::CustomField->new(RT->SystemUser);
$cf_conditioned_by_child->Create(Name => 'Child', Type => 'FreeformSingle', Queue => 'General', BasedOn => $cf_conditioned_by->id);

my ($rv, $msg) = $cf_conditioned_by->SetConditionedBy($cf_condition->id, $cf_values->[0]->Name);
ok($rv, "SetConditionedBy: $msg");

my $cf_condition_conditioned_by = $cf_condition->ConditionedBy;
is($cf_condition_conditioned_by, undef, 'Not ConditionedBy returns undef');
my $cf_conditioned_by_conditioned_by = $cf_conditioned_by->ConditionedBy;
is($cf_conditioned_by_conditioned_by->{CF}, $cf_condition->id, 'ConditionedBy returns CF id');
is($cf_conditioned_by_conditioned_by->{val}, 'Passed', 'ConditionedBy returns val');
my $cf_conditioned_by_child_conditioned_by = $cf_conditioned_by_child->ConditionedBy;
is($cf_conditioned_by_child_conditioned_by->{CF}, $cf_condition->id, 'Recursive ConditionedBy returns CF id');
is($cf_conditioned_by_child_conditioned_by->{val}, 'Passed', 'Recursive ConditionedBy returns val');

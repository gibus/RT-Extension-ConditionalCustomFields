use strict;
use warnings;

use RT::Extension::ConditionalCustomFields::Test tests => 18;

use WWW::Mechanize::PhantomJS;

my $cf_condition = RT::CustomField->new(RT->SystemUser);
$cf_condition->Create(Name => 'Condition', Type => 'SelectSingle', Queue => 'General');
$cf_condition->AddValue(Name => 'Passed', SortOder => 0);
$cf_condition->AddValue(Name => 'Failed', SortOrder => 1);
my $cf_values = $cf_condition->Values->ItemsArrayRef;

my $cf_conditioned_by = RT::CustomField->new(RT->SystemUser);
$cf_conditioned_by->Create(Name => 'ConditionedBy', Type => 'FreeformSingle', Queue => 'General');

my $cf_conditioned_by_child = RT::CustomField->new(RT->SystemUser);
$cf_conditioned_by_child->Create(Name => 'Child', Type => 'FreeformSingle', Queue => 'General', BasedOn => $cf_conditioned_by->id);

my ($base, $m) = RT::Extension::ConditionalCustomFields::Test->started_ok;
ok($m->login, 'Logged in agent');

$m->follow_link_ok({ id => 'admin-custom-fields-create' }, 'CustomField create link');
$m->content_lacks('Customfield is conditioned by', 'No ConditionedBy on CF creation');

$m->get_ok($m->rt_base_url . 'Admin/CustomFields/Modify.html?id=' . $cf_condition->id, 'Condition CF modify form');
my $cf_condition_form = $m->form_name('ModifyCustomField');
my $cf_condition_CF_select = $cf_condition_form->find_input('ConditionalCF');
my @cf_condition_CF_values = $cf_condition_CF_select->possible_values;
is($cf_condition_CF_values[0], '', 'No other select CF');

$m->get_ok($m->rt_base_url . 'Admin/CustomFields/Modify.html?id=' . $cf_conditioned_by->id, 'ConditionBy CF modify form');
my $cf_conditioned_by_form = $m->form_name('ModifyCustomField');
my $cf_conditioned_by_CF_select = $cf_conditioned_by_form->find_input('ConditionalCF');
my @cf_conditioned_by_CF_values = $cf_conditioned_by_CF_select->possible_values;
is(scalar(@cf_conditioned_by_CF_values), 2, 'Can be conditioned by select cf');
is($cf_conditioned_by_CF_values[0], '', 'Can be conditioned by nothing');
is($cf_conditioned_by_CF_values[1], $cf_condition->id, 'Can be conditioned by Condition CF');

$cf_conditioned_by->SetConditionedBy($cf_values->[0]->id);;
is($cf_conditioned_by->ConditionedByObj->Name, 'Passed', 'ConditionedByObj');
$m->reload;

$cf_conditioned_by_form = $m->form_name('ModifyCustomField');
$cf_conditioned_by_CF_select = $cf_conditioned_by_form->find_input('ConditionalCF');
is($cf_conditioned_by_CF_select->value, $cf_condition->id, 'ConditionalCF set');
my $cf_conditioned_by_CFV_select = $cf_conditioned_by_form->find_input('ConditionedBy');
is($cf_conditioned_by_CFV_select->value, $cf_values->[0]->id, 'ConditionedBy set');

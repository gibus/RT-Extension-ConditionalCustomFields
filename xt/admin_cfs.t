use strict;
use warnings;

use RT::Extension::ConditionalCustomFields::Test tests => 72;

use WWW::Mechanize::PhantomJS;

my $cf_condition_select_single = RT::CustomField->new(RT->SystemUser);
$cf_condition_select_single->Create(Name => 'ConditionSelectSingle', Type => 'Select', MaxValues => 1, RenderType => 'Dropdown', Queue => 'General');
$cf_condition_select_single->AddValue(Name => 'Single Passed', SortOder => 0);
$cf_condition_select_single->AddValue(Name => 'Single Failed', SortOrder => 1);
$cf_condition_select_single->AddValue(Name => 'Single Schrödingerized', SortOrder => 2);
my $cf_values_select_single = $cf_condition_select_single->Values->ItemsArrayRef;

my $cf_condition_select_multiple = RT::CustomField->new(RT->SystemUser);
$cf_condition_select_multiple->Create(Name => 'ConditionSelectMultiple', Type => 'Select', MaxValues => 0, RenderType => 'List', Queue => 'General');
$cf_condition_select_multiple->AddValue(Name => 'Multiple Passed', SortOder => 0);
$cf_condition_select_multiple->AddValue(Name => 'Multiple Failed', SortOrder => 1);
$cf_condition_select_multiple->AddValue(Name => 'Multiple Schrödingerized', SortOrder => 2);
my $cf_values_select_multiple = $cf_condition_select_multiple->Values->ItemsArrayRef;

my $cf_condition_freeform_single = RT::CustomField->new(RT->SystemUser);
$cf_condition_freeform_single->Create(Name => 'ConditionFreeformSingle', Type => 'Freeform', MaxValues => 1, Queue => 'General');

my $cf_conditioned_by = RT::CustomField->new(RT->SystemUser);
$cf_conditioned_by->Create(Name => 'ConditionedBy', Type => 'Freeform', MaxValues => 1, Queue => 'General');

my ($base, $m) = RT::Extension::ConditionalCustomFields::Test->started_ok;
ok($m->login, 'Logged in agent');

$m->follow_link_ok({ id => 'admin-custom-fields-create' }, 'CustomField create link');
$m->content_lacks('Customfield is conditioned by', 'No ConditionedBy on CF creation');

$m->get_ok($m->rt_base_url . 'Admin/CustomFields/Modify.html?id=' . $cf_conditioned_by->id, 'ConditionedBy CF modify form');
my $cf_conditioned_by_form = $m->form_name('ModifyCustomField');
my $cf_conditioned_by_CF = $cf_conditioned_by_form->find_input('ConditionalCF');
my @cf_conditioned_by_CF_options = $cf_conditioned_by_CF->possible_values;
is(scalar(@cf_conditioned_by_CF_options), 4, 'Can be conditioned by 4 CFs');
is($cf_conditioned_by_CF_options[0], '', 'Can be conditioned by nothing');
is($cf_conditioned_by_CF_options[1], $cf_condition_freeform_single->id, 'Can be conditioned by ConditionFreeformSingle CF');
is($cf_conditioned_by_CF_options[2], $cf_condition_select_multiple->id, 'Can be conditioned by ConditionSelectMultiple CF');
is($cf_conditioned_by_CF_options[3], $cf_condition_select_single->id, 'Can be conditioned by ConditionSelectSingle CF');

my $mjs = WWW::Mechanize::PhantomJS->new();
$mjs->get($m->rt_base_url . '?user=root;pass=password');
$mjs->get($m->rt_base_url . 'Admin/CustomFields/Modify.html?id=' . $cf_conditioned_by->id);
ok($mjs->content =~ /Customfield is conditioned by/, 'Can be conditioned by (with js)');

@cf_conditioned_by_CF_options = $mjs->xpath('//select[@name="ConditionalCF"]/option');
is(scalar(@cf_conditioned_by_CF_options), 4, 'Can be conditioned by 4 CFs (with js)');
is($cf_conditioned_by_CF_options[0]->get_value, '', 'Can be conditioned by nothing (with js)');
is($cf_conditioned_by_CF_options[1]->get_value, $cf_condition_freeform_single->id, 'Can be conditioned by ConditionFreeformSingle CF (with js)');
is($cf_conditioned_by_CF_options[2]->get_value, $cf_condition_select_multiple->id, 'Can be conditioned by ConditionSelectMultiple CF (with js)');
is($cf_conditioned_by_CF_options[3]->get_value, $cf_condition_select_single->id, 'Can be conditioned by ConditionSelectSingle CF (with js)');

# Conditioned by Select Single CF
$cf_conditioned_by_CF = $mjs->xpath('//select[@name="ConditionalCF"]', single => 1);
$mjs->field($cf_conditioned_by_CF, $cf_condition_select_single->id);
$mjs->eval_in_page("jQuery('select[name=ConditionalCF]').trigger('change');");

my @cf_conditioned_by_op_options_select_single = $mjs->xpath('//select[@name="ConditionalOp"]/option');
is(scalar(@cf_conditioned_by_op_options_select_single), 2, 'Can be conditioned with 2 operations by ConditionSelectSingle');
is($cf_conditioned_by_op_options_select_single[0]->get_value, "is", "Is operation for conditioned by ConditionSelectSingle");
is($cf_conditioned_by_op_options_select_single[1]->get_value, "isn't", "Isn't operation for conditioned by ConditionSelectSingle");

my @cf_conditioned_by_CFV_options_select_single = $mjs->xpath('//input[@name="ConditionedBy"]');
is(scalar(@cf_conditioned_by_CFV_options_select_single), 3, 'Three values available for conditioned by ConditionSelectSingle');
is($cf_conditioned_by_CFV_options_select_single[0]->get_value, $cf_values_select_single->[0]->Name, 'First value for conditioned by ConditionSelectSingle');
is($cf_conditioned_by_CFV_options_select_single[1]->get_value, $cf_values_select_single->[1]->Name, 'Second value for conditioned by ConditionSelectSingle');
is($cf_conditioned_by_CFV_options_select_single[2]->get_value, $cf_values_select_single->[2]->Name, 'Third value for conditioned by ConditionSelectSingle');

my $cf_conditioned_by_CFV_1 = $mjs->xpath('//input[@value="' . $cf_values_select_single->[0]->Name . '"]', single => 1);
$cf_conditioned_by_CFV_1->click;
my $cf_conditioned_by_CFV_2 = $mjs->xpath('//input[@value="' . $cf_values_select_single->[2]->Name . '"]', single => 1);
$cf_conditioned_by_CFV_2->click;
$mjs->click('Update');

my $conditioned_by = $cf_conditioned_by->ConditionedBy;
is($conditioned_by->{CF}, $cf_condition_select_single->id, 'ConditionedBy ConditionSelectSingle CF');
is(scalar(@{$conditioned_by->{vals}}), 2, 'ConditionedBy ConditionSelectSingle two vals');
is($conditioned_by->{vals}->[0], $cf_values_select_single->[0]->Name, 'ConditionedBy ConditionSelectSingle first val');
is($conditioned_by->{vals}->[1], $cf_values_select_single->[2]->Name, 'ConditionedBy ConditionSelectSingle second val');

# Conditioned by Select Multiple CF
$cf_conditioned_by_CF = $mjs->xpath('//select[@name="ConditionalCF"]', single => 1);
$mjs->field($cf_conditioned_by_CF, $cf_condition_select_multiple->id);
$mjs->eval_in_page("jQuery('select[name=ConditionalCF]').trigger('change');");

my @cf_conditioned_by_op_options_select_multiple = $mjs->xpath('//select[@name="ConditionalOp"]/option');
is(scalar(@cf_conditioned_by_op_options_select_multiple), 2, 'Can be conditioned with 2 operations by ConditionSelectMultiple');
is($cf_conditioned_by_op_options_select_multiple[0]->get_value, "is", "Is operation for conditioned by ConditionSelectMultiple");
is($cf_conditioned_by_op_options_select_multiple[1]->get_value, "isn't", "Isn't operation for conditioned by ConditionSelectMultiple");

my @cf_conditioned_by_CFV_options_select_multiple = $mjs->xpath('//input[@name="ConditionedBy"]');
is(scalar(@cf_conditioned_by_CFV_options_select_multiple), 3, 'Three values available for conditioned by ConditionSelectMultiple');
is($cf_conditioned_by_CFV_options_select_multiple[0]->get_value, $cf_values_select_multiple->[0]->Name, 'First value for conditioned by ConditionSelectMultiple');
is($cf_conditioned_by_CFV_options_select_multiple[1]->get_value, $cf_values_select_multiple->[1]->Name, 'Second value for conditioned by ConditionSelectMultiple');
is($cf_conditioned_by_CFV_options_select_multiple[2]->get_value, $cf_values_select_multiple->[2]->Name, 'Third value for conditioned by ConditionSelectMultiple');

$cf_conditioned_by_CFV_1 = $mjs->xpath('//input[@value="' . $cf_values_select_multiple->[0]->Name . '"]', single => 1);
$cf_conditioned_by_CFV_1->click;
$cf_conditioned_by_CFV_2 = $mjs->xpath('//input[@value="' . $cf_values_select_multiple->[2]->Name . '"]', single => 1);
$cf_conditioned_by_CFV_2->click;
$mjs->click('Update');

$conditioned_by = $cf_conditioned_by->ConditionedBy;
is($conditioned_by->{CF}, $cf_condition_select_multiple->id, 'ConditionedBy ConditionSelectMultiple CF');
is(scalar(@{$conditioned_by->{vals}}), 2, 'ConditionedBy ConditionSelectMultiple two vals');
is($conditioned_by->{vals}->[0], $cf_values_select_multiple->[0]->Name, 'ConditionedBy ConditionSelectMultiple first val');
is($conditioned_by->{vals}->[1], $cf_values_select_multiple->[2]->Name, 'ConditionedBy ConditionSelectMultiple second val');

# Conditioned by Freeform Single
$cf_conditioned_by_CF = $mjs->xpath('//select[@name="ConditionalCF"]', single => 1);
$mjs->field($cf_conditioned_by_CF, $cf_condition_freeform_single->id);
$mjs->eval_in_page("jQuery('select[name=ConditionalCF]').trigger('change');");

my @cf_conditioned_by_op_options_freeform_single = $mjs->xpath('//select[@name="ConditionalOp"]/option');
is(scalar(@cf_conditioned_by_op_options_freeform_single), 7, 'Can be conditioned with 7 operations by ConditionFreeformSingle');
is($cf_conditioned_by_op_options_freeform_single[0]->get_value, "matches", "Matches operation for conditioned by ConditionFreeformSingle");
is($cf_conditioned_by_op_options_freeform_single[1]->get_value, "doesn't match", "Doesn't match operation for conditioned by ConditionFreeformSingle");
is($cf_conditioned_by_op_options_freeform_single[2]->get_value, "is", "Is operation for conditioned by ConditionFreeformSingle");
is($cf_conditioned_by_op_options_freeform_single[3]->get_value, "isn't", "Isn't operation for conditioned by ConditionFreeformSingle");
is($cf_conditioned_by_op_options_freeform_single[4]->get_value, "less than", "Less than operation for conditioned by ConditionFreeformSingle");
is($cf_conditioned_by_op_options_freeform_single[5]->get_value, "greater than", "Greater than operation for conditioned by ConditionFreeformSingle");
is($cf_conditioned_by_op_options_freeform_single[6]->get_value, "between", "Between operation for conditioned by ConditionFreeformSingle");

my $cf_conditioned_by_op_freeform_single = $mjs->xpath('//select[@name="ConditionalOp"]', single => 1);
is($cf_conditioned_by_op_freeform_single->get_value, "matches", "Matches operation selected for conditioned by ConditionFreeformSingle");
my @cf_conditioned_by_value_freeform_single = $mjs->xpath('//input[@name="ConditionedBy"]');
is(scalar(@cf_conditioned_by_value_freeform_single), 1, "One possible value for conditioned by matches ConditionFreeformSingle");

$mjs->field($cf_conditioned_by_op_freeform_single, "doesn't match");
$mjs->eval_in_page("jQuery('select[name=ConditionalOp]').trigger('change');");
is($cf_conditioned_by_op_freeform_single->get_value, "doesn't match", "Doesn't match operation selected for conditioned by ConditionFreeformSingle");
@cf_conditioned_by_value_freeform_single = $mjs->xpath('//input[@name="ConditionedBy"]');
is(scalar(@cf_conditioned_by_value_freeform_single), 1, "One possible value for conditioned by doesn't match ConditionFreeformSingle");

$mjs->field($cf_conditioned_by_op_freeform_single, "is");
$mjs->eval_in_page("jQuery('select[name=ConditionalOp]').trigger('change');");
is($cf_conditioned_by_op_freeform_single->get_value, "is", "Is operation selected for conditioned by ConditionFreeformSingle");
@cf_conditioned_by_value_freeform_single = $mjs->xpath('//input[@name="ConditionedBy"]');
is(scalar(@cf_conditioned_by_value_freeform_single), 1, "One possible value for conditioned by is ConditionFreeformSingle");

$mjs->field($cf_conditioned_by_op_freeform_single, "isn't");
$mjs->eval_in_page("jQuery('select[name=ConditionalOp]').trigger('change');");
is($cf_conditioned_by_op_freeform_single->get_value, "isn't", "Isn't operation selected for conditioned by ConditionFreeformSingle");
@cf_conditioned_by_value_freeform_single = $mjs->xpath('//input[@name="ConditionedBy"]');
is(scalar(@cf_conditioned_by_value_freeform_single), 1, "One possible value for conditioned by isn't ConditionFreeformSingle");

$mjs->field($cf_conditioned_by_op_freeform_single, "less than");
$mjs->eval_in_page("jQuery('select[name=ConditionalOp]').trigger('change');");
is($cf_conditioned_by_op_freeform_single->get_value, "less than", "Less than operation selected for conditioned by ConditionFreeformSingle");
@cf_conditioned_by_value_freeform_single = $mjs->xpath('//input[@name="ConditionedBy"]');
is(scalar(@cf_conditioned_by_value_freeform_single), 1, "One possible value for conditioned by less than ConditionFreeformSingle");

$mjs->field($cf_conditioned_by_op_freeform_single, "greater than");
$mjs->eval_in_page("jQuery('select[name=ConditionalOp]').trigger('change');");
is($cf_conditioned_by_op_freeform_single->get_value, "greater than", "Greater than operation selected for conditioned by ConditionFreeformSingle");
@cf_conditioned_by_value_freeform_single = $mjs->xpath('//input[@name="ConditionedBy"]');
is(scalar(@cf_conditioned_by_value_freeform_single), 1, "One possible value for conditioned by greater than ConditionFreeformSingle");

$mjs->field($cf_conditioned_by_op_freeform_single, "between");
$mjs->eval_in_page("jQuery('select[name=ConditionalOp]').trigger('change');");
is($cf_conditioned_by_op_freeform_single->get_value, "between", "Between operation selected for conditioned by ConditionFreeformSingle");
@cf_conditioned_by_value_freeform_single = $mjs->xpath('//input[@name="ConditionedBy"]');
is(scalar(@cf_conditioned_by_value_freeform_single), 2, "Two possible values for conditioned by between ConditionFreeformSingle");

$mjs->field($cf_conditioned_by_value_freeform_single[0], "you");
$mjs->field($cf_conditioned_by_value_freeform_single[1], "me");
$mjs->click('Update');

$conditioned_by = $cf_conditioned_by->ConditionedBy;
is($conditioned_by->{CF}, $cf_condition_freeform_single->id, 'ConditionedBy ConditionFreeformSingle CF');
is($conditioned_by->{op}, 'between', 'ConditionedBy ConditionFreeformSingle CF and between operation');
is(scalar(@{$conditioned_by->{vals}}), 2, 'ConditionedBy ConditionFreeformSingle two vals');
is($conditioned_by->{vals}->[0], 'me', 'ConditionedBy ConditionFreeformSingle first val');
is($conditioned_by->{vals}->[1], 'you', 'ConditionedBy ConditionFreeformSingle second val');

# Delete conditioned by
$cf_conditioned_by_CF = $mjs->xpath('//select[@name="ConditionalCF"]', single => 1);
$mjs->field($cf_conditioned_by_CF, 0);
$mjs->eval_in_page("jQuery('.conditionedby select').trigger('change');");
$mjs->click('Update');
ok($mjs->content =~ /ConditionedBy deleted/, 'ConditionedBy deleted');
is($cf_conditioned_by->ConditionedBy, undef, 'Attribute deleted');


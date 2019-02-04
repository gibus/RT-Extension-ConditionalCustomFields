use strict;
use warnings;

use RT::Extension::ConditionalCustomFields::Test tests => 14;

use WWW::Mechanize::PhantomJS;

my $cf_condition = RT::CustomField->new(RT->SystemUser);
$cf_condition->Create(Name => 'Condition', Type => 'DateTime', MaxValues => 1, Queue => 'General');

my $cf_conditioned_by = RT::CustomField->new(RT->SystemUser);
$cf_conditioned_by->Create(Name => 'ConditionedBy', Type => 'Freeform', MaxValues => 1, Queue => 'General');

RT->Config->Set('CustomFieldGroupings',
    'RT::Ticket' => [
        'Group one' => ['Condition'],
        'Group two' => ['ConditionedBy'],
    ],
);

my $ticket = RT::Ticket->new(RT->SystemUser);
$ticket->Create(Queue => 'General', Subject => 'Test Ticket ConditionalCF');
$ticket->AddCustomFieldValue(Field => $cf_conditioned_by->id , Value => 'See me?');

my ($base, $m) = RT::Extension::ConditionalCustomFields::Test->started_ok;
my $mjs = WWW::Mechanize::PhantomJS->new();
$mjs->driver->ua->timeout(540);
$mjs->get($m->rt_base_url . '?user=root;pass=password');

# Set user TZ to play with datetime
my $user = RT::Test->load_or_create_user(Name => 'root', Password => 'password');
$user->SetTimezone('Europe/Paris');
my $DateObj = RT::Date->new($user);

# Operator: is, condition met
$cf_conditioned_by->SetConditionedBy($cf_condition->id, 'is', '2021-06-21 00:42:00');
$DateObj->Set(Format => 'unknown', Value => '2021-06-21 00:42:00', Timezone => 'user');
$ticket->AddCustomFieldValue(Field => $cf_condition->id , Value => $DateObj->ISO);
$mjs->get($m->rt_base_url . 'Ticket/Display.html?id=' . $ticket->id);
my $ticket_cf_conditioned_by = $mjs->selector('#CF-'. $cf_conditioned_by->id . '-ShowRow', single => 1);
ok($ticket_cf_conditioned_by->is_displayed, 'Show ConditionalCF when DateTime condition val with is operator is met');

# Operator: is, condition not met
$DateObj->Set(Format => 'unknown', Value => '2019-06-21 06:06:06', Timezone => 'user');
$ticket->AddCustomFieldValue(Field => $cf_condition->id , Value => $DateObj->ISO);
$mjs->get($m->rt_base_url . 'Ticket/Display.html?id=' . $ticket->id);
$ticket_cf_conditioned_by = $mjs->selector('#CF-'. $cf_conditioned_by->id . '-ShowRow', single => 1);
ok($ticket_cf_conditioned_by->is_hidden, 'Hide ConditionalCF when DateTime condition val with is operator is not met');

# Operator: less than, condition met
$cf_conditioned_by->SetConditionedBy($cf_condition->id, 'less than', '2019-06-21 00:42:00');
$DateObj->Set(Format => 'unknown', Value => '2019-06-21 00:00:00', Timezone => 'user');
$ticket->AddCustomFieldValue(Field => $cf_condition->id , Value => $DateObj->ISO);
$mjs->get($m->rt_base_url . 'Ticket/Display.html?id=' . $ticket->id);
$ticket_cf_conditioned_by = $mjs->selector('#CF-'. $cf_conditioned_by->id . '-ShowRow', single => 1);
ok($ticket_cf_conditioned_by->is_displayed, 'Show ConditionalCF when DateTime condition val with less than operator is met');

# Operator: less than, condition not met
$DateObj->Set(Format => 'unknown', Value => '2019-06-21 00:42:01', Timezone => 'user');
$ticket->AddCustomFieldValue(Field => $cf_condition->id , Value => $DateObj->ISO);
$mjs->get($m->rt_base_url . 'Ticket/Display.html?id=' . $ticket->id);
$ticket_cf_conditioned_by = $mjs->selector('#CF-'. $cf_conditioned_by->id . '-ShowRow', single => 1);
ok($ticket_cf_conditioned_by->is_hidden, 'Hide ConditionalCF when DateTime condition val with less than operator is not met');

# Operator: greater than, condition met
$cf_conditioned_by->SetConditionedBy($cf_condition->id, 'greater than', '2019-06-21 00:42:00');
$DateObj->Set(Format => 'unknown', Value => '2019-06-21 00:42:01', Timezone => 'user');
$ticket->AddCustomFieldValue(Field => $cf_condition->id , Value => $DateObj->ISO);
$mjs->get($m->rt_base_url . 'Ticket/Display.html?id=' . $ticket->id);
$ticket_cf_conditioned_by = $mjs->selector('#CF-'. $cf_conditioned_by->id . '-ShowRow', single => 1);
ok($ticket_cf_conditioned_by->is_displayed, 'Show ConditionalCF when DateTime condition val with greater than operator is met');

# Operator: greater than, condition not met
$DateObj->Set(Format => 'unknown', Value => '2019-06-21 00:41:59', Timezone => 'user');
$ticket->AddCustomFieldValue(Field => $cf_condition->id , Value => $DateObj->ISO);
$mjs->get($m->rt_base_url . 'Ticket/Display.html?id=' . $ticket->id);
$ticket_cf_conditioned_by = $mjs->selector('#CF-'. $cf_conditioned_by->id . '-ShowRow', single => 1);
ok($ticket_cf_conditioned_by->is_hidden, 'Hide ConditionalCF when DateTime condition val with greater than operator is not met');

# Operator: between, condition met
$cf_conditioned_by->SetConditionedBy($cf_condition->id, 'between', ['2019-06-21 00:42:00', '2019-07-14 00:42:00']);
$DateObj->Set(Format => 'unknown', Value => '2019-06-21 21:42:00', Timezone => 'user');
$ticket->AddCustomFieldValue(Field => $cf_condition->id , Value => $DateObj->ISO);
$mjs->get($m->rt_base_url . 'Ticket/Display.html?id=' . $ticket->id);
$ticket_cf_conditioned_by = $mjs->selector('#CF-'. $cf_conditioned_by->id . '-ShowRow', single => 1);
ok($ticket_cf_conditioned_by->is_displayed, 'Show ConditionalCF when DateTime condition val with between operator is met');

# Operator: between, condition not met
$DateObj->Set(Format => 'unknown', Value => '2020-06-21 00:00:00', Timezone => 'user');
$ticket->AddCustomFieldValue(Field => $cf_condition->id , Value => $DateObj->ISO);
$mjs->get($m->rt_base_url . 'Ticket/Display.html?id=' . $ticket->id);
$ticket_cf_conditioned_by = $mjs->selector('#CF-'. $cf_conditioned_by->id . '-ShowRow', single => 1);
ok($ticket_cf_conditioned_by->is_hidden, 'Hide ConditionalCF when DateTime condition val with between operator is not met');

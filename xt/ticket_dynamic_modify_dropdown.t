use strict;
use warnings;

use RT::Extension::ConditionalCustomFields::Test tests => 22;

use WWW::Mechanize::PhantomJS;

my $cf_condition = RT::CustomField->new(RT->SystemUser);
$cf_condition->Create(Name => 'Condition', Type => 'Select', MaxValues => 1, Queue => 'General', RenderType => 'Dropdown');
$cf_condition->AddValue(Name => 'Passed', SortOder => 0);
$cf_condition->AddValue(Name => 'Failed', SortOrder => 1);
$cf_condition->AddValue(Name => 'Schrödingerized', SortOrder => 2);
my $cf_values = $cf_condition->Values->ItemsArrayRef;

my $cf_conditioned_by = RT::CustomField->new(RT->SystemUser);
$cf_conditioned_by->Create(Name => 'ConditionedBy', Type => 'Freeform', MaxValues => 1, Queue => 'General');

my $cf_conditioned_by_child = RT::CustomField->new(RT->SystemUser);
$cf_conditioned_by_child->Create(Name => 'Child', Type => 'Freeform', MaxValues => 1, Queue => 'General', BasedOn => $cf_conditioned_by->id);

RT->Config->Set('CustomFieldGroupings',
    'RT::Ticket' => [
        'Group one' => ['Condition'],
        'Group two' => ['ConditionedBy'],
    ],
);
RT->Config->PostLoadCheck;

my ($base, $m) = RT::Extension::ConditionalCustomFields::Test->started_ok;
my $mjs = WWW::Mechanize::PhantomJS->new();
$mjs->driver->ua->timeout(600);
$mjs->get($m->rt_base_url . '?user=root;pass=password');

my $ticket = RT::Ticket->new(RT->SystemUser);
$ticket->Create(Queue => 'General', Subject => 'Test Ticket ConditionalCF');
$ticket->AddCustomFieldValue(Field => $cf_condition->id , Value => 'Passed');
$ticket->AddCustomFieldValue(Field => $cf_conditioned_by->id , Value => 'See me?');
$ticket->AddCustomFieldValue(Field => $cf_conditioned_by_child->id , Value => 'See me too?');

$mjs->get($m->rt_base_url . 'Ticket/Modify.html?id=' . $ticket->id);
my $ticket_cf_conditioned_by = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Grouptwo-' . $cf_conditioned_by->id . '-Value', single => 1);
ok($ticket_cf_conditioned_by->is_displayed, "Show ConditionalCF when no condition is set");
my $ticket_cf_conditioned_by_child = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField-' . $cf_conditioned_by_child->id . '-Value', single => 1);
ok($ticket_cf_conditioned_by_child->is_displayed, "Show Child when no condition is set");

my $ticket_cf_condition = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Groupone-' . $cf_condition->id . '-Values', single => 1);
$mjs->field($ticket_cf_condition, $cf_values->[0]->Name);
$mjs->eval_in_page("jQuery('#Object-RT\\\\:\\\\:Ticket-" . $ticket->id . "-CustomField\\\\:Groupone-" . $cf_condition->id . "-Values').trigger('change');");
ok($ticket_cf_conditioned_by->is_displayed, "Show ConditionalCF when Condition is changed to be met but no condition is set");
ok($ticket_cf_conditioned_by_child->is_displayed, "Show Child when Condition is changed to be met but no condition is set");

$mjs->field($ticket_cf_condition, $cf_values->[1]->Name);
$mjs->eval_in_page("jQuery('#Object-RT\\\\:\\\\:Ticket-" . $ticket->id . "-CustomField\\\\:Groupone-" . $cf_condition->id . "-Values').trigger('change');");
ok($ticket_cf_conditioned_by->is_displayed, "Show ConditionalCF when Condition is changed to be not met but no condition is set");
ok($ticket_cf_conditioned_by_child->is_displayed, "Show Child when Condition is changed to be not met but no condition is set");

$cf_conditioned_by->SetConditionedBy($cf_condition->id, 'is', [$cf_values->[0]->Name, $cf_values->[2]->Name]);

$mjs->get($m->rt_base_url . 'Ticket/Modify.html?id=' . $ticket->id);
$ticket_cf_conditioned_by = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Grouptwo-' . $cf_conditioned_by->id . '-Value', single => 1);
ok($ticket_cf_conditioned_by->is_displayed, "Show ConditionalCF when condition is met by first val");
$ticket_cf_conditioned_by_child = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField-' . $cf_conditioned_by_child->id . '-Value', single => 1);
ok($ticket_cf_conditioned_by_child->is_displayed, "Show Child when condition is met by first val");

$ticket_cf_condition = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Groupone-' . $cf_condition->id . '-Values', single => 1);
$mjs->field($ticket_cf_condition, $cf_values->[1]->Name);
$mjs->eval_in_page("jQuery('#Object-RT\\\\:\\\\:Ticket-" . $ticket->id . "-CustomField\\\\:Groupone-" . $cf_condition->id . "-Values').trigger('change');");
ok($ticket_cf_conditioned_by->is_hidden, "Hide ConditionalCF when Condition is changed to be not met");
ok($ticket_cf_conditioned_by_child->is_hidden, "Hide Child when Condition is changed to be not met");

$ticket->AddCustomFieldValue(Field => $cf_condition->id , Value => $cf_values->[1]->Name);

$mjs->get($m->rt_base_url . 'Ticket/Modify.html?id=' . $ticket->id);
$ticket_cf_conditioned_by = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Grouptwo-' . $cf_conditioned_by->id . '-Value', single => 1);
ok($ticket_cf_conditioned_by->is_hidden, "Hide ConditionalCF when condition is not met");
$ticket_cf_conditioned_by_child = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField-' . $cf_conditioned_by_child->id . '-Value', single => 1);
ok($ticket_cf_conditioned_by_child->is_hidden, "Hide Child when condition is not met");

$ticket_cf_condition = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Groupone-' . $cf_condition->id . '-Values', single => 1);
$mjs->field($ticket_cf_condition, $cf_values->[2]->Name);
sleep 1;
$mjs->eval_in_page("jQuery('#Object-RT\\\\:\\\\:Ticket-" . $ticket->id . "-CustomField\\\\:Groupone-" . $cf_condition->id . "-Values').trigger('change');");
sleep 1;
ok($ticket_cf_conditioned_by->is_displayed, "Show ConditionalCF when Condition is changed to be met by second val");
ok($ticket_cf_conditioned_by_child->is_displayed, "Show Child when Condition is changed to be met by second val");

my $cf_conditioned_by_img = RT::CustomField->new(RT->SystemUser);
$cf_conditioned_by_img->Create(Name => 'ConditionedByImg', Type => 'Image', MaxValues => 1, Queue => 'General');
$cf_conditioned_by_img->SetConditionedBy($cf_condition->id, 'is', [$cf_values->[0]->Name, $cf_values->[2]->Name]);
$ticket->AddCustomFieldValue(Field => $cf_condition->id , Value => $cf_values->[1]->Name);

$mjs->get($m->rt_base_url . 'Ticket/Modify.html?id=' . $ticket->id);
my $ticket_cf_conditioned_by_img = $mjs->xpath('//input[@name="Object-RT::Ticket-' . $ticket->id . '-CustomField-' . $cf_conditioned_by_img->id . '-Upload"]', single => 1);
ok($ticket_cf_conditioned_by_img->is_hidden, "Hide ConditionedByImg when Condition is not met");

my $cf_conditioned_by_wiki = RT::CustomField->new(RT->SystemUser);
$cf_conditioned_by_wiki->Create(Name => 'ConditionedByImg', Type => 'Wikitext', MaxValues => 1, Queue => 'General');
$cf_conditioned_by_wiki->SetConditionedBy($cf_condition->id, 'is', [$cf_values->[0]->Name, $cf_values->[2]->Name]);
$ticket->AddCustomFieldValue(Field => $cf_condition->id , Value => $cf_values->[1]->Name);

$mjs->get($m->rt_base_url . 'Ticket/Modify.html?id=' . $ticket->id);
my $ticket_cf_conditioned_by_wiki = $mjs->xpath('//textarea[@name="Object-RT::Ticket-' . $ticket->id . '-CustomField-' . $cf_conditioned_by_wiki->id . '-Values"]', single => 1);
ok($ticket_cf_conditioned_by_wiki->is_hidden, "Hide ConditionedByWiki when Condition is not met");

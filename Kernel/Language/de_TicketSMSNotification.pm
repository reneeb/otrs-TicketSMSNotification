# --
# Kernel/Language/de_TicketSMSNotification.pm - German translations for TicketSMSNotification
# Copyright (C) 2014 Perl-Services.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Language::de_TicketSMSNotification;

use strict;
use warnings;

use utf8;

sub Data {
    my $Self = shift;

    my $Lang = $Self->{Translation} || {};

    $Lang->{'Settings for new ticket notification sms preferences.'}      = '';

    $Lang->{'New ticket notification (via SMS)'}                          = 'SMS-Mitteilung bei neuem Ticket';
    $Lang->{'Send me a SMS if there is a new ticket in "My SMS Queues".'} = 'Zusenden einer SMS-Mitteilung bei neuem Ticket in "Meine Queues".';
    $Lang->{'Send new ticket notifications (via SMS)'} = 'SMS-Benachrichtigung über neue Tickets senden';

    $Lang->{'My SMS Queues'} = 'Meine SMS Queues';
    $Lang->{'Your queue selection for SMS notifications.'} = 'Auswahl der bevorzugten Queues für SMS-Benachrichtigungen.';
    $Lang->{'Ticket move notification (via SMS)'} = 'SMS-Benachrichtigung beim Verschieben von Tickets';
    $Lang->{'Send me a SMS notification if a ticket is moved into one of "My SMS Queues".'} = 'Zusenden einer SMS-Mitteilung beim Verschieben eines Tickets in "Meine SMS Queues".';

    $Lang->{'Send ticket move notifications (via SMS)'} = 'SMS-Benachrichtigung beim Verschieben von Tickets';
    $Lang->{'Ticket follow up notification (via SMS)'} = 'Benachrichtigung über Folgeaktionen';
    $Lang->{'Send me a notification (SMS) if a customer sends a follow up and I\'m the owner of the ticket or the ticket is unlocked and is in one of my subscribed queues.'} = 'Sende mir eine SMS-Benachrichtigung, wenn ein Kunde eine Rückmeldung gibt und ich der Besitzer des Tickets bin, oder das Ticket nicht gesperrt ist und in einer meiner Queues liegt.';
    $Lang->{'Send ticket follow up notifications (via SMS)'} = 'Benachrichtigung bei Rückmeldung verschicken';

    $Lang->{'Mobile number to send the SMS notifications to.'} = 'Mobilnummer für SMS-Benachrichtigungen';
    $Lang->{'Mobile number to send the SMS notifications to (international format, e.g. "+49 123 45236" or "+4911-2351223").'} = 'Mobilnummer für SMS-Benachrichtigungen (Internationales Format, z.B. "+49 123 45236" oder "+4911-2351223")';
    $Lang->{'SMS Settings'} = 'SMS-Einstellungen';
    $Lang->{'The format of the mobile number is invalid. Please use international format, e.g. "+49 123 45236" or "+4911-2351223".'} = 'Das Format der Mobilnummer ist ungültig. Bitte verwenden Sie das Internationale Format, z.B. "+49 123 45236" oder "+4911-2351223".';
    $Lang->{'History::SMSNotification'} = 'SMS-Benachrichtigung an %s';
    #$Lang->{''} = '';

    return 1;
}

1;

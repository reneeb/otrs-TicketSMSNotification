# --
# Kernel/System/Ticket/Event/SMSNotification.pm - a event module to send notifications
# Copyright (C) 2011 - 2014 Perl-Services.de, http://perl-services.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Ticket::Event::SMSNotification;

use strict;
use warnings;

use Nexmo::SMS;
use Kernel::System::TicketSMSNotificationUtils;

our $VERSION = 0.02;

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    # get needed objects
    for my $Needed (
        qw(DBObject ConfigObject TicketObject LogObject TimeObject UserObject
            CustomerUserObject SendmailObject QueueObject GroupObject MainObject
            EncodeObject)
        )
    {
        $Self->{$Needed} = $Param{$Needed} || die "Got no $Needed!";
    }

    $Self->{UtilsObject} = Kernel::System::TicketSMSNotificationUtils->new( %{$Self} );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    $Self->{LogObject}->Log(
        Priority => 'notice',
        Message  => 'Run SMSNotification event module',
    );

    # check needed stuff
    for my $Needed (qw(Event Data Config UserID)) {
        if ( !$Param{$Needed} ) {
            $Self->{LogObject}->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    for my $NeededData (qw(TicketID)) {
        if ( !$Param{Data}->{$NeededData} ) {
            $Self->{LogObject}->Log(
                Priority => 'error',
                Message  => "Need $NeededData!",
            );
            return;
        }
    }

    # get ticket attribute matches
    my %Ticket = $Self->{TicketObject}->TicketGet(
        TicketID => $Param{Data}->{TicketID},
        UserID   => 1,
    );
    my %Article = $Self->{TicketObject}->ArticleFirstArticle(
        TicketID => $Param{Data}->{TicketID},
    );

    my $Action = 'FollowUp';
    if ( $Param{Data}->{ArticleID} && $Article{ArticleID} == $Param{Data}->{ArticleID} ) {
        $Action = 'New';
    }
    elsif ( $Param{Event} eq 'TicketQueueUpdate' ) {
        $Action = 'Move',
    }

    my %Recipients = $Self->{UtilsObject}->RecipientsGet(
        QueueID => $Ticket{QueueID},
        Action  => $Action,
    );

    return if !%Recipients;

    my $User   = $Self->{ConfigObject}->Get( 'SMSNotification::NexmoUser' );
    my $Passwd = $Self->{ConfigObject}->Get( 'SMSNotification::NexmoPassword' );
    my $From   = $Self->{ConfigObject}->Get( 'SMSNotification::From' );

    # create needed object
    my $NexmoObject = Nexmo::SMS->new(
        server   => 'http://rest.nexmo.com/sms/json',
        username => $User,
        password => $Passwd,
    );

    my $TicketHook    = $Self->{ConfigObject}->Get( 'Ticket::Hook' ) || '';
    my $TicketDivider = $Self->{ConfigObject}->Get( 'Ticket::HookDivider' ) || '';
    $Article{Subject} =~ s{\[ \Q$TicketHook\E \Q$TicketDivider\E [0-9]+ \]}{}xms;;

    my $Text = $Action . '#' . $Ticket{TicketNumber} . ' ' . $Article{Subject};

    if ( 140 < length $Text ) {
        $Text = substr( $Text, 0, 135 ) . '[...]';
    }

    my %NumberSeen;

    RECIPIENT:
    for my $UserID ( keys %Recipients ) {

        next RECIPIENT if $Param{UserID} == $UserID;

        my $Recipient = $Recipients{$UserID};

        next RECIPIENT if $NumberSeen{$Recipient}++;

        my $Error;

        my $SMS = $NexmoObject->sms(
            text => $Text,
            to   => $Recipient,
            from => $From,
        ) or $Error =  $NexmoObject->errstr;

        if ( $Error ) {
            $Self->{LogObject}->Log(
                Priority => 'error',
                Message  => $Error,
            );
            next;
        }

        $SMS->send or $Error = $SMS->errstr;
        if ( $Error ) {
            $Self->{LogObject}->Log(
                Priority => 'error',
                Message  => $Error,
            );
            next;
        }
        else {
            $Self->{TicketObject}->HistoryAdd(
                TicketID     => $Ticket{TicketID},
                Name         => 'SMSNotification%%' . $Recipient,
                HistoryType  => 'SMSNotification',
                CreateUserID => $Param{UserID},
            );
        }
    }

    return 1;
}

1;


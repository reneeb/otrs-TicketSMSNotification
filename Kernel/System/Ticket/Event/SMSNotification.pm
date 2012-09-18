# --
# Kernel/System/Ticket/Event/SMSNotification.pm - a event module to send notifications
# Copyright (C) 2010-2011 einraumwerk, http://einraumwerk.de/
# --
# $Id: SMSNotification.pm,v 1.9 2011/05/31 07:56:36 rb Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Ticket::Event::SMSNotification;

use strict;
use warnings;

use Nexmo::SMS;

use vars qw($VERSION);
$VERSION = qw($Revision: 1.9 $) [1];

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    # get needed objects
    for my $Needed (
        qw(DBObject ConfigObject TicketObject LogObject TimeObject UserObject CustomerUserObject SendmailObject QueueObject GroupObject MainObject EncodeObject)
        )
    {
        $Self->{$Needed} = $Param{$Needed} || die "Got no $Needed!";
    }

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    $Self->{LogObject}->Log(
        Priority => 'notice',
        Message  => 'Run SMSNotification event module',
    );

    # check needed stuff
    for (qw(Event Data Config UserID)) {
        if ( !$Param{$_} ) {
            $Self->{LogObject}->Log( Priority => 'error', Message => "Need $_!" );
            return;
        }
    }
    for (qw(TicketID ArticleID)) {
        if ( !$Param{Data}->{$_} ) {
            $Self->{LogObject}->Log( Priority => 'error', Message => "Need $_ in Data!" );
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

    $Self->{LogObject}->Log(
        Priority => 'notice',
        Message => 'Sender-/ArticleType: ' . join '::', @Article{qw(SenderType ArticleType)},
    );

    return 1 if $Article{ArticleID} != $Param{Data}->{ArticleID};
    return 1 if $Article{SenderType} ne 'customer' || $Article{ArticleType} ne 'email-external';

    my $Config      = $Self->{ConfigObject}->Get( 'SMSNotification::QueueRecipients' );
    my $QueueConfig = $Config->{ $Ticket{Queue} };

    return 1 if !$QueueConfig;

    my %Recipients = map{ $_ => 1 }split /\s*;\s*/, $QueueConfig;

    my $User   = $Self->{ConfigObject}->Get( 'SMSNotification::NexmoUser' );
    my $Passwd = $Self->{ConfigObject}->Get( 'SMSNotification::NexmoPassword' );
    my $From   = $Self->{ConfigObject}->Get( 'SMSNotification::From' );

    # create needed object
    my $NexmoObject = Nexmo::SMS->new(
        server   => 'http://rest.nexmo.com/sms/json',
        username => $User,
        password => $Passwd,
    );

    for my $Recipient ( keys %Recipients ) {
        my $Error;

        my $SMS = $NexmoObject->sms(
            text => $Article{Subject},
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
    }

    return 1;
}

1;


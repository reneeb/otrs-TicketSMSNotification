# --
# Kernel/System/Ticket/Event/SMSNotification.pm - a event module to send notifications
# Copyright (C) 2010-2014 Perl-Services.de, http://perl-services.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Ticket::Event::SMSNotification;

use strict;
use warnings;

use Nexmo::SMS;

our @ObjectDependencies = qw(
    Kernel::Config
    Kernel::System::Log
    Kernel::System::Ticket
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $LogObject    = $Kernel::OM->Get('Kernel::System::Log');
    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    $LogObject->Log(
        Priority => 'notice',
        Message  => 'Run SMSNotification event module',
    );

    # check needed stuff
    for my $NeededParam (qw(Event Data Config UserID)) {
        if ( !$Param{$NeededParam} ) {
            $LogObject->Log(
                Priority => 'error',
                Message  => "Need $NeededParam!",
            );
            return;
        }
    }

    for my $NeededData (qw(TicketID ArticleID)) {
        if ( !$Param{Data}->{$NeededData} ) {
            $LogObject->Log(
                Priority => 'error',
                Message  => "Need $NeededData in Data!",
            );
            return;
        }
    }

    # get ticket attribute matches
    my %Ticket = $TicketObject->TicketGet(
        TicketID => $Param{Data}->{TicketID},
        UserID   => 1,
    );
    my %Article = $TicketObject->ArticleFirstArticle(
        TicketID => $Param{Data}->{TicketID},
    );

    $LogObject->Log(
        Priority => 'notice',
        Message => 'Sender-/ArticleType: ' . join '::', @Article{qw(SenderType ArticleType)},
    );

    return 1 if $Article{ArticleID} != $Param{Data}->{ArticleID};
    return 1 if $Article{SenderType} ne 'customer' || $Article{ArticleType} ne 'email-external';

    my $Config      = $ConfigObject->Get( 'SMSNotification::QueueRecipients' );
    my $QueueConfig = $Config->{ $Ticket{Queue} };

    return 1 if !$QueueConfig;

    my %Recipients = map{ $_ => 1 }split /\s*;\s*/, $QueueConfig;

    my $User   = $ConfigObject->Get( 'SMSNotification::NexmoUser' );
    my $Passwd = $ConfigObject->Get( 'SMSNotification::NexmoPassword' );
    my $From   = $ConfigObject->Get( 'SMSNotification::From' );

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
            $LogObject->Log(
                Priority => 'error',
                Message  => $Error,
            );
            next;
        }

        $SMS->send or $Error = $SMS->errstr;
        if ( $Error ) {
            $LogObject->Log(
                Priority => 'error',
                Message  => $Error,
            );
            next;
        }
    }

    return 1;
}

1;

